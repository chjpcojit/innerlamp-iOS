# Requirements — Article

Version: 1.3
Last updated: 2026-10-06
Status: in-progress — full reading screen reading the articles API, hero image loaded from `image_url` (v1.3);
in-memory save; Share destination not built
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
- WHEN the Article screen loads, THE SYSTEM SHALL fetch the article from the
  server (`GET /v1/articles/{id}`) and, WHILE the request is in flight, SHALL
  NOT show stale or mock article content.
- IF the article cannot be loaded (unknown id, no connection, server error),
  THEN THE SYSTEM SHALL show a localized error message instead of article
  content.
- WHEN the article has a source, THE SYSTEM SHALL show the source name and a
  link to the original article (`source_name` + `source_url`), because the
  articles are summaries of press originals.
- WHEN the article has a cover image (`image_url`), THE SYSTEM SHALL load it
  into the hero and keep the placeholder (warm tint + category label) visible
  until it has loaded.
- IF the cover image cannot be loaded (HTTP error, network failure,
  or undecodable data), THEN THE SYSTEM SHALL keep showing the placeholder hero
  and no error message.
- WHEN the article has no cover image or no published date (both optional),
  THE SYSTEM SHALL fall back to the placeholder hero and omit the date.
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

- Hero image hosting — `image_url` is now set for all 60 articles, but the
  URLs are hotlinks to the original publishers (not hosted by the backend), so
  they may break or be blocked later (BE probed 60/60 → 200 with an iOS-style
  User-Agent on 2026-10-06; an earlier "6/60 return 403" report was wrong — it
  only affected a spoofed `Mozilla/5.0` User-Agent). A durable fix would be
  BE-hosted or proxied images.

- "Đọc tiếp" (read next) source — the API has no related-articles field, so
  the list is derived client-side (see `design.md`).

  > ⚠️ Not confirmed: whether the backend will add a related-articles field or
  > a `limit` on `/v1/articles/top` — the client-side derivation is a
  > decision, not a backend fact. Does not block Phase 3.

- Save persistence — `toggleSave` only mutates the in-memory `savedArticleIDs`
  set; there is no `UserDefaultsService`/Core Data write.

- The Share destination — `.share` is a TODO in the coordinator.

- Visual QA (scroll layout, hero image, dark mode) not verified on device.

## Open questions (resolved during implementation)

- ~~What is the articles API contract?~~ → Confirmed by [BE-Developer]
  2026-09-30 and verified against the real dev server (30 articles). Three
  public endpoints (`/v1/articles/top`, `/v1/articles?page=N`,
  `/v1/articles/{id}`); full shape in `design.md`. Resolved 2026-09-30.

- ~~Is the author's avatar initials derivable from the name?~~ → No.
  `authorInitials` is editorial data (e.g. "Ban biên tập InnerLamp" → "IL"), not
  computable from the author string. Resolved during implementation (see
  `Domain/Entities/ILArticleEntity.swift`).
