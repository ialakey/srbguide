# Serbia Guide

**A Flutter app for people relocating to Serbia.** It answers the questions every newcomer hits in
their first months: how many visa-free days are left, how to fill in a *beli karton*, where today's
best exchange rate is, and which Telegram chat to ask.

<p>
  <a href="https://play.google.com/store/apps/details?id=com.alakey.serbiaguide">
    <img src="https://img.shields.io/badge/Google_Play-Download-4285F4?style=for-the-badge&logo=google-play&logoColor=white" alt="Google Play"/>
  </a>
  <img src="https://img.shields.io/badge/Flutter-3-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Platforms-Android_·_iOS-555?style=for-the-badge" alt="Platforms"/>
</p>

Part of a three-repository system:

| Repository | Role |
|---|---|
| **srbguide** (this one) | Flutter mobile client |
| [serbiaguide](https://github.com/ialakey/serbiaguide) | Spring Boot REST API — locations, guides, Telegram chat directory |
| [serbiaguide-front-admin](https://github.com/ialakey/serbiaguide-front-admin) | React admin panel for editing the content |

---

## Screenshots

<p float="left">
  <img src="https://github.com/ialakey/srbguide/assets/56916175/428ef8e7-e7df-4049-93ee-9d8d6b1f5ead" width="220" alt="Guide"/>
  <img src="https://github.com/ialakey/srbguide/assets/56916175/2e1b3291-04c9-423c-92ff-de1efc0778d8" width="220" alt="Visa-free calculator"/>
  <img src="https://github.com/ialakey/srbguide/assets/56916175/f36625a3-e231-4afe-be7d-2d7b1fbccf80" width="220" alt="White cardboard"/>
</p>
<p float="left">
  <img src="https://github.com/ialakey/srbguide/assets/56916175/c15b40a3-95d1-4b03-8ca7-855125645077" width="220" alt="Exchange rates"/>
  <img src="https://github.com/ialakey/srbguide/assets/56916175/b41deac0-51d9-4a64-8ceb-a980c7cb29c9" width="220" alt="Map"/>
</p>

---

## Features

### Visa-free stay calculator
Enter your entry date and the app tracks the remaining days of the 29-day visa-free window, shows
the exit deadline, and pushes the date straight into the system calendar via `add_2_calendar`, so
the reminder survives even if the app is uninstalled.

### White cardboard (*beli karton*) generator
Address registration in Serbia means filling in the same form by hand every time you move. The app
stores your data once and renders a ready-to-print `.docx` from a bundled template
(`assets/template/cardboard.docx`) using `docx_template`, then hands it to the system share sheet.

### Live exchange rates
Serbian exchange offices don't publish an API, so the app scrapes their public pages directly.
Five independent parsers live in `lib/service/parser/` — one per office — each returning a normalized
rate. Adding a sixth office means adding one parser file, nothing else changes.

### Offline guide
The relocation guide ships as Markdown inside the app (`assets/data/guide.json` plus 112 images in
`assets/data/media/`), rendered by `flutter_markdown` with full-text search, favourites, and an
adjustable font size. **It works with no connection** — which matters on day one in a new country,
before you have a local SIM.

### Map of useful places
A curated set of Google Maps searches — exchange offices, non-smoking cafés, expat-friendly venues —
defined in `assets/data/locations.json` and rendered in an embedded `webview_flutter` view with a
dropdown to switch between them.

### Telegram directory
A curated list of relocation chats and channels (`assets/data/tg_chats.json`), opened directly in
the Telegram app through `url_launcher`.

### Personalisation
Light/dark theme, RU/EN localisation, adjustable text size, and a configurable start screen — all
persisted with `shared_preferences` and restored on launch.

---

## Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter, Dart |
| State | `provider` (`LanguageProvider`) + `setState` for local screen state |
| Persistence | `shared_preferences` (theme, language, start screen, saved form data) |
| Localisation | `flutter_localizations` + ARB files (`lib/l10n/app_en.arb`, `app_ru.arb`) |
| Content | Offline JSON + Markdown in `assets/data/`, rendered with `flutter_markdown` |
| Scraping | `http` + `html` — one parser class per exchange office |
| Documents | `docx_template` + `xml` for `.docx` generation, `open_file` / `share` to export |
| Integrations | `add_2_calendar`, `url_launcher`, `webview_flutter`, `photo_view` |

---

## Project structure

```
lib/
├── main.dart                  # bootstrap: prefs, locale, theme, initial screen
├── screens/                   # one file per screen
│   ├── calculator.dart        #   visa-free day counter + calendar export
│   ├── white_cardboard.dart   #   .docx form generation
│   ├── exchange_rate.dart     #   aggregated rates from all parsers
│   ├── guide.dart             #   Markdown guide + search
│   ├── guide_favourite.dart
│   ├── map.dart
│   ├── tg_chats.dart
│   └── settings.dart
├── service/
│   ├── document_generate.dart # .docx rendering from template
│   └── parser/                # one scraper per exchange office
│       ├── dok_parser.dart
│       ├── funta_parser.dart
│       ├── gaga_parser.dart
│       ├── promonet_parser.dart
│       └── exchange_office.dart
├── provider/language_provider.dart
├── widget/                    # reusable UI: app bar, drawer, cards, search, themed icons
├── localization/              # AppLocalizations wrapper over the ARB files
└── l10n/                      # app_en.arb, app_ru.arb
```

---

## Running locally

```bash
git clone https://github.com/ialakey/srbguide.git
cd srbguide
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

No API keys or backend are required — the app ships its content offline and only reaches the
network for live exchange rates.

---

## Notes

The exchange-rate parsers depend on the HTML of third-party sites and will break when those sites
are redesigned. Each parser is isolated so a broken office degrades that one row rather than the
screen.

---

## Author

Ilia Alakov — [Telegram](https://t.me/i_alakey) · [LinkedIn](https://www.linkedin.com/in/ilia-alakov)
