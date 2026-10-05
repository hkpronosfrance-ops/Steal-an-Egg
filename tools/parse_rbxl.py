import struct, ctypes, ctypes.util, lz4.block, json, os, re
from pathlib import Path
P=Path('/mnt/data/stealanegg14.rbxl'); b=P.read_bytes()
lib=ctypes.CDLL(ctypes.util.find_library('zstd'))
lib.ZSTD_decompress.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t];lib.ZSTD_decompress.restype=ctypes.c_size_t
lib.ZSTD_isError.argtypes=[ctypes.c_size_t];lib.ZSTD_isError.restype=ctypes.c_uint

def decomp(data,outlen):
    if data[:4]==b'\x28\xb5\x2f\xfd':
        out=ctypes.create_string_buffer(outlen); src=ctypes.create_string_buffer(data)
        n=lib.ZSTD_decompress(out,outlen,src,len(data))
        if lib.ZSTD_isError(n): raise RuntimeError('zstd err')
        return out.raw[:n]
    return lz4.block.decompress(data,uncompressed_size=outlen)

def rstr(d,o):
    n=struct.unpack_from('<I',d,o)[0]; o+=4
    return d[o:o+n],o+n

def deinterleave(data,n,w):
    # input column-major => list of row bytes
    return [bytes(data[j*n+i] for j in range(w)) for i in range(n)]
def zigzag(u): return (u>>1) ^ -(u&1)
def refs_from(data,n):
    rows=deinterleave(data,n,4); out=[]; cur=0
    for row in rows:
        u=int.from_bytes(row,'big',signed=False); delta=zigzag(u); cur+=delta; out.append(cur)
    return out

def u32s_interleaved(data,n):
    return [int.from_bytes(x,'big') for x in deinterleave(data,n,4)]

# chunk decode
chunks=[]; o=32
while o+16<=len(b):
    typ=b[o:o+4].decode('latin1');cl,ul=struct.unpack_from('<II',b,o+4);o+=16
    raw=b[o:o+(cl or ul)];o+=len(raw); d=raw if cl==0 else decomp(raw,ul)
    chunks.append((typ,d))
    if typ=='END\x00': break

# SSTR
shared=[]
for typ,d in chunks:
    if typ=='SSTR':
        ver,cnt=struct.unpack_from('<II',d,0); q=8
        for i in range(cnt):
            q+=16; s,q=rstr(d,q); shared.append(s)
        print('SSTR',ver,cnt,'parsed bytes',q,'of',len(d))
        break
# INST
classes={}; refinfo={}; instances={}
for typ,d in chunks:
    if typ!='INST': continue
    q=0; cid=struct.unpack_from('<I',d,q)[0];q+=4; nameb,q=rstr(d,q); cname=nameb.decode('utf-8','replace'); fmt=d[q];q+=1;n=struct.unpack_from('<I',d,q)[0];q+=4
    refs=refs_from(d[q:q+4*n],n);q+=4*n
    classes[cid]={'name':cname,'count':n,'refs':refs,'service':fmt}
    for r in refs: instances[r]={'class':cname,'class_id':cid,'props':{}}
print('classes',len(classes),'instances',len(instances),'sum',sum(x['count'] for x in classes.values()))

