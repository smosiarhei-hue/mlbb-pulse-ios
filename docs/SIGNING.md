# Подпись и Telegram

Workflow `.github/workflows/build-signed-ipa.yml` собирает архив только из ветки `feature/modern-mlbb-pulse-home` при push. После подписи он сохраняет IPA как артефакт GitHub Actions и отправляет IPA в Telegram (или ссылку на артефакт, если файл больше 50 МБ). Ссылка на Actions требует доступа к приватному репозиторию; это не прямая OTA-ссылка установки. OTA/GitHub Pages пока не настроены.

## Настройки в репозитории MLBB Pulse

В Settings → Secrets and variables → Actions задайте repository variable `MLBB_BUNDLE_ID` — новый уникальный App ID, созданный в вашей Apple Developer Team для MLBB Pulse. Он должен отличаться от ID другого приложения. Используйте только профиль, выпущенный для этого ID, с Personal VPN capability и зарегистрированным iPhone. Автоматическая подмена ID под чужой профиль не производится.

Задайте repository secrets (или организационные secrets, доступные этому репозиторию):

- `APPLE_CERT_P12_BASE64` — сертификат и приватный ключ в формате .p12, закодированный base64.
- `P12_PASSWORD` — пароль файла .p12.
- `PROVISION_PROFILE_BASE64` — подходящий development или Ad Hoc `.mobileprovision`, закодированный base64.
- `TELEGRAM_BOT_TOKEN` — токен существующего бота.
- `TELEGRAM_CHAT_ID` — ID целевого чата; если он не задан, workflow использует резервный ID из существующей сборки Sonivo (`8559869613`). Проверьте, что это ваш чат, до запуска доставки.

Секреты другого репозитория автоматически не копируются. Для преобразования файлов на Mac:

```sh
base64 -i /path/to/certificate.p12 | pbcopy
# Вставьте содержимое буфера в APPLE_CERT_P12_BASE64 на GitHub.
base64 -i /path/to/profile.mobileprovision | pbcopy
# Вставьте содержимое буфера в PROVISION_PROFILE_BASE64 на GitHub.
```

Не добавляйте эти файлы, пароли или токены в Git и не отправляйте их в чат. После настройки запустите workflow пушем в указанную ветку. Ручной `workflow_dispatch` станет доступен в интерфейсе после появления файла workflow в основной ветке репозитория. Проверяйте логи: совпадение сертификата и профиля, установка на iPhone и доставка в Telegram требуют проверки реальным запуском. Даже с подписанным IPA выбор игрового сервера и сетевое поведение не гарантированы.
