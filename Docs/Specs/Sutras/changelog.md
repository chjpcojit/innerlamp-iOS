# Sutras — Changelog

- 2026-10-03 — v1.0 initial spec written retroactively with the first implementation.
- 2026-10-07 — v1.1 integrated the real catalog API (`GET /v1/sutras`): paging, server filters (chips follow the API enums), client-side search on loaded pages. requirements / design / tasks rewritten; design gains a Step-by-step Flow. Resolves TD-Sutras-001; adds TD-Sutras-002/003 and AS-Sutras-002/003.
- 2026-10-07 — v1.2 backend added `audio_url`, a non-null `duration_minutes` and `q` search to `GET /v1/sutras`. REQ-5 now sends `q` (debounced 300 ms, ≤100 chars) and restarts from page 1; client-side `search` removed; REQ-9 added (audio badge from `audio_url`). Resolves TD-Sutras-003; narrows TD-Sutras-002 to the "downloaded" badge.
- 2026-10-07 — v1.2 added REQ-10: round "×" clear button in the search field (prototype `skClear`); implemented as opt-in `ILSearchInputView.showsClearButton`, enabled on this screen only.
