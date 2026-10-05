import struct, subprocess, json, os, sys
import lz4.block
from collections import Counter, defaultdict

PATH='/mnt/data/stealanegg14.rbxl'

def u32(b,o): return struct.unpack_from('<I',b,o)[0], o+4
def i32(b,o): return struct.unpack_from('<i',b,o)[0], o+4
def readstr(b,o):
    n,o=u32(b,o); return b[o:o+n], o+n

def deinterleave(data,nvals,width=4):
    assert len(data)==nvals*width
    out=bytearray(len(data))
    for bytepos in range(width):
        start=bytepos*nvals
        for i in range(nvals): out[i*width+bytepos]=data[start+i]
    return bytes(out)

def zigzag32(x): return (x>>1) ^ (-(x&1))

def refs_decode(raw,n):
    d=deinterleave(raw,n,4)
    vals=[]; prev=0
    for i in range(n):
        x=int.from_bytes(d[i*4:(i+1)*4],'big',signed=False)
        delta=zigzag32(x)
        prev += delta
        vals.append(prev)
    return vals

def ints_decode(raw,n):
    d=deinterleave(raw,n,4); out=[]
    for i in range(n):
        x=int.from_bytes(d[i*4:(i+1)*4],'big')
        out.append(zigzag32(x))
    return out

def uints_decode(raw,n):
    d=deinterleave(raw,n,4); return [int.from_bytes(d[i*4:(i+1)*4],'big') for i in range(n)]

def floats_decode(raw,n):
    d=deinterleave(raw,n,4); out=[]
    for i in range(n):
        x=int.from_bytes(d[i*4:(i+1)*4],'big')
        # undo left-rotate by 1 => right rotate by 1
        x=((x>>1)|((x&1)<<31)) & 0xffffffff
        out.append(struct.unpack('>f',x.to_bytes(4,'big'))[0])
    return out

with open(PATH,'rb') as f: data=f.read()
assert data[:14]==b'<roblox!\x89\xff\r\n\x1a\n'
ver=struct.unpack_from('<H',data,14)[0]
class_count=struct.unpack_from('<I',data,16)[0]
inst_count=struct.unpack_from('<I',data,20)[0]
print('header',ver,class_count,inst_count,'bytes',len(data))
pos=32
chunks=[]
while pos+16<=len(data):
    name=data[pos:pos+4].rstrip(b'\x00').decode('ascii','replace'); pos+=4
    clen,ulen=struct.unpack_from('<II',data,pos); pos+=8
    reserved=data[pos:pos+4];pos+=4
    body=data[pos:pos+(clen if clen else ulen)]; pos += (clen if clen else ulen)
    if clen:
        if body[:4]==b'\x28\xb5\x2f\xfd':
            p=subprocess.run(['zstd','-d','-q','-c'],input=body,stdout=subprocess.PIPE,check=True)
            payload=p.stdout
        else:
            payload=lz4.block.decompress(body,uncompressed_size=ulen)
    else: payload=body
    if len(payload)!=ulen: print('WARN len',name,len(payload),ulen)
    chunks.append((name,payload,clen,ulen))
    if name=='END': break
print('chunks',len(chunks),Counter(n for n,_,_,_ in chunks))

classes={}; ref_to_inst={}; class_instances=defaultdict(list)
for name,p,_,_ in chunks:
    if name!='INST': continue
    o=0; cid,o=i32(p,o); cnameb,o=readstr(p,o); cname=cnameb.decode('utf-8','replace'); has=p[o];o+=1; count,o=u32(p,o)
    refs=refs_decode(p[o:o+count*4],count); o+=count*4
    markers=list(p[o:o+count]) if has else []
    classes[cid]={'name':cname,'count':count,'refs':refs,'hasService':bool(has)}
    for r in refs:
        inst={'ref':r,'class':cname,'class_id':cid,'props':{}}
        ref_to_inst[r]=inst; class_instances[cname].append(inst)

# properties: parse useful scalar/string props
prop_type_counts=Counter(); prop_names=Counter(); errors=[]
for name,p,_,_ in chunks:
    if name!='PROP': continue
    try:
        o=0; cid,o=i32(p,o); pnameb,o=readstr(p,o); pname=pnameb.decode('utf-8','replace'); tid=p[o];o+=1
        c=classes[cid]; n=c['count']; refs=c['refs']; vals=None
        prop_type_counts[tid]+=1; prop_names[pname]+=1
        if tid==1:
            vals=[]
            for _i in range(n):
                sb,o=readstr(p,o); vals.append(sb.decode('utf-8','replace'))
        elif tid==2:
            vals=[bool(x) for x in p[o:o+n]]; o+=n
        elif tid==3:
            vals=ints_decode(p[o:o+n*4],n); o+=n*4
        elif tid==4:
            vals=floats_decode(p[o:o+n*4],n); o+=n*4
        elif tid==5:
            vals=list(struct.unpack_from('<'+'d'*n,p,o)); o+=8*n
        elif tid in (0x0b,0x12):
            vals=uints_decode(p[o:o+n*4],n); o+=n*4
        elif tid==0x13:
            vals=refs_decode(p[o:o+n*4],n); o+=n*4
        # string-ish shared string 0x1c: indexes into SSTR, parse index only
        elif tid==0x1c:
            vals=uints_decode(p[o:o+n*4],n); o+=n*4
        if vals is not None:
            for r,v in zip(refs,vals): ref_to_inst[r]['props'][pname]=v
    except Exception as e:
        errors.append((str(e),p[:40].hex()))

