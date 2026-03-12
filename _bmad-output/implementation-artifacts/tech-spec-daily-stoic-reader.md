---
title: 'The Daily Stoic Reader'
slug: 'daily-stoic-reader'
created: '2026-03-12'
status: 'completed'
stepsCompleted: [1, 2, 3, 4, 5]
tech_stack: ['Flutter 3.x (Dart)', 'Python 3.9+ (extraction script)', 'pdfplumber', 'flutter_secure_storage', 'http (Dart)', 'intl (Dart)', 'google_fonts (Dart)']
files_to_modify: []
code_patterns: ['Clean architecture: models / services / screens / widgets', 'JSON asset keyed by MM-DD date string', 'State machine PDF parser handling 3 edge cases']
test_patterns: ['Widget tests for entry display', 'Unit tests for date lookup and parser']
---

# Tech-Spec: The Daily Stoic Reader

**Created:** 2026-03-12

## Overview

### Problem Statement

The user reads The Daily Stoic daily and wants a convenient way to look up any day's passage by date — accessible on both desktop (Mac/PC) and iPhone — without manually flipping through the book. The app should also generate a single-line AI summary suitable for a diary entry.

### Solution

A Flutter app (single codebase targeting macOS, Windows, iOS, Android) that reads from a pre-extracted JSON data file bundled in app assets. It defaults to today's date, displays the day's Stoic quote (formatted as a block quote in italics), the author's full explanation, and an optional AI-generated one-line diary summary. The AI summary is not required — the app is fully usable without it. On first run, the user may optionally configure an AI provider: Ollama (free, local, desktop only), OpenAI, or Anthropic Claude. The choice can be skipped and configured later via Settings.

### Scope

**In Scope:**
- One-time Python script to extract all 366 entries from the PDF into a structured JSON file
- Flutter app for macOS, Windows, iOS, Android
- Date picker defaulting to today's date
- Passage display: italic block-quoted Stoic quote, full author explanation, optional AI one-line diary summary
- Multi-provider AI support: Ollama (local, desktop only), OpenAI (GPT), and Anthropic (Claude)
- AI summary is optional — app is fully usable without it; summary section shows "Configure AI in Settings" if not set up
- First-run onboarding: AI setup is skippable; provider + credentials stored securely if configured
- Clean, sparse, stoic UI aesthetic

**Out of Scope:**
- Web app deployment
- Cloud sync or user accounts
- Multiple books or content sources
- Push notifications or reminders

---

## Context for Development

### Codebase Patterns

**Confirmed Clean Slate** — greenfield project. No existing code constraints.

**PDF Structure (verified by investigation):**
- 407 pages total. 366 entry pages (pages 14–392). Each day is exactly one page.
- Entry page format (consistent across all 366 entries):
  - Line 0: `Month Nth` (e.g., `January 1st`)
  - Line 1: `TITLE IN ALL CAPS`
  - Lines 2–N: Quote starting with `\u201c` (LEFT DOUBLE QUOTATION MARK)
  - Attribution line: starts with `\u2014` (EM DASH) — or without em dash in 1 edge case (July 29)
  - Body: everything after attribution

**PDF Parser — 3 edge cases to handle:**
1. **July 29**: Attribution has no leading em dash (`SENECA, MORAL LETTERS, 111.2` not `—SENECA...`)
2. **September 28**: Quote has no closing `\u201d` — em dash on next line signals end of quote
3. **Author names in body** (Aug 2, Aug 26, Oct 1): avoided by state machine (only captures first post-quote line as attribution)

**JSON data format** (keyed by `MM-DD`):
```json
{
  "01-01": {
    "date_key": "01-01",
    "month": "January",
    "day": 1,
    "title": "CONTROL AND CHOICE",
    "quote": "\u201cThe chief task in life...\u201d",
    "attribution": "EPICTETUS, DISCOURSES, 2.5.4\u20135",
    "body": "The single most important practice..."
  }
}
```

