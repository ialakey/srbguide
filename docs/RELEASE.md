# Release & signing

Two ways to produce the same artifact under the same checks:

| | |
|---|---|
| locally, on Windows | `.\tool\build_release.ps1` |
| in CI, on a `v*` tag | the `Release` workflow |

Both refuse to publish anything that is not signed with a real SHA-256 upload
key. What Play asks for on the upload screen — the "What's new" text — is
in [play/](play/); the full account of the release is in
[CHANGELOG.md](CHANGELOG.md).

## The short version

```powershell
# once, ever
.\tool\create_upload_key.ps1   # creates the key, prints what Play asks for
.\tool\show_upload_key.ps1     # prints it again later, if you need it

# bump `version:` in pubspec.yaml, then, for every release
.\tool\build_release.ps1
```

The bundle lands in `dist/srbguide-<version>+<code>.aab`. Upload that;
`dist/srbguide-<version>+<code>.apk` is for sideloading and manual QA.

## 1. Create the upload key (once)

Google Play requires RSA 2048+ and a validity that runs past 2033. `-sigalg
SHA256withRSA` is what makes the certificate itself SHA-256; the workflow
verifies this and fails if the key uses an older algorithm.

```powershell
.\tool\create_upload_key.ps1
```

It prompts for a password, runs the `keytool` invocation below, checks the
certificate really is SHA-256, and writes `android/key.properties` for you. The
keystore stays on this machine: nothing copies it anywhere, and CI never sees
it.

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

Keep `upload-keystore.jks` and its passwords somewhere safe and offline. A
SHA-256 fingerprint is a hash of the certificate, so a fingerprint you wrote
down somewhere is not a spare copy of the key — nothing can be signed with it.

## 1a. Registering the key with Play

Play needs to know the public half of whichever key you sign uploads with. It
asks for it in one of two forms depending on the screen:

```powershell
.\tool\show_upload_key.ps1
```

That prints the **SHA-256 fingerprint** to paste into "Добавьте открытый ключ,
указав его цифровой отпечаток сертификата SHA-256", and writes a **PEM
certificate** next to the keystore for the screens that take a file instead.
Both are public; the keystore and its password never leave the machine.

This matters because the app signing key and the upload key are different
things. Under Play App Signing, Google holds the app signing key that end users
verify, and it re-signs every release — so replacing the upload key does not
break updates for anyone who already has the app installed. The upload key only
proves that an upload came from you. Losing it is recoverable; losing the app
signing key would not be, and you never had it.

Compare what Play shows under **App integrity → App signing → Upload key
certificate** with what `show_upload_key.ps1` prints. If they differ, the build
will be rejected at upload with "the APK was signed with the wrong key".

## 2. Keep the key off GitHub

There is nothing to add. `release.yml` reads no secrets, and asserts that the
APK it produced carries the debug certificate — an artifact signed with the
real upload certificate would mean the key had reached a runner, and anyone
holding that build could then publish as this app.

If `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
or `ANDROID_KEY_PASSWORD` are still set under
`Settings → Secrets and variables → Actions`, delete them: nothing reads them
any more, and a secret that exists is a secret that can leak.

## 3. Building locally

`tool/build_release.ps1` is the only path to a Play-ready artifact. It resolves the
Flutter SDK, JDK and Android build-tools by itself (SETUP.md records how they
are pinned on this machine), so no PATH setup is needed.

```powershell
.\tool\build_release.ps1                              # version from pubspec.yaml
.\tool\build_release.ps1 -VersionName 2.0.1 -BuildNumber 14
.\tool\build_release.ps1 -BundleOnly                  # skip the APK
.\tool\build_release.ps1 -SkipChecks -SkipClean       # fast rebuild, never for upload
```

It stops before spending a build on:

- a missing or incomplete `android/key.properties`, or a keystore that is not
  where that file says it is;
- an upload key that is not `SHA256withRSA`;
- a `versionCode` Play has already seen (`-PublishedBuildNumber`, currently
  `12`; raise the default in the script after each accepted upload).

Then it runs `flutter analyze`, the unit tests and `tool/validate_guide.dart`,
builds both artifacts at an explicit version, verifies the signatures, asserts
the merged manifest still targets SDK 36, and copies the results into `dist/`
with their SHA-256 sums. `dist/` is git-ignored.

The key is read from `android/key.properties`, which is git-ignored:

```properties
storeFile=D:\\path\\to\\upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Gradle loads that file as a `java.util.Properties`, so on Windows the
backslashes have to be doubled; an absolute path avoids a second trap, since
Gradle resolves a relative one against `android/app`.
`create_upload_key.ps1` writes both correctly.

Without that file the release build falls back to the debug signing config so
`flutter run --release` still works. **A debug-signed bundle will be rejected by
Play** — both the script and the workflow fail the build rather than letting
one through.

## 4. Cutting a release

`versionName` and `versionCode` both come from one line in `pubspec.yaml`:

```yaml
version: 2.0.0+14
```

`android/app/build.gradle.kts` reads them from there through
`flutter.versionCode` / `flutter.versionName`, and `build_release.ps1` passes
both to `flutter build` explicitly, so what ships is what the log printed.

```bash
# bump `version:` in pubspec.yaml first
git tag v2.0.0
git push origin v2.0.0
```

The tag triggers `Release`, which:

1. runs `flutter analyze`, the unit tests and `tool/validate_guide.dart`;
2. checks the tag against `version:` in `pubspec.yaml` — `v2.0.0` must be
   `2.0.0`, so a tag can never claim a version the build does not carry;
3. builds the APK at that exact `versionName`/`versionCode`, with no
   `key.properties`, so Gradle falls back to the debug signing config;
4. runs `apksigner verify` and requires the **debug** certificate, which is the
   usual check inverted: a real certificate here would mean a leak;
5. asserts the merged manifest still has `targetSdkVersion="36"`;
6. uploads `srbguide-<version>-debug-signed.apk` with its SHA-256 and opens a
   **draft** GitHub Release explaining what the artifact is.

That APK is for putting a tagged build on a phone, not for Play. The bundle for
Play comes from `tool/build_release.ps1` on the release machine, whose summary
prints the certificate SHA-256 fingerprint — the value to compare against
"Upload key certificate" in the Play Console.

## 5. Before uploading to Play

- `versionCode` must be higher than the published one: production is on
  `12` (1.0.0), published 21 January 2024.
- Play requires `targetSdk` 36 (Android 16); step 6 above guards this.
- `minSdk` is 24, so Android 5.x devices no longer receive updates.

Upload `dist/srbguide-<version>+<code>.aab` under **Production → Create new
release**, and paste the release notes from:

| Play language | File |
|---|---|
| Russian | `docs/play/whats-new-ru-RU.txt` |
| English | `docs/play/whats-new-en-US.txt` |

Both fit Play's 500-character limit for the "What's new" field. The unabridged
version of the same release is [CHANGELOG.md](CHANGELOG.md), which is for the
repository rather than for the listing.

The bundle is around 60 MB, which is not what anyone downloads: half of it is
the native debug symbols Play keeps for crash symbolication, and the rest
carries all three ABIs. Play delivers one ABI per device, so the install is far
smaller — the Play Console shows the real figure once the bundle is processed.
