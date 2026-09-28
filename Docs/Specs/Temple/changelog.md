# Changelog — Temple Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v2.0 — full redesign to match `Component.TEMPLE_INFO`

- Rebuilt the Temple detail screen to match the complete design handoff
  (`isTemple` in `InnerLamp Prototype.dc.html`), which the v1.0 spec/code only
  partially implemented (a simplified 3-stat strip instead of the real status
  card + facts grid, no org info / architecture / amenities / visit rules /
  location & contacts sections).
- `requirements.md`: rewrote the acceptance criteria to cover every section of
  the redesigned screen (hero chips + alias, 3 buttons, status card, facts
  grid, collapsible biography, org info, architecture + highlights, amenities,
  visit rules, sessions incl. empty state, location & contacts, footer) and
  their new interactions (`.openURL` for Maps/contacts). Added one resolved
  open question about the two different "no rank" fallback strings.
- `design.md`: rewrote the Layers & components table for the expanded
  `ILTempleEntity`/`ILTempleStateModel` shape, documented the client-side
  open/closed + distance computation (`ILLunarCalendar` + haversine) in Data
  flow, added `.openURL` to the navigation flow, and recorded the removal of
  `ILTempleStatsView` in favor of `ILTempleStatusCardView` + the facts grid.
- `tasks.md`: Phase 1–2 items updated/annotated for the v2 scope (all still
  `[x]`, now 11 tests instead of 6); Phase 4 gained a completed "wire
  Google/Apple Maps + contact URLs" item; Phase 5's OKF item is now done.
- Reason: the user asked to update the Temple screen to match the new design;
  the design handoff's `TEMPLE_INFO` data model turned out to be substantially
  richer than what v1.0 had speced/shipped, so both the spec and the
  implementation needed a full pass rather than an incremental patch.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Temple feature
  (the detail screen only; the discovery/list scope in `SRS.md` is not built).
- `requirements.md`: user story and 6 EARS acceptance criteria (load name +
  subtitle + stats + description + sessions + address, follow toggle, offer
  event, directions event, session event, back). "Pending" records the static
  catalog (with a ⚠️ on the temple API), the `toggleFollow` stub, the three TODO
  destinations, and the absent loading/error states. One resolved open question
  (only the detail screen shipped; the discovery feature is separate). Notes
  `SRS.md` as an upstream BA document describing a larger scope.
- `design.md`: Layers & components table (Entity + session/tone/glyph, UseCase,
  StateModel, ViewModel, leaf Coordinator, ViewController, 2 feature views,
  shared tokens), navigation flow (from Home + Sangha), data flow, and a
  "Deliberately stub / mock" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 6
  tests; Phase 3 (temple API) pending on contract; Phase 4 (sub-destinations)
  pending; a "Deferred" section records the discovery/list scope from `SRS.md`
  as a separate future feature.
- Reason: Temple had only an upstream `SRS.md`; written the 3-file convention
  retroactively to document what actually shipped (the detail screen), while
  keeping `SRS.md` as the BA source.
