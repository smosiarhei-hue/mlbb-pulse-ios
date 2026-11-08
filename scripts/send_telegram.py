"""Send the signed IPA privately to the configured chat without logging tokens."""
import http.client
import json
import os
from pathlib import Path
import re
import secrets
import sys

LIMIT = 50_000_000

def prepare(env, ipa):
    token, chat = env.get('TELEGRAM_BOT_TOKEN', '').strip(), env.get('TELEGRAM_CHAT_ID', '').strip()
    if not re.fullmatch(r'\d+:[A-Za-z0-9_-]+', token): raise ValueError('Missing or invalid TELEGRAM_BOT_TOKEN')
    if not re.fullmatch(r'-?\d+', chat) or int(chat) == 0 or int(chat) == int(token.split(':')[0]): raise ValueError('Missing or invalid TELEGRAM_CHAT_ID')
    repo, run, sha = env.get('GITHUB_REPOSITORY', ''), env.get('GITHUB_RUN_ID', ''), env.get('GITHUB_SHA', '')
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repo) or not run.isdigit() or not re.fullmatch(r'[0-9a-fA-F]{40}', sha): raise ValueError('Invalid GitHub run context')
    if not ipa.is_file() or ipa.stat().st_size == 0: raise ValueError('IPA missing or empty')
    link = f'https://github.com/{repo}/actions/runs/{run}'
    text = f'MLBB Pulse — подписанная сборка\nКоммит: {sha[:7]}\nСборка и артефакт: {link}\nУстановка доступна только на устройствах, разрешённых профилем.'
    ota = env.get('OTA_URL', '').strip()
    if ota and env.get('OTA_PUBLISHED') == 'true':
        from urllib.parse import urlparse
        parsed = urlparse(ota)
        if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
            raise ValueError('Invalid OTA installation URL')
        text += '\nУстановка в Safari: ' + ota
    if ipa.stat().st_size > LIMIT:
        body = json.dumps({'chat_id': chat, 'text': text + '\nIPA больше 50 МБ — скачайте артефакт в GitHub.', 'link_preview_options': {'is_disabled': True}}, ensure_ascii=False).encode()
        return token, 'sendMessage', body, 'application/json; charset=utf-8'
    boundary = 'mlbb' + secrets.token_hex(24)
    parts = []
    for name, value in [('chat_id', chat), ('caption', text)]:
        parts.append((f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n').encode())
    parts += [(f'--{boundary}\r\nContent-Disposition: form-data; name="document"; filename="MLBBPulse.ipa"\r\nContent-Type: application/octet-stream\r\n\r\n').encode(), ipa.read_bytes(), f'\r\n--{boundary}--\r\n'.encode()]
    return token, 'sendDocument', b''.join(parts), f'multipart/form-data; boundary={boundary}'

def send(env, ipa, connection_type=http.client.HTTPSConnection):
    token, method, body, content_type = prepare(env, ipa)
    connection = connection_type('api.telegram.org', timeout=180)
    try:
        connection.request('POST', f'/bot{token}/{method}', body=body, headers={'Content-Type': content_type})
        response = connection.getresponse()
        status, raw = response.status, response.read(1_000_001)
    finally: connection.close()
    try: payload = json.loads(raw)
    except (ValueError, UnicodeError): raise ValueError('Telegram response could not be confirmed') from None
    result = payload.get('result') if isinstance(payload, dict) else None
    if status != 200 or payload.get('ok') is not True or not isinstance(result, dict) or not isinstance(result.get('message_id'), int): raise ValueError('Telegram delivery failed or could not be confirmed')
    if method == 'sendDocument' and not isinstance(result.get('document', {}).get('file_id'), str): raise ValueError('Telegram document delivery could not be confirmed')
    if method == 'sendMessage' and not isinstance(result.get('text'), str): raise ValueError('Telegram message delivery could not be confirmed')

def main():
    try: send(os.environ, Path('release/MLBBPulse.ipa'))
    except ValueError as e: print(str(e), file=sys.stderr); return 1
    except Exception: print('Telegram delivery unconfirmed; check the chat before retrying.', file=sys.stderr); return 1
    print('Telegram confirmed delivery.')
    return 0

if __name__ == '__main__': sys.exit(main())
