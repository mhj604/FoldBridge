# Signing completion notifications

Watch 0.5.29 / build 63; Android 0.6.23-local / code 45.

The Mac runner writes `Documents/watchbridge-renewal.json` only after extending actual provisioning expirations and installing the app. The watch posts one local notice per receipt ID and forwards it through the existing encrypted Bluetooth session. The phone acknowledges after accepting its notification; persisted receipt IDs prevent reconnect duplicates.

The notification includes the next expiration. An absent phone or disabled notification permission delays delivery. The weekly schedule, existing registration, settings, signing identity, installation IDs and vehicle-button configuration remain intact. No system logs or vehicle commands are used.

See [schedule, states and requirements](AUTO_RENEW_EN.md). Receipts remain in the private app container and local renewal-state directory; personal signing profiles, Team IDs, device IDs and state files are not published.
