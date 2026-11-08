"""Validate an iPhone provisioning profile without exposing its contents."""
import datetime
import os
import plistlib
import re
import sys

class ProfileError(ValueError):
    pass

def validate(profile, bundle):
    if not re.fullmatch(r'[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+', bundle):
        raise ProfileError('Set a valid MLBB_BUNDLE_ID repository variable.')
    team_ids = profile.get('TeamIdentifier', [])
    if len(team_ids) != 1 or not re.fullmatch(r'[A-Z0-9]{10}', team_ids[0]):
        raise ProfileError('Profile must have one valid Apple Team ID.')
    ent = profile.get('Entitlements', {})
    if ent.get('application-identifier', '') != team_ids[0] + '.' + bundle:
        raise ProfileError('Profile does not match MLBB_BUNDLE_ID. Never reuse another app ID.')
    if 'allow-vpn' not in ent.get('com.apple.developer.networking.vpn.api', []):
        raise ProfileError('Profile does not include Personal VPN capability.')
    expiry = profile.get('ExpirationDate')
    if not isinstance(expiry, datetime.datetime) or expiry.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
        raise ProfileError('Profile is expired or missing its expiration date.')
    if not profile.get('ProvisionedDevices') or profile.get('ProvisionsAllDevices'):
        raise ProfileError('Use a development or Ad Hoc profile with registered devices.')
    uuid = profile.get('UUID', '')
    if not re.fullmatch(r'[0-9A-Fa-f-]{36}', uuid):
        raise ProfileError('Invalid profile UUID.')
    method = 'debugging' if ent.get('get-task-allow', False) else 'release-testing'
    return team_ids[0], uuid, method

def main():
    try:
        with open(sys.argv[1], 'rb') as f: profile = plistlib.load(f)
        bundle = os.environ.get('MLBB_BUNDLE_ID', '').strip()
        team, uuid, method = validate(profile, bundle)
        with open(os.environ['GITHUB_ENV'], 'a', encoding='utf-8') as f:
            f.write(f'MLBB_BUNDLE_ID={bundle}\nTEAM_ID={team}\nPROFILE_UUID={uuid}\nEXPORT_METHOD={method}\n')
        print('Profile validated for MLBB Pulse; Xcode will verify certificate compatibility.')
    except (OSError, ValueError, KeyError, IndexError) as e:
        print(f'Profile validation failed: {e}', file=sys.stderr)
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
