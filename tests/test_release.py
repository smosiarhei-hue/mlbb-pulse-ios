import datetime
import importlib.util
import tempfile
import plistlib
import zipfile
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def load(name):
 spec=importlib.util.spec_from_file_location(name,ROOT/'scripts'/f'{name}.py')
 module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
profile=load('signing_profile'); sender=load('send_telegram'); ota=load('create_ota')

class ReleaseTests(unittest.TestCase):
 def profile(self):
  return {'TeamIdentifier':['ABCDE12345'], 'Entitlements':{'application-identifier':'ABCDE12345.com.example.pulse','com.apple.developer.networking.vpn.api':['allow-vpn'],'get-task-allow':False},'ExpirationDate':datetime.datetime(2099,1,1),'ProvisionedDevices':['DEVICE'], 'UUID':'12345678-1234-1234-1234-123456789ABC'}
 def test_profile_valid_and_mismatch(self):
  self.assertEqual(profile.validate(self.profile(),'com.example.pulse')[2],'release-testing')
  with self.assertRaises(profile.ProfileError): profile.validate(self.profile(),'com.example.other')
 def test_profile_id_may_be_reused_when_matching(self):
  p=self.profile();p['Entitlements']['application-identifier']='ABCDE12345.app.hare5681.lyra4838'
  self.assertEqual(profile.validate(p,'app.hare5681.lyra4838')[2],'release-testing')
 def test_vpn_and_devices_required(self):
  p=self.profile();p['Entitlements'].pop('com.apple.developer.networking.vpn.api')
  with self.assertRaises(profile.ProfileError): profile.validate(p,'com.example.pulse')
  p=self.profile();p.pop('ProvisionedDevices')
  with self.assertRaises(profile.ProfileError): profile.validate(p,'com.example.pulse')
 def test_telegram_prepares_private_document(self):
  env={'TELEGRAM_BOT_TOKEN':'1234:abc','TELEGRAM_CHAT_ID':'9876','GITHUB_REPOSITORY':'owner/repo','GITHUB_RUN_ID':'42','GITHUB_SHA':'a'*40}
  with tempfile.TemporaryDirectory() as d:
   path=Path(d)/'MLBBPulse.ipa';path.write_bytes(b'ipa')
   token,method,body,typ=sender.prepare(env,path)
   self.assertEqual(method,'sendDocument');self.assertIn(b'owner/repo/actions/runs/42',body)
   env['TELEGRAM_CHAT_ID']='1234'
   with self.assertRaises(ValueError): sender.prepare(env,path)

 def test_ota_manifest_matches_real_ipa_metadata(self):
  with tempfile.TemporaryDirectory() as d:
   path=Path(d)/'MLBBPulse.ipa'; site=Path(d)/'site'
   with zipfile.ZipFile(path,'w') as z:
    z.writestr('Payload/MLBBPulse.app/Info.plist',plistlib.dumps({'CFBundleIdentifier':'com.example.pulse','CFBundleShortVersionString':'1.0'}))
    z.writestr('Payload/MLBBPulse.app/embedded.mobileprovision',b'test')
   ota.build(path,site,'https://example.github.io/pulse/','com.example.pulse')
   m=plistlib.loads((site/'manifest.plist').read_bytes())['items'][0]
   self.assertEqual(m['metadata']['bundle-identifier'],'com.example.pulse')
   self.assertEqual(m['assets'][0]['url'],'https://example.github.io/pulse/MLBBPulse.ipa')
   self.assertIn('itms-services://', (site/'index.html').read_text())
   with self.assertRaises(ValueError): ota.build(path,site,'https://example.github.io/pulse/','com.example.other')

if __name__=='__main__': unittest.main()
