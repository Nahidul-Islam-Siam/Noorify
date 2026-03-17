# App Size Optimization (Noorify)

This project is now configured for smaller release builds.

## Applied in codebase

1. Release minification and resource shrinking are enabled:
- `isMinifyEnabled = true`
- `isShrinkResources = true`

2. Packaging excludes are added for common `META-INF` license files:
- file: `android/app/build.gradle.kts`

3. R8 full mode is enabled:
- `android.enableR8.fullMode=true`
- file: `android/gradle.properties`

4. Quran module is hidden from UI via feature flag (code kept for future):
- `kQuranFeatureEnabled = false`
- file: `lib/shared/services/app_globals.dart`

## Build commands (recommended)

### 1) Play Store upload (best path)

```bash
flutter build appbundle --release --tree-shake-icons --obfuscate --split-debug-info=build/symbols
```

Output:
- `build/app/outputs/bundle/release/app-release.aab`

### 2) Direct APK distribution (smaller than universal APK)

```bash
flutter build apk --release --split-per-abi --tree-shake-icons --obfuscate --split-debug-info=build/symbols
```

Outputs:
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

## Latest measured outputs on this machine

- `app-armeabi-v7a-release.apk` -> ~20.0 MB
- `app-arm64-v8a-release.apk` -> ~22.4 MB
- `app-x86_64-release.apk` -> ~23.8 MB
- `app-release.aab` -> ~48.1 MB

Notes:
- `AAB` file is larger as an upload artifact. Play Store serves optimized split installs to users.
- Device download size from Play Store will be smaller than the raw `.aab`.

## Practical guidance

1. For Play Store: always upload `.aab`.
2. For manual sharing: send only matching ABI APK (usually arm64).
3. Keep `build/symbols` safe for crash deobfuscation when using obfuscation.
