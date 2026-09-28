# Changelog — Mala Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Mala feature
  (full-screen bead counter with audio feedback, no persistence, no network).
- `requirements.md`: user story and 6 EARS acceptance criteria (immersive
  layout, advance bead + click, quarter milestone haptic, round complete + bell,
  reset without touching rounds, done/back). "Pending" records the missing
  persistence (with a ⚠️ on whether Mala and Home share a count) and the absent
  sound picker. One resolved open question (audio is Presentation-layer, not
  Domain).
- `design.md`: Layers & components table (Entity + milestone, UseCase, StateModel,
  ViewModel, leaf Coordinator, ViewController, Core/Audio, 4 shared components),
  navigation flow, data flow, and a persistence-gap note. No Step-by-step Flow —
  no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 7 +
  7 tests; Phase 3 "not applicable"; Phase 4 leaves persistence and the sound
  picker as `[ ]`.
- Reason: Mala was one of the implemented features with no spec folder; written
  to close documentation debt, matching the `Docs/Specs/SignUp/` example.
