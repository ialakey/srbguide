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

### Deadline reminders
Missing a Serbian deadline costs money. The app tracks visa runs, residence-permit renewal,
paušal tax (the 15th of every month), eco tax (30 April), insurance and document expiry, and
notifies ahead of each one. Dates are derived from what the obligation *is*, so most reminders
need no data entry; monthly and yearly ones roll forward on their own. Scheduling is deliberately
inexact — exact alarms are a Play-restricted permission that a reminder app does not need.

### "My path" checklist
The guide explains *how* to do each thing; the checklist says *what to do next*. 24 steps across
six stages, each linked to the article that explains it, with progress on the home screen.

### Live exchange rates
Serbian exchange offices don't publish an API, so the app scrapes their public pages directly.
Four independent parsers live in `lib/service/parser/` — one per office — each matching rows by
**currency code** rather than row position, because these sites renumber their tables regularly
and positional parsing fails silently. The best rate across offices is highlighted, the National
Bank reference rate is shown as a yardstick, and the last successful fetch is cached so the screen
still works offline.

### Offline guide
The relocation guide — 74 articles in 8 sections — ships as Markdown inside the app
(`assets/data/guide.json`), mirrored from [srb.guide](https://www.srb.guide/) with the authors'
permission and re-scraped weekly by CI. Rendered with full-text search, favourites and an
adjustable font size. **It works with no connection** — which matters on day one in a new country,
before you have a local SIM.

Search stems the query, so the Russian "банка" finds "банки" and "банковский"; results are ranked
title-first and show the snippet that matched.

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
| UI | Material 3, one seeded `ColorScheme` for light and dark |
| Content | Offline JSON + Markdown in `assets/data/`, rendered with `flutter_markdown_plus` |
| Scraping | `http` + `html` — one parser class per exchange office |
| Reminders | `flutter_local_notifications` + `timezone` |
| Documents | `docx_template` + `xml` for `.docx` generation, `open_file` / `share_plus` to export |
| Integrations | `add_2_calendar`, `url_launcher`, `webview_flutter`, `photo_view` |
| CI | GitHub Actions — analyze/test, weekly content sync, signed release, daily parser health |

---

## Project structure

```
lib/
├── main.dart                  # bootstrap: prefs, locale, theme, warm caches
├── data/                      # models + repositories
│   ├── guide_dto.dart         #   guide content model
│   ├── guide_repository.dart  #   single cached load, search, favourites
│   ├── deadline.dart          #   deadline kinds and their default schedules
│   ├── journey.dart           #   the relocation checklist
│   └── currency_rate.dart
├── screens/
│   ├── app_shell.dart         #   NavigationBar: Home / Guide / Services / Saved
│   ├── home.dart              #   search, rate, next deadline, checklist progress
│   ├── guide.dart             #   collapsible sections
│   ├── article.dart           #   reader: text size, bookmark, source link
│   ├── guide_search.dart      #   stemmed full-text search
│   ├── deadlines.dart         #   reminders
│   ├── journey.dart           #   "my path" checklist
│   ├── exchange_rate.dart     #   best rate, NBS reference, converter
│   ├── calculator.dart        #   visa-free day counter + calendar export
│   ├── white_cardboard.dart   #   .docx form generation
│   ├── services.dart, map.dart, tg_chats.dart, favourites.dart
│   ├── author.dart, settings.dart
├── service/
│   ├── exchange_rate_service.dart  # parallel fetch, offline cache, best rate
│   ├── notification_service.dart   # scheduling
│   ├── document_generate.dart      # .docx rendering from template
│   └── parser/                     # one scraper per exchange office
├── theme/app_theme.dart       # Material 3 light + dark
├── utils/search_stem.dart     # Russian query stemming
├── widget/                    # reusable UI
├── localization/, l10n/       # AppLocalizations + ARB files
tool/
├── sync_guide.dart            # re-scrape srb.guide -> assets/data/guide.json
└── validate_guide.dart        # sanity gate before that content is committed
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

Refresh the bundled guide from the website:

```bash
dart run tool/sync_guide.dart
```

Release builds and signing are documented in [`docs/RELEASE.md`](docs/RELEASE.md).

---

## Continuous integration

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | push / PR | format, analyze, tests, guide validation, debug build |
| `sync-guide.yml` | weekly | re-scrapes srb.guide, validates, commits only real changes |
| `release.yml` | tag `v*` | signed AAB + APK, verifies the signature, draft release |
| `parsers.yml` | daily | runs the parsers against the live sites, opens an issue on failure |

The daily parser check is the important one. The exchange offices redesign without notice, and two
of the four parsers had been returning nothing for months before anyone noticed — the whole point
of that job is that CI finds out before users do.

---

## Notes

The exchange-rate parsers depend on the HTML of third-party sites and will break when those sites
are redesigned. Each parser is isolated so a broken office degrades that one card rather than the
screen, and each card reports its own failure with a retry.

Guide content belongs to the authors of srb.guide and is used with their permission; see
[`NOTICE`](NOTICE). The MIT licence in [`LICENSE`](LICENSE) covers the source code only.

---

## Author

Ilia Alakov — [LinkedIn](https://www.linkedin.com/in/ilia-alakov/) ·
[GitHub](https://github.com/ialakey) · [Medium](https://medium.com/@alakov.ilia) ·
[Habr](https://habr.com/ru/users/i_alakey/) · alakov.ilia@gmail.com
