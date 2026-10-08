# Changelog — SutraDetail Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

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
