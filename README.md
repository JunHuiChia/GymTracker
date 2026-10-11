# GymTracker

A personal Android workout tracker built with Flutter. Exercises, plans and workout records stay in a local SQLite database. There are no accounts or remote services.

## Using the app

1. Create a plan and add exercises from the 35-item catalogue, or create a custom exercise in the picker.
2. Set target sets/reps. Dragging or Move up / Move down only organises the displayed list; it never dictates workout order.
3. Start the plan. The performed date defaults to today and can be changed in the workout checklist.
4. Open any available exercise, enter kg/reps and check completed sets. Back to workout returns to the checklist so you can choose or revisit any exercise. Valid entries save automatically; Resume restores an active workout.
5. Review and finish. History supports correcting dates and set records; Stats charts exercise weight, reps, sets and training volume.

Weight means total external load, including the bar or both dumbbells. Bodyweight movements accept 0 kg and track reps/sets. Training volume is the sum of each completed set's kg × reps, expressed as kg·reps; it is not an estimated strength score.

Editing a plan does not rewrite workout history. Archived custom exercises and plans retain their old references. Draft workouts, unchecked sets and skipped exercises do not contribute to progress statistics.

## Run and test

Use Flutter stable and the Android toolchain, then:

```powershell
flutter pub get
flutter devices
flutter run -d <android-device-id>
flutter analyze
flutter test
```

The Android integration check uses a separate disposable database and labels its sample plan explicitly. It does not populate the personal workout database:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d <android-device-id>
```

Emulator screenshots are written under `.impeccable/review`. These contain synthetic test records. Database tests also check persistence across a real file close/reopen, session snapshot isolation, input validation, volume calculations and deletion behaviour.

## Personal APK

Build with `flutter build apk --release`. The universal APK is `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the Android phone and allow installation from the app used to open the APK when Android requests it. Install future updates over the existing app without uninstalling.

Application ID: `dev.jeffe.gym_tracker`. Current version: `0.2.0+2`, updating the initial `0.1.0+1`. Use the same application ID and release signing key for updates. The database schema is unchanged.

On this development PC, the private release keystore is `C:\Users\jeffe\.android\signing\gymtracker-release.jks`; its password/configuration is in the ignored `android/key.properties`. Keep both securely backed up and out of shared source archives. A different signing key cannot update the installed APK. Debug builds use a different key and cannot be installed over the release build without uninstalling; use release builds for personal workout history.

Other checkouts can build debug APKs without the release key. Release signing is configured only when `android/key.properties` exists; do not distribute an unsigned release APK.

## Storage limits

Cloud backup and database device transfer are disabled. Uninstalling, clearing app data or losing the phone can lose all workout records; this risk is accepted for this MVP. Manual export/restore, cloud sync, timers, iOS and Play Store publishing are deferred.

Physical phone performance, gestures and hardware-specific behaviour require a personal gym trial. See IMPLEMENTATION_PLAN.md and DEVELOPMENT_ENVIRONMENT.md for product scope and setup history.

## Verified locally

Fifteen database/interface tests and static analysis pass. Native Android 13 integration verifies custom exercise/plan creation, variable completed sets, skipped exercises, persistent resume, history and exact training volume. Light/dark phone screenshots and compact 360 dp layouts at 1.3 text scale were reviewed. The integration capture uses --no-enable-impeller on the emulator; release builds retain Flutter's default renderer. Physical-phone and tablet/desktop visual checks remain outstanding; Android phone use is the shipping target.


Final deliverable: artifacts/GymTracker-0.2.0.apk (52,877,913 bytes), version 0.2.0+2. APK Signature Scheme v2 verification passed, and its certificate matches 0.1.0. The signed release installed over 0.1.0 and opened on the Android 13 test emulator with the default renderer. A synthetic saved plan and completed 42.5 kg × 8 workout survived the update; the retained database was reopened and verified (340 kg·reps). Twenty final native captures were reviewed against the approved mockup, including light and dark/enlarged-text layouts. Physical-device upgrade testing remains outstanding.

