import datetime
import importlib.util
import tempfile
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def load(name):
 spec=importlib.util.spec_from_file_location(name,ROOT/'scripts'/f'{name}.py')
 module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
profile=load('signing_profile'); sender=load('send_telegram')

class ReleaseTests(unittest.TestCase):
 def profile(self):
  return {'TeamIdentifier':['ABCDE12345'], 'Entitlements':{'application-identifier':'ABCDE12345.com.example.pulse','com.apple.developer.networking.vpn.api':['allow-vpn'],'get-task-allow':False},'ExpirationDate':datetime.datetime(2099,1,1),'ProvisionedDevices':['DEVICE'], 'UUID':'12345678-1234-1234-1234-123456789ABC'}
 def test_profile_valid_and_mismatch(self):
  self.assertEqual(profile.validate(self.profile(),'com.example.pulse')[2],'release-testing')
  with self.assertRaises(profile.ProfileError): profile.validate(self.profile(),'com.example.other')
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

if __name__=='__main__': unittest.main()
