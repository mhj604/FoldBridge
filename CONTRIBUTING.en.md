# Contributing

[한국어](CONTRIBUTING.md) · **English** · [Documentation](docs/README.md)

Korean and English issues, documentation edits, translations, and pull requests are welcome. `local-ble` is the direct BLE configuration; `main` also contains the current implementation. Create a working branch from the current source:

```sh
git clone --branch local-ble https://github.com/mhj604/FoldBridge.git
cd FoldBridge
git switch -c fix/your-change
```

## Find the relevant code

| Path | Responsibility |
| --- | --- |
| `android/app/src/main/java/dev/foldbridge/` | Notification listener, GATT server, crypto, pending outbox, Android UI |
| `watch/FoldBridge/` | GATT client, authentication, notification body, keepalive, SwiftUI |
| `watch/generate_project.py` | Xcode project and Info.plist generation |
| `localization/en.json` | Shared English translation catalog |
| `tools/generate-app-icon.swift` | Shared FoldBridge icon generation |
| `docs/` | Korean/English current guides and archived earlier notes |
| `relay/`, `windows/`, `legacy/` | Earlier designs outside the current Local runtime |

[Build instructions](docs/BUILD_AND_SETUP_EN.md) explain signing and tools; [setup](docs/QUICK_START_EN.md) covers first installation. Use your own Android key and Apple team. If generated Xcode settings change, update the generator as well.

## Reporting a problem

Use [GitHub Issues](https://github.com/mhj604/FoldBridge/issues). State the Android/watch app versions, device models and OS versions, what you pressed, expected/actual behavior, and whether the watch app was visible, backgrounded, or force-quit. Ordinary connection/permission stages and error text are enough to start; private messages, identifiers, personal logs, signing keys, and provisioning files do not belong in public reports.

Current Local operation uses no runtime server/internet, root access, or workout/audio keepalive session. Describe the actual supported behavior and watchOS runtime conditions when changing connection logic.

## Translating the app

Edit `localization/en.json` and run:

```sh
python3 tools/generate-localization.py
```

Korean UI strings are the keys. Android and watchOS share the catalog; do not edit generated string resources or `I18n.java` directly. If Swift/resource project composition changes, also run `python3 watch/generate_project.py`. Commit the generated resources with the catalog change. Forwarded message contents, source app names, and user-assigned device names keep their original text.

## Maintaining documentation

Use [the bilingual index](docs/README.md) to find paired files. Update both languages when changing current setup steps, versions, downloads, behavior, or limitations. Keep the language switch at the top of each guide. Older release notes remain historical; describe current operation in the current guides and summarize significant history in both languages.

For a PR, explain the user-visible change, relevant implementation, and any remaining limits. Documentation-only contributions do not require rebuilding or reinstalling the apps.
