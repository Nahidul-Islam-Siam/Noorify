# Noorify Future Updates

This document tracks planned improvements for Noorify.

## Product Goals

- Help users build a consistent daily Islamic routine.
- Improve Quran learning, memorization, and reflection.
- Keep core features reliable in low-network conditions.

## Priority Roadmap

## 1) Hifz Mode (Memorization Mode) - Next Major Feature

Why:
- High-value recurring use case for Quran users.
- Works well with existing ayah-level playback and tafsir support.

MVP scope:
- Select ayah range (single ayah or multiple ayahs).
- Repeat each ayah N times (3 / 5 / 10).
- Pause between repeats (configurable short delay).
- "Hide Bangla text" practice mode for self-testing.
- Mark memorization progress per surah/ayah.

Technical notes:
- Reuse `SurahDetailScreen` playback pipeline.
- Persist progress with cache/local storage service.
- Keep logic compatible with both timed and fallback single-ayah audio.

Success metric:
- Users complete at least one memorization session daily.

## 2) Advanced Single-Ayah Player Controls

Scope:
- A-B repeat for one ayah.
- Auto-next mode (play ayah 1 -> 2 -> 3).
- Playback speed controls (0.75x / 1.0x / 1.25x).
- Optional "continue from last ayah" setting.

## 3) Quran Bookmarks and Collections

Scope:
- Save ayah bookmarks with personal notes.
- Group bookmarks into named collections (e.g., "Morning", "Dua Ayahs").
- Quick access from home screen.

## 4) Better Offline Quran Experience

Scope:
- Bulk download manager (audio + tafsir by surah).
- Download status page with progress and file size.
- "Offline ready" badge for cached surahs.

## 5) Daily Reflection Experience

Scope:
- Ayah of the day widget on home screen.
- Optional short tafsir summary card.
- Streak and reminder nudges.

## Implementation Order

1. Hifz Mode MVP
2. Advanced single-ayah controls
3. Bookmarks and collections
4. Offline manager
5. Daily reflection

## Release Checklist Template

Use this checklist for each feature:

- Product behavior defined
- UX states covered (loading/empty/error/offline)
- Local cache behavior validated
- `flutter analyze` passes
- `flutter test` passes
- Docs updated (`README.md` + this file)
