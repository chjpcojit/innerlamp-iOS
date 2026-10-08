# Changelog — Mala Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.1

- Redesign per the updated handoff (`Docs/InnerLamp icon consistency/`, screen
  `mala`): header "Xong" action and "Vòng N · biến x / goal" subtitle; goal chips
  21 / 54 / 108; red cord and wooden beads; "Tròn N biến" completion popup with
  "Niệm tiếp vòng mới"; the big count, hint line, footnote and bottom "Xong"
  button are removed.
- `requirements.md`: acceptance criteria rewritten (goal selection, round stops
  at goal instead of wrapping, next-round popup). Behavior change: reaching the
  goal no longer wraps to 1 — it waits for the user's choice.
- `design.md`: Entity now has `round` + `isRoundComplete` (replaces
  `completedRounds`); UseCase gains `selectGoal` / `startNextRound`; new
  `ILMalaCompletionView` and `ILMalaProgressBarView` (replaces
  `ILMalaCountDisplayView`).
- `tasks.md`: new Phase 2b; test run and bead grain texture left open.
- Also: bead-advance particle burst + ambient gold dust (`ILMalaParticleView`, design `mlFx`); one acceptance criterion extended.
- Reason: align Mala with the new design handoff.

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
