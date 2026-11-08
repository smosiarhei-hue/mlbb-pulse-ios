"""Materialize the versioned Icon Composer image layers before XcodeGen."""
import base64, hashlib, struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {'01-upper.png': '3fa9f4cd246b161eef2c76362c5a3a468c34807ac9d881f7ddaa497c6d5bee3c', '02-lower.png': '22cb638f93a2b77ff0ebfc33cad186dbf832ac006c5efac4d0ff5a7befe3e818', '03-center.png': '7414749551a2c265e35c220a6699bae7fd4f4d59629f3f59c1bcb02a28ce75be'}
out = ROOT / 'MLBBPulse.icon' / 'Assets'
out.mkdir(parents=True, exist_ok=True)
for name, digest in EXPECTED.items():
    data = base64.b64decode((ROOT/'IconSources'/(name+'.b64')).read_bytes(), validate=False)
    if hashlib.sha256(data).hexdigest() != digest:
        raise SystemExit('Icon layer checksum mismatch: '+name)
    if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II',data[16:24]) != (1024,1024):
        raise SystemExit('Icon layer is not a 1024x1024 PNG: '+name)
    (out/name).write_bytes(data)
print('Materialized and verified icon layers.')
