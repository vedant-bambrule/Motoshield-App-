# MOTOSHIELD — Real App Setup

This is real code, not a demo — it needs a few one-time setup steps on your
machine before `flutter run` will work. Follow these in order.

## 1. Turn this into a runnable Flutter project

This zip only has the `lib/` code, not the Android/iOS platform folders
(those are machine-generated, not something to hand-copy). Generate them
fresh, then drop our code in:

```bash
flutter create --org com.motoshield --project-name motoshield motoshield_app
cd motoshield_app
rm -rf lib pubspec.yaml
# now copy in the lib/, pubspec.yaml, functions/, firestore.rules from this zip
flutter pub get
```

## 2. Add Android permissions

Open `android/app/src/main/AndroidManifest.xml` and add these lines inside
the `<manifest>` tag, above `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

## 3. Create the Firebase project (manual — needs your Google login)

See the step-by-step card from chat: create the project at
console.firebase.google.com, register the Android app as `com.motoshield.app`,
enable Email/Password auth, create a Firestore database (Mumbai region).

## 4. Connect the app to your real Firebase project

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=motoshield
```
This **overwrites** `lib/firebase_options.dart` with your real keys. That's
expected — the placeholder in this zip is just so the code compiles before
you've done this step.

## 5. Deploy the security rules (do this before test mode expires!)

```bash
firebase deploy --only firestore:rules
```

## 6. (Optional but needed for real family alerts) Deploy the Cloud Function

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```
Note: this step requires Firebase's "Blaze" (pay-as-you-go) plan to deploy —
free-tier usage should stay $0 for personal testing, but Firebase requires a
card on file for Functions specifically. Everything else in the app (crash
detection, SOS screen, Firestore logging) works fine without this — you just
won't get automatic pushes to family until it's deployed.

## 7. Run it on your phone

```bash
flutter run
```
Use a real device, not an emulator — accelerometer/gyroscope data from
emulators isn't realistic enough to test crash detection.

## 8. Tuning crash detection

Open `lib/services/crash_detection_service.dart`. The thresholds at the top
(`impactThresholdMs2`, `tiltThresholdRadS`, `suddenStopDropKmh`) are starting
points. Test by mounting your phone like it'll actually ride, then simulate
a drop (onto a bed/cushion, not concrete!) and watch whether it triggers —
adjust the numbers from there.

## What's real vs. what's next

**Real and working today:**
- Firebase email/password login
- Real GPS tracking + free OpenStreetMap live map
- Real accelerometer/gyroscope crash detection (rule-based)
- Real Firestore storage for rides, contacts, alerts
- Real push notifications to your own device

**Needs the Cloud Function deployed (step 6):**
- Alerts actually reaching a family member's phone

**Good next upgrades, not built yet:**
- Phone-number OTP login (needs SHA key setup in Firebase console)
- Family member accounts that see the rider's live location in real time
  (right now, contacts are just names/phones — not linked user accounts)
- Replacing the rule-based detector with a trained ML model