**Flutter architecture (clean layers):**
- `lib/models/` — data models
- `lib/services/` — entry lookup + AI API calls
- `lib/screens/` — full-page UI
- `lib/widgets/` — reusable display components

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `docs/The_Daily_Stoic.pdf` | Source book — input to extraction script (run once) |
| `tools/extract_entries.py` | Python script to generate `entries.json` from PDF |
| `assets/data/entries.json` | Bundled data file — 366 entries keyed by `MM-DD` |
| `lib/main.dart` | App entry point, first-run detection |
| `lib/models/entry.dart` | Entry data model |
| `lib/services/entry_service.dart` | Load JSON asset, lookup by date |
| `lib/services/ai_service.dart` | OpenAI + Anthropic API calls |
| `lib/screens/home_screen.dart` | Main screen: date picker + entry display |
| `lib/screens/onboarding_screen.dart` | First-run: provider select + API key entry |
| `lib/widgets/quote_widget.dart` | Italic block-quote display widget |
| `lib/widgets/entry_display.dart` | Full entry layout (quote + passage + summary) |
| `pubspec.yaml` | Flutter project config + dependencies |
| `macos/Runner/DebugProfile.entitlements` | Add Keychain entitlement for flutter_secure_storage |
| `macos/Runner/Release.entitlements` | Add Keychain entitlement for flutter_secure_storage |

### Technical Decisions

- **Framework**: Flutter 3.x (Dart) — single codebase for macOS, Windows, iOS, Android
- **PDF Extraction**: `tools/extract_entries.py` using `pdfplumber`. Run once by developer. Outputs `assets/data/entries.json`.
- **Data storage**: JSON bundled in Flutter assets. 366 entries ~150KB — no database needed.
- **API key storage**: `flutter_secure_storage` — uses macOS Keychain, Windows Credential Manager, iOS Keychain, Android Keystore. Requires entitlement entries in `macos/Runner/*.entitlements`.
- **AI providers**: Three options — Ollama (local, desktop only), OpenAI (`gpt-4o-mini`), Anthropic (`claude-haiku-4-5-20251001`). All optional. Stored securely. Changeable via settings icon on home screen.
- **Ollama**: Free, no account needed. Runs locally at `http://localhost:11434`. Uses OpenAI-compatible API (`/v1/chat/completions`). Only shown as an option on macOS and Windows (not iOS/Android — mobile cannot run local servers). Suggested model: `llama3.2`. No API key needed — just provider set to `ollama`.
- **AI optional**: If no provider configured, `EntryDisplay` shows a muted "Set up AI summaries in Settings →" prompt in the summary section. The rest of the entry displays normally.
- **HTTP**: `http` Dart package for all AI API calls (REST)
- **Date handling**: `DateTime.now()` as default. Flutter `showDatePicker` for navigation. Leap year (Feb 29) handled — entry exists in data. Date formatted as `MM-dd` for JSON key lookup.
- **Onboarding**: On app start, check `flutter_secure_storage` for `onboarding_complete` flag. If not set → show `OnboardingScreen` (skippable). If set → show `HomeScreen` directly. Onboarding is marked complete whether user configures AI or skips.
- **Typography**: `google_fonts` with Lora (serif) for passage text. Sans-serif system font for UI chrome. Minimal color palette: near-black background, off-white text, single muted accent.
- **AI summary prompt**: `"In one sentence, summarize the following Stoic passage for a personal diary entry: {body}"`. Strip to single sentence in response.

---

## Implementation Plan

### Tasks

Tasks are ordered by dependency — lowest level first.

#### Phase 1: Data Extraction (Pre-build, run once)

