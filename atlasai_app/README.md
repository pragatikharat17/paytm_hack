# atlasai_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend connection

Start the backend from `atlasai_backend`:

```sh
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The Android default uses `http://10.2.30.85:8000`. For a physical phone,
connect the phone and backend computer to the same network and override the
address if the computer's LAN IP changes:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000
```

For the Android emulator:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Web and desktop default to `http://localhost:8000`. Ensure port 8000 is
reachable from the device. Rebuild/relaunch after changing `API_BASE_URL`.
