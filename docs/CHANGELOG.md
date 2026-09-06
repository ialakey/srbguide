# Changelog

Versions are `versionName+versionCode`, both from `version:` in `pubspec.yaml`.
The short "What's new" texts that go into the Play Console live in
[docs/play/](play/).

## 2.0.0+14 — unreleased

The first release since January 2024. The app was rebuilt around Android 16,
the guide it ships was re-scraped from srb.guide, and four screens are new.
Everything below is what a user of 1.0.0 (versionCode 12) will notice.

### The guide

- **74 articles across 8 sections**, up from 5 articles. Re-synced from
  srb.guide with `tool/sync_guide.dart`; each article now carries its source URL
  and last-modified date, and credits the original on screen.
- **Articles render correctly.** The old reader split the text on newlines and
  built a separate Markdown widget per line, which broke every construct that
  spans lines — lists, tables, quotes, fenced code.
- **Search understands Russian inflection.** The query is stemmed, so
  "документы" also finds "документов". Adds a section filter, ranking, and a
  snippet of the matching text under each hit.
- **The guide updates itself between releases.** Once a day the app asks GitHub
  whether the bundled guide changed, conditional on an ETag, so an unchanged
  guide costs a single 304. A download is validated before it is accepted and
  the bundled copy stays the fallback, so a bad fetch cannot leave the app with
  no content. Settings has a manual "check now".
- **Favourites survive guide updates.** They store the article id instead of a
  copy of the text, so a saved article follows the guide when it is re-synced.
  Existing favourites are migrated by title.

### New: visa-free calculator (reworked)

The old screen assumed everyone gets 30 days from a single entry date, and its
remaining-days arithmetic truncated — at 10:00 the day before the deadline it
said zero days left when two were still available.

- **Three regimes**, as the guide's own calculator article describes them:
  30 days per entry (Russia, Belarus, China, Kazakhstan), 90 days in any 180
  (EU, USA, Ukraine and most others), 30 days in any 365 (Bahamas, Barbados,
  Colombia and five more).
- A rolling window cannot be answered from one date, so the screen keeps a
  **list of trips**. The single date the old screen stored is carried over on
  first run.
- Day counter with a progress ring, the must-leave-by date, and an overstay
  warning. Both the entry and the exit day count, as the guide states. Calendar
  days are anchored to UTC midnight, so adding days across the March clock
  change no longer loses one.
- The deadline can become a reminder or a calendar event.
- The arithmetic lives in `lib/data/visa_rule.dart` under 16 tests.

### New: deadlines with reminders

Local notifications for visa runs, residence-permit renewal, paušal tax, eco
tax, insurance and document expiry. Dates are derived from the obligation, and
the recurring ones roll forward on their own. Scheduling is deliberately
inexact — exact alarms need a Play-restricted permission this app does not
qualify for.

### New: "Мой путь" / My path

A 24-step relocation checklist across six stages — before the move, first days,
setting up a business, banks, temporary residence, and after — with every step
linked to the guide article that explains it. Progress is stored by article
slug, so it survives a guide re-sync.

### New: train timetable

Route search and a per-station departure/arrival board over the Serbian
Railways timetable at w3.srbvoz.rs, with recently used stations remembered.

**The class of train is back.** `Soko`, `InterCity`, `BG:Voz` and what a
service carries — travel classes, bicycles, whether a reservation is required —
are published as icons rather than text, so reading the cell's text left those
columns empty and the badge never appeared. Both are now read off the icons.

**Stations can be searched in Russian.** The operator's lookup only understands
Latin: its own front end strips everything else out of the term, and an empty
term is answered with all 396 stations — so typing "Белград" produced an
alphabetical dump of the whole network and looked like the search had stopped
working. The list is now fetched once, cached for a week and matched on device:
Cyrillic is transliterated, diacritics are folded, each word is allowed one
character of slack (Белград/Beograd, Крагуевац/Kragujevac), and the match runs
inside the name, so "centar" finds BEOGRAD CENTAR — which the server itself
could not do. The picker also stops answering a network failure with "nothing
found".

### New: one map, replacing the old "Карты" screen

362 businesses from the stats.srb.guide catalogue plus 145 non-smoking venues
from the *Lokali bez dima* map, together on one OpenStreetMap map. Both
catalogues are bundled, so the list and filters work offline and only the tiles
need a connection. OSM needs no API key and no billing account, unlike the
Google Maps SDK.