# props - parse only selected primitive useful all strings, shared strings, bool, int, enum, refs; plus record prop metadata
propmeta=[]
for typ,d in chunks:
    if typ!='PROP': continue
    q=0; cid=struct.unpack_from('<I',d,q)[0];q+=4; pnb,q=rstr(d,q); pn=pnb.decode('utf-8','replace'); tid=d[q];q+=1
    c=classes[cid]; n=c['count']; vals=None
    try:
        if tid==0x01: # strings
            vals=[]
            for _ in range(n): s,q=rstr(d,q); vals.append(s)
        elif tid==0x1c: # shared string indexes
            idxs=u32s_interleaved(d[q:q+4*n],n); vals=[shared[i] if i < len(shared) else b'' for i in idxs]
        elif tid==0x02: vals=list(d[q:q+n])
        elif tid in (0x03,0x13):
            rows=deinterleave(d[q:q+4*n],n,4); arr=[zigzag(int.from_bytes(x,'big')) for x in rows]
            if tid==0x13:
                cur=0; vals=[]
                for z in arr: cur+=z; vals.append(cur)
            else: vals=arr
        elif tid in (0x0b,0x12): vals=u32s_interleaved(d[q:q+4*n],n)
        elif tid==0x05: vals=[struct.unpack_from('<d',d,q+8*i)[0] for i in range(n)]
        # capture
        if vals is not None:
            for r,v in zip(c['refs'],vals):
                if isinstance(v,bytes):
                    if pn in ('Name','Source','LinkedSource','Tags','AttributesSerialize','UniqueId','ScriptGuid') or c['name'] in ('Script','LocalScript','ModuleScript'):
                        try: sv=v.decode('utf-8','replace')
                        except: sv=''
                        instances[r]['props'][pn]=sv
                else:
                    if pn in ('Name','Disabled','RunContext','Archivable','Value','Source','LinkedSource','ScriptGuid'):
                        instances[r]['props'][pn]=v
    except Exception as e:
        pass
    propmeta.append({'class':c['name'],'class_id':cid,'prop':pn,'type_id':tid,'len':len(d)})
# PRNT
for typ,d in chunks:
    if typ=='PRNT':
        q=0;ver=d[q];q+=1;n=struct.unpack_from('<I',d,q)[0];q+=4
        ch=refs_from(d[q:q+4*n],n);q+=4*n; pa=refs_from(d[q:q+4*n],n)
        for c,p in zip(ch,pa):
            if c in instances: instances[c]['parent']=p
        print('prnt',n);break
# paths
from functools import lru_cache
@lru_cache(None)
def path(r):
    x=instances.get(r); 
    if not x:return '?'
    nm=x['props'].get('Name') or x['class']; p=x.get('parent',-1)
    return (path(p)+'/' if p in instances else '')+nm
# export scripts
out=Path('/mnt/data/stealanegg_audit'); out.mkdir(exist_ok=True); (out/'scripts').mkdir(exist_ok=True)
scripts=[]
for r,x in instances.items():
    if x['class'] in ('Script','LocalScript','ModuleScript'):
        src=x['props'].get('Source',''); pth=path(r)
        scripts.append({'ref':r,'class':x['class'],'path':pth,'name':x['props'].get('Name'),'source_len':len(src),'disabled':x['props'].get('Disabled'),'run_context':x['props'].get('RunContext')})
        safe=re.sub(r'[^A-Za-z0-9._-]+','_',pth)[-180:]
        (out/'scripts'/f'{r}_{safe}.luau').write_text(src,encoding='utf-8')
# class counts
cc={c['name']:c['count'] for c in classes.values()}
(out/'scripts.json').write_text(json.dumps(sorted(scripts,key=lambda x:x['path']),ensure_ascii=False,indent=2))
(out/'class_counts.json').write_text(json.dumps(dict(sorted(cc.items(),key=lambda kv:-kv[1])),indent=2))
(out/'propmeta.json').write_text(json.dumps(propmeta,ensure_ascii=False,indent=2))
# remotes and service-like objects names/paths
special=[]
for r,x in instances.items():
    if x['class'] in ('RemoteEvent','RemoteFunction','BindableEvent','BindableFunction','DataStoreService','MessagingService','MarketplaceService','MemoryStoreService'):
        special.append({'ref':r,'class':x['class'],'path':path(r),'name':x['props'].get('Name')})
(out/'special.json').write_text(json.dumps(sorted(special,key=lambda x:x['path']),ensure_ascii=False,indent=2))
print('scripts',len(scripts),'source total',sum(s['source_len'] for s in scripts))
for s in sorted(scripts,key=lambda x:-x['source_len'])[:20]: print(s['source_len'],s['class'],s['path'])
print('special',len(special))