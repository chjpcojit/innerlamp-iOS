# Requirements — Talk

Version: 1.1
Last updated: 2026-11-15
Status: not started — prospective; the backend contract is confirmed (2026-11-15), the iOS API layer and real audio playback are not built
Feature folder: `InnerLamp/Presentation/Scenes/Talk/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner in the Library, I want to open a Dharma talk (Pháp thoại) so
that I can read its title/metadata, play or pause the talk, jump between its
chapters, and be offered a short meditation after listening.

## Acceptance Criteria (EARS notation)

- WHEN the Talk screen loads, THE SYSTEM SHALL show a transparent header over a
  dark hero with the talk's kicker ("PHÁP THOẠI · …"), title, speaker, duration,
  and play count.
- WHEN the user scrolls past 110 px, THE SYSTEM SHALL transition the transparent
  header to an opaque background.
- WHEN the user taps play/pause, THE SYSTEM SHALL control playback and show the
  current time and remaining time.
- WHEN the talk's media type is `audio`, THE SYSTEM SHALL use the API
  `audio_url` exactly as returned — an absolute `http(s)` URL — and SHALL NOT
  prefix its own API base or host.
- WHEN the audio file cannot be loaded, THE SYSTEM SHALL keep the talk's title,
  speaker, description and chapters visible and show a player-unavailable state.
- WHEN the user drags the seek bar, THE SYSTEM SHALL seek within the talk.
- WHEN the user taps the 15s / 30s skip controls, THE SYSTEM SHALL jump forward
  or back by that amount.
- WHEN the screen renders the "Các phần" (chapters) list, THE SYSTEM SHALL show
  each chapter with its start time and title; tapping a chapter SHALL seek to
  that time.
- WHEN the screen renders the follow-up card ("Nghe xong, ngồi thiền 10 phút ·
  Quán niệm ân cha mẹ"), THE SYSTEM SHALL offer it; tapping it SHALL navigate to
  MeditationSetup.
- WHEN the user taps back, THE SYSTEM SHALL return to the Library.

## Out of scope (this feature boundary, not backend work)

- The Library featured Dharma-talk card that navigates here — owned by the
  Library feature (`Docs/Specs/Library/`).
- The full-screen Player (speed / sleep timer) and the Reader — separate
  features (`Docs/Specs/Player/`, `Docs/Specs/Sutra/` for the reading view).
- MeditationSetup — a separate feature reached from the follow-up card.

## Contract (confirmed 2026-11-15)

Source of truth: `innerlamp-be` `docs/product/dharmatalk/product.md` @ v0.4,
`docs/specs/features/dharmatalk/requirements.md` @ v2.4, and
`docs/specs/api/openapi.yaml` @ v3.0.0.

- `GET /v1/dharma-talks/{id}` is public. For `media_type = "audio"` it returns
  `audio_url` as an **absolute** `http(s)` URL, no `Authorization` header or
  cookie needed. It never returns a root-relative path.
- The media route supports `HEAD` (`Content-Length`, `Accept-Ranges: bytes`) and
  byte ranges (`206` with `Content-Range`; `416` when out of range). A native
  player can therefore seek and resume without downloading the whole file.
- `Content-Type` is `audio/mpeg` for the mp3 files; no DRM and no signed URL.
  `Cache-Control: public, max-age=86400`.
- A missing file returns `404` from the audio URL but the detail route still
  returns `200`. The screen keeps its content and shows the unavailable state.
- Production uses HTTPS. A dev server on `http://<lan-ip>:8082` needs the app's
  ATS exception (`NSAllowsLocalNetworking` / a local exception domain); otherwise
  point the app at an HTTPS tunnel or the CDN origin.

## Pending (not yet implemented — see `tasks.md`)

- The iOS data layer: DTO, mapper, endpoint, repository, and a real
  `AVPlayer`/`AVAudioPlayer` source. The current screen is a static mock.

## Open questions (resolved during implementation)

- <!-- none yet -->
