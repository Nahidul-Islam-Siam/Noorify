# Noorify Language Audit (Screen-by-Screen)

Date: 2026-03-14
Scope: `lib/features/**/screens/*.dart`
Goal: Bangla/English consistency lock before release.

## Status Legend
- `P0 - Must Fix`: Broken/garbled text risk (mojibake) or language rendering can fail for users.
- `P1 - Should Fix`: Works, but mixed language or English-only copy in user-facing flow.
- `P2 - Nice to Have`: Internal/admin/legal polish.

## Summary
- Total screens audited: **22**
- `P0` screens: **4**
- `P1` screens: **16**
- `P2` screens: **2**

---

## Screen-by-Screen Audit

| Screen | Path | Current State | Priority | Action |
|---|---|---|---|---|
| Splash | `lib/features/splash/screens/ramadan_splash_screen.dart` | Minimal text only; safe. | P1 | Optional: localize fallback "Noorify" caption if needed. |
| Sign In | `lib/features/auth/screens/signin_screen.dart` | Guest setup + many labels are English-only; language selector exists. | P1 | Add `_text()`/localized map for all user-visible strings. |
| Sign Up | `lib/features/auth/screens/signup_screen.dart` | Same as Sign In (English-heavy UI text). | P1 | Mirror Sign In localization strategy. |
| Home (Daily Activity) | `lib/features/home/screens/daily_activity_screen.dart` + `widgets/daily_activity_view_mixin.dart` | Bangla/English toggle exists; mojibake repair fallback exists. | P1 | Replace repaired mojibake source strings with clean Bangla literals (`\u09..`) to remove fallback dependency. |
| Discover | `lib/features/discover/screens/discover_screen.dart` | Uses `t()` + repair fallback; mostly localized. | P1 | Replace remaining mojibake Bangla literals with clean Unicode Bangla strings. |
| Quran List | `lib/features/quran/screens/quran_screen.dart` | Mixed language experience; several labels are fixed English. | P1 | Localize static UI labels, filters, errors, snackbars. |
| Surah Detail | `lib/features/quran/screens/surah_detail_screen.dart` | Strong bilingual controls + repair helper in place. | P1 | Replace legacy repaired Bangla text with clean literals to stabilize rendering. |
| Quran Bookmarks | `lib/features/quran/screens/ quran_bookmarks_screen.dart` | English-only screen chrome (title/subtitle). | P1 | Add language-aware labels and ayah meta text. |
| Prayer Times | `lib/features/prayer_time/screens/prayer_times_screen.dart` | Good bilingual coverage and helper usage. | P1 | Localize fallback location/loading phrases and any remaining direct English constants. |
| Islamic Calendar | `lib/features/islamic_calendar/screens/islamic_calendar_screen.dart` | Heavy mojibake risk in month/day/event labels. | **P0** | Replace all Bangla literals with valid Unicode Bangla; remove corrupted strings. |
| Qibla Compass | `lib/features/qibla/screens/qibla_compass_screen.dart` | Bangla labels currently rely on corrupted text values. | **P0** | Convert Bangla copy to clean Unicode literals and keep `_text()` only for switching. |
| Find Mosque | `lib/features/mosque/screens/find_mosque_screen.dart` | Primarily English user text; no language toggle handling. | P1 | Localize notices/errors/button labels/location states. |
| Set Location | `lib/features/mosque/screens/set_location_screen.dart` | English-only labels/messages. | P1 | Localize title, search hint, permission/location snackbars, button text. |
| Asmaul Husna | `lib/features/asmaul_husna/screens/asma_screen.dart` | Data supports Bangla fields, but screen labels are English-only. | P1 | Localize header/search/error/audio placeholder text. |
| Hadith | `lib/features/hadith/screens/hadith_screen.dart` | Bangla strings include mojibake-like values. | **P0** | Replace all corrupted Bangla literals with valid Unicode Bangla, then verify search/category labels. |
| Dua | `lib/features/dua/screens/dua_screen.dart` | Mostly English UI shell; Bangla content exists in data. | P1 | Localize categories, headers, helper labels, references. |
| Tasbih | `lib/features/tasbih/screens/tasbih_screen.dart` | English-only control text and status messages. | P1 | Add bilingual labels for preset, counters, alerts, and snackbar copy. |
| Profile Edit | `lib/features/profile/screens/edit_profile_screen.dart` | English-only labels/errors/buttons. | P1 | Localize form labels, validation messages, button text. |
| Profile Preferences | `lib/features/profile/screens/profile_preferences_screen.dart` | Highest mojibake density; mixed source quality. | **P0** | Full Bangla string cleanup + unified localization helper + quick regression pass on all toggles. |
| Admin Panel | `lib/features/admin/screens/admin_panel_screen.dart` | Internal/admin UI in English only. | P2 | Optional bilingual admin copy (not user-critical). |
| About | `lib/features/legal/screens/about_screen.dart` | English-only + old brand mention (`ilMify`). | P2 | Update brand to `Noorify`; optional Bangla version. |
| Privacy Policy | `lib/features/legal/screens/privacy_policy_screen.dart` | English-only legal copy. | P1 | Add Bangla policy version or language switch. |

---

## P0 Release Blockers (Fix First)
1. `lib/features/profile/screens/profile_preferences_screen.dart`
2. `lib/features/islamic_calendar/screens/islamic_calendar_screen.dart`
3. `lib/features/qibla/screens/qibla_compass_screen.dart`
4. `lib/features/hadith/screens/hadith_screen.dart`

Reason: these can show visibly broken Bangla text on device.

## Recommended Fix Order
1. **Pass 1 (P0):** Clean corrupted Bangla literals and remove mojibake source strings.
2. **Pass 2 (P1 core):** Auth + Home + Discover + Prayer + Quran + Mosque + Profile Edit.
3. **Pass 3 (P1/P2 polish):** Asma, Dua, Tasbih, Legal, Admin.

## Implementation Standard (Lock Rule)
- Do not keep Bangla as mojibake text in source.
- Store Bangla strings either:
  - as proper UTF-8 Bangla text, or
  - as Unicode escapes (`\u09..`) where editor encoding is unstable.
- Prefer one helper per screen (`_text(en, bn)`) or central i18n map.
- No direct user-facing hardcoded English in Bangla mode.

## QA Checklist Before Release
- Bangla mode ON: all routes show readable Bangla (no `Ã`, `à§`, `à¦`).
- Bangla mode OFF: all screens remain readable English.
- Toggle language from Profile and re-open each main tab.
- Check snackbars/dialogs/empty states/errors in both languages.
- Check calendar and profile screens on low-end Android (where issues were observed).