- Filter chips for the smoking policy — smoking banned outright, or smokeless
  devices only — next to the business categories, and a badge on the venue.
- A venue on both lists is matched by name and proximity, so it gets one pin
  rather than two.
- **The old "Карты" screen is gone.** It was a dropdown of Google My Maps links
  opened in a WebView: the Russian-venues map it pointed at is the same
  catalogue this screen already shows, the non-smoking map is now bundled as
  pins, and the exchange-office search moved into the map's toolbar. The
  "black list of apartments" link had been returning a Google 403 for a while
  and is dropped. `webview_flutter` goes with it.

### Images in the guide

- **The guide bundled blurred thumbnails instead of photos.** srb.guide runs
  Hugo behind lazysizes: every `<img>` carries a blurred placeholder of a few
  hundred bytes in `src` and the real file in `data-srcset` / `data-src`. The
  scraper read `src`, so 257 of the guide's 283 images were smudges. It now
  takes the widest published variant a phone can use — up to 1280px, rather
  than the 2268px original, which is twelve times the bytes for pixels no
  phone has.
- **Tap an image to open it full screen**, then pinch, double-tap or use the
  toolbar buttons to zoom in and out. Inline images are capped at half a screen
  so a portrait screenshot no longer pushes the article off the page, and both
  the inline image and the viewer report a failed load instead of leaving a
  blank space.

### Exchange rates

- **Two of the four parsers had been silently returning nothing for months.**
  funta.rs renumbered its columns and dropped `tbody.row-hover`;
  menjacnicegaga.rs replaced its table with a div ticker. promonet.rs assigned
  rows by index parity, so the CHF row was overwriting the RUB quote. All
  parsers now match rows by currency code rather than by position.
- **The National Bank of Serbia is a fifth source** and the only one with a real
  API. It replaces the previous reference rate, which was scraped out of one
  office's ticker. Reference sources are flagged and left out of the "best rate"
  comparison — the NBS is not a counter you can walk up to.
- Offices are queried in parallel, each card reports its own failure, the best
  rate is highlighted, the last good response is cached for offline use, and
  there is a converter.
- A daily CI job runs the parsers against the live sites and opens an issue when
  an office changes its markup, so a break is visible before users hit it.

### Telegram chats

432 chats from the catalogue, with topic, size and activity, replacing 340
hand-maintained entries that had drifted. Refreshed weekly along with the guide,
the places catalogue and the non-smoking map.

### Design

- Material 3 throughout, from one colour scheme. The seed used to be the Serbian
  flag red and Material 3 tints every surface with the seed, so backgrounds and
  cards came out pink; the palette is now a blue accent over a neutral surface
  ramp. Colour marks actions, the active tab and an urgent deadline, nothing
  else.
- A `NavigationBar` shell replaces the navigation drawer and the nested bottom
  bars.
- The default language follows the device instead of always starting in English.

### Under the hood

- **targetSdk 36 (Android 16)**, which Google Play now requires. AGP 9.1,
  Gradle 9.3.1, Kotlin 2.4, Java 17, the Kotlin DSL. `minSdk` moves 21 → 24
  (Flutter's floor), so Android 5.x devices no longer receive updates.
- Release signing is conditional on `android/key.properties`; the previous
  config threw at configuration time whenever that file was absent.
- `versionCode` and `versionName` now both come from `pubspec.yaml`.
- Search no longer re-lowercases every article on every keystroke (1.5 MB per
  search); the lowercased forms are computed once per article.
- The guide is parsed once and cached rather than re-read per screen.
- Seven `use_build_context_synchronously` violations fixed; the analyzer is
  clean and CI keeps it that way.
- 5.6 MB of orphaned images dropped from the repository.
- CI on every push: formatting, analysis, tests, guide validation, debug APK.
  A signed-release workflow that refuses to publish anything not signed with a
  SHA-256 upload key. MIT licence, and a NOTICE recording that it does not cover
  the guide content, which belongs to the authors of srb.guide and is used with
  their permission.

### Known limitations

- Article images are fetched from srb.guide, so article text is available
  offline but its images are not.
- iOS is unmaintained: the `ios/` project has no Podfile and still declares an
  iOS 11 deployment target, below what the current plugins require.

## 1.0.0+12 — 2024-01-21

Guide, visa-run calculator, white-card (beli karton) form, exchange rates,
Telegram chat directory, maps, favourites, RU/EN localisation.
