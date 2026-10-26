# Sarathy mobile app

One Flutter codebase for the Sarathy transit platform.

- **Passenger** — anonymous stop search, live ETA, live map. No account, no login.
- **Crew** — staff login, trip start/stop, GPS pings, incident reporting.
- **Operator** — development/demo only. The production operator console is
  `apps/web-admin`.

## Flavors

| Flavor | Package ID | Audience | Background location |
|---|---|---|---|
| `passenger` | `com.sarathy.transit` | Store build | No |
| `crew` | `com.sarathy.transit.crew` | Sideload / MDM | Yes |
| `dev` | `com.sarathy.transit.dev` | Local demos (internal) | Crew-level |

The dev build keeps the role-selection screen. The passenger flavor starts
directly on the passenger experience and contains no login surface.

## Configuration

URLs are injected at build time so no domain is hardcoded:

```bash
flutter run \
  --dart-define=SARATHY_API_URL=https://api.example.com/api/v1 \
  --dart-define=SARATHY_WS_URL=wss://api.example.com
```

Defaults target the Android emulator (`http://10.0.2.2:8000`).

## Develop

```bash
flutter pub get
flutter analyze
flutter test
flutter run --flavor dev -t lib/main.dart --dart-define=SARATHY_API_URL=...
```

`dev` is an internal role-picker build (`com.sarathy.transit.dev`), not a release
artifact. Product flavors replace the default variant, so a flavor is required
for every `flutter run` / `flutter build`.

## Build

```bash
flutter build apk --flavor passenger -t lib/main_passenger.dart --dart-define=SARATHY_API_URL=...
flutter build appbundle --flavor passenger -t lib/main_passenger.dart --dart-define=SARATHY_API_URL=...
flutter build apk --flavor crew -t lib/main_crew.dart --dart-define=SARATHY_API_URL=...
flutter build appbundle --flavor crew -t lib/main_crew.dart --dart-define=SARATHY_API_URL=...
```

Release signing requires `android/key.properties` and a keystore; neither is
committed. See `docs/release.md` once the signing keys exist.

iOS crew background-location mode (`UIBackgroundModes` / `location`) and dedicated
Xcode schemes/signing are still pending — they cannot be verified on Linux and
are intentionally not added to the shared Info.plist (would affect passenger).
On Android the crew build runs geolocator's foreground location service with a
persistent notification during an active trip; the passenger build declares no
location permission at all.

## Structure

```
lib/
├── core/        config, constants, routing, theme, utils
├── features/    passenger, crew, operator, shared screens
├── models/      API and session models
└── services/    api, auth, location, websocket
```

Brand assets live in `assets/`.
