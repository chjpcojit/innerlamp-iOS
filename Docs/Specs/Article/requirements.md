# Requirements — Article

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full reading screen with static catalog + in-memory save;
no articles API, and the Share destination is not built
Feature folder: `InnerLamp/Presentation/Scenes/Article/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Article
> feature. It documents the shipped behavior, including the static mock
> catalog, the in-memory save toggle, and the unimplemented Share destination.

## User Story

As a practitioner, I want to read a full Dharma article (title, author, body,
quote) and save it or read the next suggested article, so that I can consume
curated Buddhist content.

## Acceptance Criteria (EARS notation)

- WHEN the Article screen loads for a given article id, THE SYSTEM SHALL show
  that article's hero image, category + read-time header, title, author (with
  initials), date, body paragraphs, and quote with its source.
- WHEN the user taps "Lưu bài" (save), THE SYSTEM SHALL toggle the article's
  saved state and update the button label to "Đã lưu" / "Lưu bài" accordingly.
- WHEN the user taps an article in the "Đọc tiếp" (read next) list, THE SYSTEM
  SHALL switch the displayed article in place (scrolling back to the top).
- WHEN the user taps "Chia sẻ" (share), THE SYSTEM SHALL emit a share event.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Article screen
  and return to Home.

## Out of scope (this feature boundary, not backend work)

- The Share screen itself (`.share` reaches a TODO in the coordinator; the
  `share` screen — 3 card styles — is not built).
- A "Bài đã lưu" (saved articles) screen — the save state is currently
  in-memory only.

## Pending (not yet implemented — see `tasks.md`)

- A real articles API. `ILArticleUseCaseImpl` builds a static 5-article catalog
  from `Component.ARTICLES` with a TODO to replace with `NetworkService`.
  (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the articles API contract(s) — no articles endpoint in
  > `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- Real article hero images — the hero renders a warm tint + category label as a
  placeholder.

- Save persistence — `toggleSave` only mutates the in-memory `savedArticleIDs`
  set; there is no `UserDefaultsService`/Core Data write.

- The Share destination — `.share` is a TODO in the coordinator.

- Visual QA (scroll layout, hero image, dark mode) not verified on device.

## Open questions (resolved during implementation)

- ~~Is the author's avatar initials derivable from the name?~~ → No.
  `authorInitials` is editorial data (e.g. "Ban biên tập InnerLamp" → "IL"), not
  computable from the author string. Resolved during implementation (see
  `Domain/Entities/ILArticleEntity.swift`).
