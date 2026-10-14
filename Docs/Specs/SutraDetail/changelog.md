# Changelog — SutraDetail Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.4 (2026-10-11)

- Product decision: the detail screen shows **all** fields the API returns. `summary` is shown when present
  and hidden while empty (backend seeds it later). Added EARS criteria for the summary, information and
  "Bản dịch & giấy phép" blocks and the unreviewed notice.
- `design.md`: layer row for the new DTO / Entity / StateModel / view fields; Step-by-step Flow note (still a
  single call). `tasks.md`: new Phase 6. Two ⚠️ Not confirmed items remain (row labels / deity-row tap;
  unreviewed-notice wording and the "reviewed" value).
- Backend JSON sample received the same day and the display was implemented (Phase 6 `[x]` except running
  the tests, README and device QA). Resolves the earlier "nested shapes pending" item.

## v1.3 (2026-10-11)

- Re-confirmed `GET /v1/sutras/{id}` with the backend: contract unchanged (BE HEAD `87c3083`). Recorded
  the fields the API returns that the app does not consume yet (`summary`, `deities`, `original_title`,
  `author`, `han_*`, `reference_note`, translation `variant` / `license_url` / `license_note` / `note`).
- `design.md` Step-by-step Flow and `requirements.md` Pending updated; ⚠️ Not confirmed item added.
  No code change. Adds AS-SutraDetail-002; AS-SutraDetail-001 corrected ("API has no description").

## v1.2 (2026-10-07)

- Integrated the real API (`GET /v1/sutras/{id}`): the static 11-sutra catalog and sample progress are
  gone; the screen shows kind + tradition, "N dòng · duration", collection · reference, translator /
  source / license, and the TOC from `sections` (hidden when empty). No audio / progress (TD-SutraDetail-002).
- `requirements.md`, `design.md` (+ Step-by-step Flow), `tasks.md` updated. Resolves TD-SutraDetail-001;
  adds TD-SutraDetail-002/003 and AS-SutraDetail-001.

## v1.1 (2026-10-03)

- Synced with the refreshed design handoff (`isDetail`): pinned `ILNavBar`
  header with a scroll hairline (>110pt), theme-aware hero (`--il-th-*`) with
  italic original name and wrapping chips, "Dịch / hiệu đính" line.
- Data-driven per sutra: kicker (KINH VĂN / THẦN CHÚ · sect), meta line, chips
  (purposes + "Có audio" + "✓ Đã tải về"), CTA "Tụng theo" / "Đọc kinh", play
  button only with audio, progress card only for Kinh Pháp Cú, 2 sample parts for
  the other sutras. Catalog grows from 1 to 11 sutras.
- `requirements.md`: criteria updated + 2 new criteria. `design.md`: Entity,
  UseCase, StateModel, views rows updated. `tasks.md`: v1.1 items added.
- Player screen needed no change (already on `ILNavBar` + `--il-pl-*`).

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented SutraDetail
  feature (full detail screen with static catalog; Download destination not
  built).
- `requirements.md`: user story and 5 EARS acceptance criteria (load hero +
  progress + description + TOC, open reader on chant/chapter, open player on
  play, download event, back). "Pending" records the missing sutra API (with a
  ⚠️ on the contract), the unimplemented Download destination, and the sample
  reading progress. One resolved open question (`.openPlayer` is wired — the
  README's "TODO" note for it is stale).
- `design.md`: Layers & components table (Entity + enums, UseCase, StateModel,
  ViewModel, Coordinator, ViewController, 2 feature views, shared tokens),
  navigation flow (Library → SutraDetail → Reader/Player), data flow, and a
  "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 8
  tests; Phase 3 (sutra API) pending on contract; Phase 4 (Download screen)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: SutraDetail was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
