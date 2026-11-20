# Signing completion notifications

Watch 0.5.29 / build 63; Android 0.6.23-local / code 45.

The Mac runner writes `Documents/watchbridge-renewal.json` only after extending actual provisioning expirations and installing the app. The watch posts one local notice per receipt ID and forwards it through the existing encrypted Bluetooth session. The phone acknowledges after accepting its notification; persisted receipt IDs prevent reconnect duplicates.

The notification includes the next expiration. An absent phone or disabled notification permission delays delivery. The weekly schedule, existing registration, settings, signing identity, installation IDs and vehicle-button configuration remain intact. No system logs or vehicle commands are used.

See [schedule, states and requirements](AUTO_RENEW_EN.md). Receipts remain in the private app container and local renewal-state directory; personal signing profiles, Team IDs, device IDs and state files are not published.

## This deployment

The 2026-11-20 16:00 weekly attempt failed while waiting for the watch development connection. This maintenance deployment obtained fresh profiles and installed over the same app and Team. The app expires **2026-11-27 19:52:41 KST**, and the widget **19:52:43 KST**.

REA install evidence: Watch `ev_7bbdd8b12ac2ef008ab3bfa0c3c8d928355fcd8a365640b55aae6a63d58ef074`; phone `ev_0ab3d11e170b350447a08952206420bb0356f76e2c9f6ffcad243c54e5ff40f8`. The phone app record and watch app preferences contained matching notification-acceptance and phone-acknowledgement IDs. This records successful notification API acceptance, not a direct visual observation of the popup. Only app-owned records were read; no system logs were collected.

The private renewal source was aligned to installed commit `6918306`, and its runner now includes completion receipts. The **Friday 16:00 weekly** schedule is unchanged; the next attempt is November 27 at 16:00. Renewal still requires the Mac and a usable watch development connection at that time.
