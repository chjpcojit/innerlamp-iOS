# Changelog — Bell Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## Implementation note (2026-10-03) — new stage UI

No spec prose changed. The pad is now an instrument photo + mallet stage (see the Bell README
changelog). Assumption AS-Bell-001, tech debt TD-Bell-001.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Bell feature
  (full in-memory practice tool with real audio, no persistence, no network).
- `requirements.md`: user story and 10 EARS acceptance criteria (immersive
  layout, pad strike + sound, preset selection, mode switch, every-milestone,
  rate adjust, play toggle, roll/reset, ring bell, back). "Pending" records the
  missing persistence and the absent sound/volume picker (with a ⚠️ on scope).
  One resolved open question (audio is a Presentation-layer concern, not Domain).
- `design.md`: Layers & components table (Entity + `ILBellMode`/`ILBellPreset`,
  UseCase, StateModel, ViewModel, leaf Coordinator, ViewController, Core/Audio
  files, 5 feature views), navigation flow, the synchronous in-memory data flow
  (steady rhythm `Timer`, `DispatchWorkItem` roll, auto-bell delay), and a
  persistence gap note. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 12
  + 11 tests; Phase 3 "not applicable"; Phase 4 leaves persistence and the sound
  picker as `[ ]`.
- Reason: Bell was one of the implemented features with no spec folder; written
  to close documentation debt, matching the `Docs/Specs/SignUp/` example.
