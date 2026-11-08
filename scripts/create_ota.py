"""Create a GitHub Pages OTA package from a signed IPA and the configured Pages URL."""
import html
import os
from pathlib import Path
import plistlib
import re
import shutil
import sys
from urllib.parse import quote, urlparse
import zipfile


def build(ipa, site, base, expected_bundle):
    u = urlparse(base)
    if u.scheme != 'https' or not u.hostname or u.username or u.password or u.query or u.fragment:
        raise ValueError('Pages base URL must be an HTTPS URL without credentials or query.')
    base = base.rstrip('/') + '/'
    if not re.fullmatch(r'[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+', expected_bundle):
        raise ValueError('Invalid MLBB_BUNDLE_ID.')
    if not ipa.is_file() or not zipfile.is_zipfile(ipa):
        raise ValueError('Signed IPA is missing or invalid.')
    with zipfile.ZipFile(ipa) as z:
        infos = [n for n in z.namelist() if re.fullmatch(r'Payload/[^/]+\.app/Info\.plist', n)]
        if len(infos) != 1: raise ValueError('IPA must contain exactly one main application.')
        info = plistlib.loads(z.read(infos[0]))
        if info.get('CFBundleIdentifier') != expected_bundle: raise ValueError('IPA bundle identifier does not match MLBB_BUNDLE_ID.')
        app_dir = infos[0].rsplit('/', 1)[0]
        if app_dir+'/embedded.mobileprovision' not in z.namelist(): raise ValueError('Signed IPA must contain its embedded provisioning profile.')
        version = str(info.get('CFBundleShortVersionString') or info.get('CFBundleVersion') or '')
        if not re.fullmatch(r'[0-9]+(?:\.[0-9]+)*', version): raise ValueError('IPA version missing or invalid.')
    site.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ipa, site/'MLBBPulse.ipa')
    manifest={'items':[{'assets':[{'kind':'software-package','url':base+'MLBBPulse.ipa'}], 'metadata':{'bundle-identifier':expected_bundle,'bundle-version':version,'kind':'software','title':'MLBB Pulse'}}]}
    (site/'manifest.plist').write_bytes(plistlib.dumps(manifest))
    install='itms-services://?action=download-manifest&url='+quote(base+'manifest.plist',safe='')
    page='''<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MLBB Pulse — установка</title><style>body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;max-width:38rem;margin:4rem auto;padding:0 1.25rem;background:#101827;color:#f2f7fb;line-height:1.55}a.button{display:inline-block;background:#5ce4bb;color:#102a26;font-weight:700;padding:1rem 1.4rem;border-radius:12px;text-decoration:none}a{color:#87ebd2}</style></head><body><h1>MLBB Pulse</h1><p>Версия '''+html.escape(version)+'''</p><p>Откройте эту страницу в Safari на iPhone, зарегистрированном в профиле подписи.</p><p><a class="button" href="'''+html.escape(install,quote=True)+'''">Установить приложение</a></p><p>Для этой сборки действуют ограничения профиля Apple. VPN-сервер и работа игры требуют отдельной проверки.</p><p><a href="MLBBPulse.ipa">Скачать IPA</a></p></body></html>'''
    (site/'index.html').write_text(page,encoding='utf-8')
    (site/'.nojekyll').touch()

if __name__ == '__main__':
    try: build(Path('release/MLBBPulse.ipa'),Path('_site'),os.environ['PAGES_BASE_URL'],os.environ['MLBB_BUNDLE_ID'])
    except (ValueError,KeyError,OSError,zipfile.BadZipFile,plistlib.InvalidFileException) as e:
        print('Could not prepare OTA:',e,file=sys.stderr);sys.exit(1)
    print('OTA manifest and installation page prepared.')