- [x] **Task 1: Create PDF extraction script**
  - File: `tools/extract_entries.py`
  - Action: Create Python script that:
    1. Opens `docs/The_Daily_Stoic.pdf` using `pdfplumber`
    2. Iterates all 407 pages; detects entry pages via regex `^(January|February|...) \d+(st|nd|rd|th)`
    3. Parses each entry using the state machine below:
       - State `pre_quote`: skip until line starts with `\u201c`
       - State `in_quote`: accumulate lines; transition to `post_quote` when line contains `\u201d`, OR transition to `in_body` immediately if line starts with `\u2014`
       - State `post_quote`: first non-empty line = attribution (strip leading `\u2014` if present); transition to `in_body`
       - State `in_body`: accumulate remaining lines as body
    4. Outputs `assets/data/entries.json` — a single JSON object keyed by `MM-DD` (zero-padded month and day)
    5. Prints summary: `Extracted N entries. Problems: M`
  - Notes: Requires `pdfplumber` (`pip3 install pdfplumber`). Run from project root: `python3 tools/extract_entries.py`. All 366 entries should parse with 0 problems.

#### Phase 2: Flutter Project Setup

- [x] **Task 2: Initialize Flutter project**
  - File: project root
  - Action: Run `flutter create --org com.yourname daily_stoic_reader --platforms=macos,windows,ios,android .` (or a new subdirectory). Confirm `pubspec.yaml` is created.
  - Notes: If running in existing directory, use a subdirectory like `app/`.

- [x] **Task 3: Configure pubspec.yaml**
  - File: `pubspec.yaml`
  - Action: Add dependencies and asset declaration:
    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      flutter_secure_storage: ^9.2.2
      http: ^1.2.1
      intl: ^0.19.0
      google_fonts: ^6.2.1

    flutter:
      assets:
        - assets/data/entries.json
    ```
  - Notes: Run `flutter pub get` after editing.

- [x] **Task 4: Add macOS Keychain entitlements**
  - Files: `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`
  - Action: Add to both files inside the `<dict>` element:
    ```xml
    <key>keychain-access-groups</key>
    <array>
      <string>$(AppIdentifierPrefix)com.yourname.dailyStoicReader</string>
    </array>
    ```
  - Notes: Required for `flutter_secure_storage` to work on macOS. Without this, secure reads/writes silently fail.

#### Phase 3: Data Layer

- [x] **Task 5: Create Entry model**
  - File: `lib/models/entry.dart`
  - Action: Create `Entry` class with fields: `dateKey` (String), `month` (String), `day` (int), `title` (String), `quote` (String), `attribution` (String), `body` (String). Add `Entry.fromJson(Map<String, dynamic> json)` factory constructor.

- [x] **Task 6: Create EntryService**
  - File: `lib/services/entry_service.dart`
  - Action: Create `EntryService` class with:
    - `static Map<String, Entry>? _cache` (lazy-loaded)
    - `static Future<Entry?> getEntry(DateTime date)` — formats date as `MM-dd` using `intl` (`DateFormat('MM-dd').format(date)`), loads JSON from assets if not cached, returns matching `Entry` or null
    - `static Future<Map<String, Entry>> _loadAll()` — loads `assets/data/entries.json` via `rootBundle.loadString`, decodes JSON, maps to `Entry` objects
  - Notes: Use `flutter/services.dart` for `rootBundle`. Cache on first load.

#### Phase 4: AI Service

- [x] **Task 7: Create AiService**
  - File: `lib/services/ai_service.dart`
  - Action: Create `AiService` class with:
    - `static Future<String> generateSummary(String body, String provider, String apiKey)` method
    - Prompt (same for all providers): `"In one sentence, summarize the following Stoic passage for a personal diary entry:\n\n{body}"`
    - For `provider == 'openai'`: POST to `https://api.openai.com/v1/chat/completions`. Headers: `Authorization: Bearer {apiKey}`, `Content-Type: application/json`. Body: `{"model": "gpt-4o-mini", "messages": [{"role": "user", "content": prompt}]}`. Extract `choices[0].message.content`.
    - For `provider == 'anthropic'`: POST to `https://api.anthropic.com/v1/messages`. Headers: `x-api-key: {apiKey}`, `anthropic-version: 2023-06-01`, `Content-Type: application/json`. Body: `{"model": "claude-haiku-4-5-20251001", "max_tokens": 150, "messages": [{"role": "user", "content": prompt}]}`. Extract `content[0].text`.
    - For `provider == 'ollama'`: POST to `http://localhost:11434/v1/chat/completions`. No auth header. Body: `{"model": "llama3.2", "messages": [{"role": "user", "content": prompt}]}`. Extract `choices[0].message.content` (same OpenAI-compatible format).
    - Return the single-sentence summary string. Throw descriptive exception on non-200 response or connection refused (Ollama not running).
  - Notes: Use `http` package. `apiKey` is ignored for Ollama — pass empty string.

