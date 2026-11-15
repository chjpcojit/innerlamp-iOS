# Changelog — Talk Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this
folder. All three files share one changelog since they change together as one
spec unit. Newest version first.

## v1.1 — 2026-11-15

- `requirements.md`: the backend contract is confirmed — an absolute public
  `audio_url`, HEAD/byte-range support, no DRM, and a player-unavailable state
  when the file is missing. Removes the two ⚠️ Not confirmed audio blockers and
  adds the matching acceptance criteria.
- `tasks.md`: Phase 3 marks the contract and audio-source questions resolved;
  the remaining work is the iOS data layer and the real player.
- `design.md`: the player uses the absolute `audio_url` via AVFoundation; the
  stream-vs-download question is resolved.
- No iOS code changed: the screen is still a static mock.

## v1.0.1 — 2026-10-16

- `requirements.md`: the link to the reading view now points to `Docs/Specs/Sutra/` (the former
  `Docs/Specs/Reader/` was merged into it and deleted). No requirement, design or task change.

## v1.0 (initial) — 2026-09-27

- Initial spec written before implementation, as the work order for building
  Talk. Covers the Dharma-talk detail screen (hero, inline player, chapters,
  follow-up meditation card), with the talk-detail API and audio-source
  contracts left ⚠️ Not confirmed.
