# Release & signing

The `Release` workflow builds a signed App Bundle and APK and refuses to publish
anything that is not signed with a real SHA-256 upload key.

## 1. Create the upload key (once)

Google Play requires RSA 2048+ and a validity that runs past 2033. `-sigalg
SHA256withRSA` is what makes the certificate itself SHA-256; the workflow
verifies this and fails if the key uses an older algorithm.

```bash
keytool -genkeypair \
  -alias upload \
  -keyalg RSA -keysize 4096 \
  -sigalg SHA256withRSA \
  -validity 10000 \
  -keystore upload-keystore.jks \
  -storetype PKCS12 \
  -dname "CN=Ilia Alakov, O=Serbia Guide, C=RS"
```

Keep `upload-keystore.jks` and its passwords somewhere safe and offline. If you
lose them you cannot ship an update to the existing listing — you would have to
ask Play support to reset the upload key.

## 2. Add the repository secrets

`Settings → Secrets and variables → Actions → New repository secret`:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | key password |

On macOS use `base64 -i upload-keystore.jks | tr -d '\n'`.

## 3. Building locally

The same key can be used locally through `android/key.properties`, which is
git-ignored:

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

```bash
flutter build appbundle --release
```

Without that file the release build falls back to the debug signing config so
`flutter run --release` still works. **A debug-signed bundle will be rejected by
Play** — the workflow fails the build rather than letting one through.

## 4. Cutting a release

```bash
# bump `versionCode`/`versionName` in android/app/build.gradle.kts first
git tag v1.1.0
git push origin v1.1.0
```

The tag triggers `Release`, which:

1. runs `flutter analyze` and the unit tests;
2. verifies the signing secrets exist and that the key is `SHA256withRSA`;
3. builds the AAB and APK;
4. runs `apksigner verify` and requires **APK Signature Scheme v2** plus a
   SHA-256 certificate digest, and fails if the artifact carries the Android
   debug certificate;
5. verifies the AAB with `jarsigner -verify -strict`;
6. asserts the merged manifest still has `targetSdkVersion="36"`;
7. uploads both artifacts and opens a **draft** GitHub Release.

The run summary prints the certificate SHA-256 fingerprint — that is the value
to compare against "Upload key certificate" in the Play Console.

## 5. Before uploading to Play

- `versionCode` must be higher than the published one (currently `11`).
- Play requires `targetSdk` 36 (Android 16); step 6 above guards this.
- `minSdk` is 24, so Android 5.x devices no longer receive updates.