#### Phase 5: Onboarding Screen

- [x] **Task 8: Create OnboardingScreen**
  - File: `lib/screens/onboarding_screen.dart`
  - Action: Create `OnboardingScreen` StatefulWidget with:
    - Sparse layout: app name at top, brief subtitle ("Your daily Stoic companion"), then AI setup section
    - AI setup section:
      - Heading: "AI Diary Summaries (optional)"
      - Brief explanation: "Generate a one-line summary of each passage for your diary. You can set this up later."
      - Provider selector — show 3 options on macOS/Windows, 2 on iOS/Android. Use `Platform.isMacOS || Platform.isWindows` (from `dart:io`) to conditionally show Ollama:
        - "Ollama — free, runs on your computer" (desktop only)
        - "OpenAI"
        - "Anthropic Claude"
      - If Ollama selected: show instruction text "Make sure Ollama is running with `ollama serve`" — no API key field
      - If OpenAI or Anthropic selected: show API key text field (obscured, with show/hide toggle)
      - If no provider selected (default): no key field shown
    - Two buttons at bottom: "Set Up AI" (enabled only if provider selected + key entered when required) and "Skip for now" (always enabled)
    - On "Set Up AI": save `provider` and `api_key` (empty string for Ollama) to `flutter_secure_storage`, save `onboarding_complete: 'true'`, navigate to `HomeScreen`
    - On "Skip for now": save `onboarding_complete: 'true'` only (no provider/key), navigate to `HomeScreen`
    - Both navigation calls replace the route stack (no back navigation to onboarding)
    - Visual style: dark background (#1A1A1A), off-white text (#F0EDE8), minimal borders, Lora font for title

#### Phase 6: Home Screen & Widgets

- [x] **Task 9: Create QuoteWidget**
  - File: `lib/widgets/quote_widget.dart`
  - Action: Create `QuoteWidget` StatelessWidget accepting `quote` (String) and `attribution` (String). Renders quote in italic Lora serif, left-border accent line (3px, muted gold or grey), attribution in small caps below. Full width, comfortable vertical padding.

- [x] **Task 10: Create EntryDisplay widget**
  - File: `lib/widgets/entry_display.dart`
  - Action: Create `EntryDisplay` StatelessWidget accepting `entry` (Entry) and `summary` (String?, nullable). Layout top-to-bottom:
    1. Entry title — small, letter-spaced, all-caps, muted color
    2. `QuoteWidget` — the Stoic quote + attribution
    3. Divider (thin, muted)
    4. Body text — Lora serif, comfortable line height, off-white
    5. Divider (thin, muted)
    6. Summary section — label "Diary Summary" in small caps, then:
       - If `summaryState == loading`: show subtle loading indicator
       - If `summaryState == loaded`: show summary text in italic
       - If `summaryState == error`: show error text in muted red (e.g., "Could not generate summary — check Settings")
       - If `summaryState == notConfigured`: show muted tap-target "Set up AI summaries in Settings →"
  - Notes: Wrap in `SingleChildScrollView` to handle long passages. `summaryState` is an enum: `loading`, `loaded`, `error`, `notConfigured`.

- [x] **Task 11: Create HomeScreen**
  - File: `lib/screens/home_screen.dart`
  - Action: Create `HomeScreen` StatefulWidget with:
    - State: `_selectedDate` (DateTime, init to `DateTime.now()`), `_entry` (Entry?), `_summary` (String?), `_isLoadingSummary` (bool)
    - `initState`: call `_loadEntry(_selectedDate)`
    - `_loadEntry(DateTime date)`: fetch entry from `EntryService`, set `_entry`, then trigger `_loadSummary()`
    - `_loadSummary()`: read `provider` from `flutter_secure_storage`. If null/empty → set `summaryState = notConfigured`, return. Otherwise call `AiService.generateSummary()` → set `summaryState = loaded` with result, or `summaryState = error` on exception.
    - UI layout:
      - AppBar: app name left-aligned, settings gear icon right (navigates to settings)
      - Date selector row: left arrow, tappable date label (opens `showDatePicker` defaulting to `_selectedDate`), right arrow — for prev/next day navigation
      - Body: `EntryDisplay` widget (or loading/error state if entry not found)
    - Date picker: `showDatePicker` with `initialDate: _selectedDate`, `firstDate: DateTime(2000, 1, 1)`, `lastDate: DateTime(2000, 12, 31)` — year is irrelevant, only month+day matters for lookup

- [x] **Task 12: Create SettingsScreen**
  - File: `lib/screens/settings_screen.dart`
  - Action: Create `SettingsScreen` StatefulWidget with:
    - Provider selector (radio buttons): "None (disable summaries)", "Ollama" (desktop only — hide on iOS/Android), "OpenAI", "Anthropic Claude"
    - API key field (obscured, pre-filled with `••••••••` if key already stored): shown only when OpenAI or Anthropic selected; hidden for Ollama and None
    - Ollama hint text when selected: "Ensure Ollama is running: `ollama serve`"
    - "Save" button: writes updated `provider` and `api_key` to `flutter_secure_storage`. If "None" selected, delete both keys.
    - Simple back navigation

#### Phase 7: App Entry Point & Routing

- [x] **Task 13: Configure main.dart**
  - File: `lib/main.dart`
  - Action: In `main()`, before `runApp()`, read `onboarding_complete` flag from `flutter_secure_storage`. If null → set initial route to `OnboardingScreen`. If `'true'` → set initial route to `HomeScreen`. Apply dark theme: background `#1A1A1A`, surface `#242424`, primary text `#F0EDE8`, use Lora as default text font via `google_fonts`.
  - Notes: `flutter_secure_storage` requires `WidgetsFlutterBinding.ensureInitialized()` before first use in `main()`. Routing is now based on `onboarding_complete`, not `api_key` — AI is optional.

#### Phase 8: Build & Package

- [x] **Task 14: Build macOS app**
  - Action: Run `flutter build macos --release`. Output at `build/macos/Build/Products/Release/daily_stoic_reader.app`. Copy/distribute this `.app` bundle.

- [x] **Task 15: Build Windows app**
  - Action: Run `flutter build windows --release` (on a Windows machine or CI). Output at `build/windows/x64/runner/Release/`.

- [x] **Task 16: Build iOS app**
  - Action: Run `flutter build ios --release` then archive via Xcode for App Store or TestFlight distribution. Alternatively: `flutter build ipa` for ad-hoc distribution.

- [x] **Task 17: Build Android app**
  - Action: Run `flutter build apk --release` for sideloading, or `flutter build appbundle` for Play Store.

---

### Acceptance Criteria

- [x] **AC 1 — Today's entry loads on launch without AI:** Given the app has been opened before (onboarding complete, no AI configured), when the app is opened, then today's date is pre-selected and the full Stoic entry (title, quote, attribution, body) is displayed. The summary section shows "Set up AI summaries in Settings →".

- [x] **AC 2 — Quote is formatted correctly:** Given any entry is displayed, when the user views the passage, then the Stoic quote appears in italic serif text with a vertical accent border, and the attribution (author + source) appears below the quote in a smaller weight.

- [x] **AC 3 — AI diary summary is generated (cloud):** Given a valid OpenAI or Anthropic API key is stored, when an entry is displayed, then a one-line AI-generated diary summary appears below the body text under a "Diary Summary" label within 5 seconds.

- [x] **AC 4 — AI diary summary is generated (Ollama):** Given the user is on macOS or Windows, has Ollama installed and running (`ollama serve`), and has selected Ollama as their provider, when an entry is displayed, then a one-line diary summary is generated locally and displayed without any API key or internet connection.

- [x] **AC 5 — Ollama option not shown on mobile:** Given the app is running on iOS or Android, when the user opens Settings, then the "Ollama" provider option is not shown — only OpenAI, Anthropic, and None are available.

- [x] **AC 6 — Date navigation works:** Given the home screen is displayed, when the user taps the left or right arrow, then the date changes by one day and the new entry loads. When the user taps the date label, then `showDatePicker` opens pre-filled with the current date, and selecting a date loads that entry.

- [x] **AC 7 — Onboarding is skippable:** Given the app is launched for the first time, when the user taps "Skip for now", then the home screen loads directly with no AI configured. The app is fully usable — entry content displays normally.

- [x] **AC 8 — Onboarding not shown again after skip:** Given the user skipped onboarding, when the app is closed and reopened, then the home screen loads directly (onboarding is not shown again).

- [x] **AC 9 — Settings allows provider setup and change:** Given the user is on the home screen, when the user taps the settings icon and selects a provider and saves, then subsequent entry loads generate AI summaries using the new configuration.

- [x] **AC 10 — Feb 29 entry is accessible:** Given the user navigates to February 29th, then the entry "YOU CAN'T ALWAYS (BE) GET(TING) WHAT YOU WANT" is displayed (not a "not found" error).

- [x] **AC 11 — Invalid API key shows error gracefully:** Given the user has entered an invalid API key, when an entry is loaded and the AI summary is requested, then an error message is shown in place of the summary and the rest of the entry still displays normally.

- [x] **AC 12 — Stoic aesthetic on all platforms:** Given the app is running on macOS, Windows, iOS, or Android, when the home screen is displayed, then the UI shows a dark background, off-white serif text, and no unnecessary chrome or decorative elements.

---

## Additional Context

### Dependencies

**Python (extraction script — run once):**
- `pdfplumber >= 0.11` — PDF text extraction (`pip3 install pdfplumber`)
- Python 3.9+ (pre-installed on macOS)

**Flutter (app):**
- `flutter_secure_storage: ^9.2.2` — platform-native secure key storage
- `http: ^1.2.1` — HTTP client for AI API calls
- `intl: ^0.19.0` — date formatting (`MM-dd` key generation)
- `google_fonts: ^6.2.1` — Lora serif font

**External Services (all optional):**
- Ollama (local) — `http://localhost:11434/v1/chat/completions` — free, no account, desktop only. User installs from https://ollama.com and runs `ollama pull llama3.2`
- OpenAI API (user-provided key) — `https://api.openai.com/v1/chat/completions`
- Anthropic API (user-provided key) — `https://api.anthropic.com/v1/messages`

**Platform requirements:**
- macOS: Xcode 14+, macOS 12+
- Windows: Visual Studio 2022 with C++ workload
- iOS: Xcode 14+, Apple Developer account for device/distribution builds
- Android: Android Studio, Android SDK 21+

### Testing Strategy

**Unit Tests (`test/`):**
- `entry_service_test.dart`: Test `getEntry()` for Jan 1, Feb 29, Dec 31, and an invalid date (e.g., `13-01`). Verify correct `Entry` fields are returned.
- `ai_service_test.dart`: Mock HTTP responses; test OpenAI path returns `choices[0].message.content`, Anthropic path returns `content[0].text`, Ollama path returns `choices[0].message.content`, non-200 response throws exception, connection refused (Ollama not running) throws descriptive exception.

**Widget Tests (`test/`):**
- `quote_widget_test.dart`: Render `QuoteWidget` with sample data; verify italic text and attribution are present.
- `entry_display_test.dart`: Render `EntryDisplay` with null summary (verify loading indicator shown) and with summary string (verify summary text shown).
- `onboarding_screen_test.dart`: Verify "Skip for now" is always enabled. Verify "Set Up AI" is disabled with no provider selected. Verify "Set Up AI" is enabled when Ollama selected (no key needed). Verify "Set Up AI" is disabled when OpenAI/Anthropic selected but key is empty; enabled when key is non-empty. Verify Ollama option is absent when platform is iOS/Android.

**Manual Testing Checklist:**
- [ ] Run extraction script, verify `assets/data/entries.json` has 366 entries, spot-check Jan 1, July 29, Sep 28, Feb 29
- [ ] Launch app fresh → onboarding shown
- [ ] Tap "Skip for now" → home screen loads, summary section shows "Set up AI summaries in Settings →"
- [ ] Close and reopen app → home screen shown directly (no onboarding again)
- [ ] Configure OpenAI in Settings → AI summary generated on next entry load
- [ ] Switch provider to Anthropic → AI summary generated via Anthropic
- [ ] Switch provider to Ollama (macOS only) with Ollama running → summary generated locally, no internet
- [ ] Switch provider to Ollama with Ollama NOT running → error shown in summary section
- [ ] Set provider to None in Settings → summary section reverts to "Set up AI summaries" prompt
- [ ] Enter invalid API key → error message shown, entry body still displays
- [ ] Navigate to Feb 29 → correct entry displayed
- [ ] Test on macOS and iOS (at minimum)

### Notes

**High-Risk Items:**
1. **macOS Keychain entitlement**: Forgetting the entitlement in `macos/Runner/*.entitlements` causes `flutter_secure_storage` to silently fail (reads return null, writes are no-ops). This will make the app show onboarding every launch. Must be added before first macOS build test.
2. **AI latency**: Summary generation adds 1–3 seconds of latency (even Ollama). Show loading indicator immediately when entry loads; never block entry display while waiting for AI.
3. **Date year mismatch**: The JSON keys are `MM-DD` only (no year). When using `showDatePicker`, the year selected by the user is irrelevant — only month+day is used for lookup. Make this clear in code comments.
4. **Ollama connection refused**: If the user selected Ollama but hasn't started it, the `http` package throws a `SocketException`. Catch this specifically and show "Ollama doesn't appear to be running. Start it with `ollama serve`." rather than a generic error.

**Known Limitations:**
- Cloud AI (OpenAI/Anthropic) requires internet. Ollama works offline but requires Ollama to be installed and running on the same machine.
- Ollama is not available on iOS/Android — mobile users who want summaries must use a cloud provider.
- The extraction script must be re-run by the developer if the PDF changes. The `entries.json` is a static asset — it does not update automatically.
- Windows build requires a Windows machine (cannot cross-compile from macOS).

**Future Considerations (out of scope):**
- Copy-to-clipboard button for the diary summary
- Favourite/bookmark entries
- Daily reminder notification
- On-device AI for iOS/Android summary generation (Apple Intelligence API, when publicly available)
- Share entry as image

---

## Review Notes

- Adversarial review completed 2026-03-12
- Findings: 11 total, 10 fixed, 1 skipped (noise: F9 — raw API error body acceptable for personal app)
- Resolution approach: auto-fix
- Key fixes: race condition on rapid date navigation (generation counter), mounted checks before navigation, TimeoutException handling, deprecated ColorScheme fields, dead code removal, test compilation errors
