# Build notes

## Running the app

```bash
flutter pub get
flutter run            # pick a device
flutter test           # 19 widget smoke tests
flutter analyze        # expected: no issues
```

The app runs entirely on mock repositories seeded from the Stitch designs, so it needs no backend
and no network. See [`API_SPEC.md`](./API_SPEC.md) for the contract those mocks mirror.

## iOS simulator builds fail from this folder

**Symptom**

```
image_picker_ios.framework: resource fork, Finder information, or similar detritus not allowed
Command CodeSign failed with a nonzero exit code
```

**Cause**

The project lives under `~/Documents`, which is synced by iCloud Drive. The iCloud file provider
stamps build outputs with the `com.apple.FinderInfo` and `com.apple.fileprovider.fpfs#P` extended
attributes. `codesign` refuses to sign a bundle carrying those, and the attributes are reapplied by
the OS as fast as `xattr -c` strips them, so clearing them is not a durable fix.

This is an environment issue, not a problem with the app. The same commit builds and runs cleanly
from any folder outside iCloud, and Android builds fine in place.

**Fix — pick one**

1. **Move the project out of the synced folder.** The cleanest option, for example
   `~/dev/infio-partner`. Nothing in the project needs changing.
2. **Turn off Desktop & Documents syncing** in System Settings, iCloud, iCloud Drive.
3. **Build from a copy outside iCloud** when you only need to check something on the simulator:

   ```bash
   rsync -a --exclude build --exclude .dart_tool --exclude ios/Pods \
     ~/Documents/projects/infio-partner/ /tmp/infio-build/
   cd /tmp/infio-build && flutter pub get && flutter run
   ```

Two mitigations are already committed and reduce the surface, though they are not sufficient on
their own because Flutter signs `Flutter.framework` through its own build phase:

- `ios/Podfile` skips code signing for pod frameworks on the simulator SDK only.
- `ios/Flutter/Debug.xcconfig` does the same for the Runner target.

Both are scoped with `[sdk=iphonesimulator*]`, so device builds and archives sign normally.

## Code signing identity

`flutter create` auto-selected a developer team and wrote `DEVELOPMENT_TEAM` into
`ios/Runner.xcodeproj/project.pbxproj`. That has been removed — the project carries no signing
identity. `CODE_SIGN_STYLE` is left as `Automatic`, so whoever opens it in Xcode picks their own
team when they first build for a device.

## Android

Builds in place with no changes:

```bash
flutter build apk --debug
```

`flutter doctor` reports unaccepted Android licenses on this machine. Debug builds work regardless;
run `flutter doctor --android-licenses` before a release build.