# parent hierarchy
parents={}; children=defaultdict(list)
for name,p,_,_ in chunks:
    if name!='PRNT': continue
    o=0; reserved=p[o];o+=1; n,o=u32(p,o)
    crefs=refs_decode(p[o:o+n*4],n); o+=n*4
    prefs=refs_decode(p[o:o+n*4],n); o+=n*4
    for c,pa in zip(crefs,prefs): parents[c]=pa; children[pa].append(c)

for r,inst in ref_to_inst.items():
    inst['name']=inst['props'].get('Name',inst['class'])
    inst['parent']=parents.get(r,-1)

def path_for(r):
    parts=[]; seen=set()
    while r!=-1 and r in ref_to_inst and r not in seen:
        seen.add(r); ins=ref_to_inst[r]; parts.append(ins['name']); r=parents.get(r,-1)
    return '/'.join(reversed(parts))

# summaries
summary={
 'file':PATH,'size':len(data),'version':ver,'class_count_header':class_count,'instance_count_header':inst_count,
 'parsed_instances':len(ref_to_inst),'classes':dict(sorted(((k,len(v)) for k,v in class_instances.items()), key=lambda x:(-x[1],x[0]))),
 'prop_type_counts':dict(prop_type_counts),'property_names_top':prop_names.most_common(100),'parse_errors':errors[:20]
}
with open('/mnt/data/rbxinspect/summary.json','w') as f: json.dump(summary,f,ensure_ascii=False,indent=2)

# tree top levels up to depth 4 with counts
roots=children[-1]
print('roots',[(ref_to_inst[r]['class'],ref_to_inst[r]['name'],r) for r in roots[:50]])
print('class top',summary['classes'])

# scripts
scripts=[]
for cls in ('Script','LocalScript','ModuleScript'):
    for ins in class_instances.get(cls,[]):
        src=ins['props'].get('Source','')
        scripts.append({'ref':ins['ref'],'class':cls,'name':ins['name'],'path':path_for(ins['ref']),'source':src,'source_len':len(src),'disabled':ins['props'].get('Disabled'),'runcontext':ins['props'].get('RunContext')})
with open('/mnt/data/rbxinspect/scripts.json','w') as f: json.dump(scripts,f,ensure_ascii=False,indent=2)
os.makedirs('/mnt/data/rbxinspect/scripts',exist_ok=True)
for i,s in enumerate(scripts):
    safe=''.join(c if c.isalnum() or c in '._-' else '_' for c in s['path'])[-180:]
    with open(f'/mnt/data/rbxinspect/scripts/{i:04d}_{s["class"]}_{safe}.luau','w',encoding='utf-8') as f: f.write(s['source'])
print('scripts',len(scripts),'with_source',sum(bool(x['source']) for x in scripts),'total source bytes',sum(x['source_len'] for x in scripts))
for s in sorted(scripts,key=lambda x:-x['source_len'])[:30]: print(s['class'],s['source_len'],s['path'])

# remotes/bindables
for cls in ['RemoteEvent','RemoteFunction','UnreliableRemoteEvent','BindableEvent','BindableFunction']:
    arr=class_instances.get(cls,[])
    print(cls,len(arr))
    for ins in arr[:100]: print(' ',path_for(ins['ref']))

# services/top hierarchy immediate children counts
with open('/mnt/data/rbxinspect/tree.txt','w',encoding='utf-8') as f:
    def rec(r,d,maxd=5):
        ins=ref_to_inst[r]; f.write('  '*d+f'- {ins["name"]} [{ins["class"]}] ({len(children.get(r,[]))})\n')
        if d<maxd:
            for ch in children.get(r,[]): rec(ch,d+1,maxd)
    for r in roots: rec(r,0,5)

# export noteworthy non-geometric instances with props basic
interesting_classes={'Folder','Configuration','StringValue','IntValue','NumberValue','BoolValue','ObjectValue','RemoteEvent','RemoteFunction','BindableEvent','BindableFunction','Script','LocalScript','ModuleScript','ScreenGui','StarterGui','DataStoreService','ReplicatedStorage','ServerScriptService','ServerStorage','StarterPlayer','StarterCharacterScripts','StarterPlayerScripts','Teams','Team','SoundService','MarketplaceService'}
items=[]
for r,ins in ref_to_inst.items():
    if ins['class'] in interesting_classes or ins['class'].endswith('Value'):
        items.append({'path':path_for(r),'class':ins['class'],'props':ins['props']})
with open('/mnt/data/rbxinspect/interesting.json','w') as f: json.dump(items,f,ensure_ascii=False,indent=2)