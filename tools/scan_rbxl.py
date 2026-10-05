import struct, ctypes, ctypes.util, lz4.block
from pathlib import Path
p=Path('/mnt/data/stealanegg14.rbxl')
b=p.read_bytes()
assert b[:8]==b'<roblox!'
version=struct.unpack_from('<H',b,14)[0]
cc,ic=struct.unpack_from('<II',b,16)
print('version',version,'classes',cc,'instances',ic,'size',len(b))
lib=ctypes.CDLL(ctypes.util.find_library('zstd'))
lib.ZSTD_decompress.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t]
lib.ZSTD_decompress.restype=ctypes.c_size_t
lib.ZSTD_isError.argtypes=[ctypes.c_size_t];lib.ZSTD_isError.restype=ctypes.c_uint

def decomp(data,outlen):
    if data[:4]==b'\x28\xb5\x2f\xfd':
        out=ctypes.create_string_buffer(outlen)
        src=ctypes.create_string_buffer(data)
        n=lib.ZSTD_decompress(out,outlen,src,len(data))
        if lib.ZSTD_isError(n): raise RuntimeError('zstd')
        return out.raw[:n]
    return lz4.block.decompress(data,uncompressed_size=outlen)

o=32;counts={};i=0
while o+16<=len(b):
    typ=b[o:o+4].decode('latin1'); clen,ulen=struct.unpack_from('<II',b,o+4); o+=16
    data=b[o:o+(clen or ulen)]; o+=len(data)
    counts[typ]=counts.get(typ,0)+1
    if i<12 or typ in ('SSTR','PRNT','END\x00'):
        print(i,repr(typ),clen,ulen,'magic',data[:4].hex())
    i+=1
    if typ=='END\x00':break
print('chunks',i,counts)