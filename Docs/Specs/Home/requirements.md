# Requirements — Home

Version: 1.10
Last updated: 2026-10-07
Status: in-progress — full UI + local logic with mock data; no dashboard API
yet (all content is stubbed in the UseCase)
Feature folder: `InnerLamp/Presentation/Scenes/Home/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Home feature.
> It documents the shipped behavior, including the fact that all content is
> currently mock data in `ILHomeUseCaseImpl`.

## User Story

As a signed-in user, I want a home screen that greets me by name and surfaces
the daily quote, my practice progress, the bead counter, and shortcuts to the
app's main sections, so that I can get oriented and start a session quickly.

## Acceptance Criteria (EARS notation)

- WHEN the Home screen loads, THE SYSTEM SHALL greet the user by their
  registered display name (falling back to a guest label when no name is
  stored) and show the current solar + lunar date.
- WHEN the Home screen loads, THE SYSTEM SHALL render the sections in this
  order: weekly calendar strip, large lunar hero card (with daily quote), photo
  gallery, temple carousel, statistics (session progress + streak), bead
  counter, bell card, suggested-session list, and articles list — all from
  mock data.
- WHEN the Home screen loads, THE SYSTEM SHALL fill the "Bài viết Phật pháp hay"
  section with the top articles from `GET /v1/articles/top` (server order,
  currently 5) and SHALL show nothing in that section while the request is in
  flight or if it fails with no data.
- WHEN the user taps a navigation target, THE SYSTEM SHALL open the
  corresponding child screen:
  - "Toàn màn hình" link or anywhere on the bead card → Mala (Niệm Phật);
  - "Lịch âm" or the lunar hero card → LunarCalendar;
  - "Sổ giỗ" (link beside "Lịch âm" in the week-strip header) → Memorial;
  - "Xem tất cả" / a photo tile → Photos;
  - the bell card → Bell;
  - "Tất cả" under events → Events;
  - an article → Article (by id);
  - a temple in the carousel → Temple (by id);
  - a meditation row in suggested sessions → MeditationSetup.
- WHEN the user taps a "sutra" or "offering" suggested-session row, THE SYSTEM
  SHALL NOT navigate (those destinations are not built yet).

## Out of scope (this feature boundary, not backend work)

- The content of each child screen — Mala, LunarCalendar, Memorial, Photos, Bell, Events,
  Article, Temple, MeditationSetup are each owned by their own feature (and
  spec).
- The Reader (Đọc kinh) and Offering (Cúng dường) screens — the `.sutra` /
  `.offering` suggested-session rows currently do nothing.

## Pending (not yet implemented — see `tasks.md`)

- WHEN Home loads, THE SYSTEM SHALL request the featured gallery photos
  (`GET /v1/gallery/top`, 10 photos) and show the first 3 as the "Ảnh chùa đẹp"
  tiles with the "+N ảnh" overlay for the rest; IF the request fails, THEN THE
  SYSTEM SHALL keep the placeholder tiles and hide the overlay without failing
  Home. (Contract: `Docs/Specs/Photos/design.md` → "API contract".)

- A real dashboard/content API. All content (daily quote, session/streak
  statistics, suggested sessions, photos, temples, articles, events) is mock
  data inside `ILHomeUseCaseImpl`, marked with TODO comments to replace with
  `NetworkService` calls once a contract exists. (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the dashboard/content API contract(s) — there is no
  > home-dashboard endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks
  > `tasks.md` Phase 3.

- A real session/current-user service. The greeting name has no source
  (always "khách"): it used to read a temporary Keychain item holding the
  plaintext sign-up password, which was removed ({D}, TD-Home-002).

- The bead count is memory-only: it is not persisted locally and is not synced
  with the full-screen Mala screen.

## Open questions (resolved during implementation)

- ~~How is the "today" lunar date computed?~~ → Via `ILLunarCalendar.solarToLunar`
  (a real conversion, not a hardcoded string). The weekly strip and lunar hero
  card both use it. Resolved during implementation (see
  `Presentation/Scenes/Home/README.md`).
