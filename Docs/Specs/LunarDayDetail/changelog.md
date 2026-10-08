# Changelog — LunarDayDetail Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this
folder. All three files share one changelog since they change together as one
spec unit. Newest version first.

## v2.0 — 2026-10-07

- `requirements.md`: scope change — the hero gets a real server image. Added 5
  EARS criteria (request per date in parallel with local data; image under a
  scrim + attribution line; explicit `yyyy-MM-dd`, verbatim `image_url`; skip
  outside 1900–2100; every failure keeps the gradient with no error UI). The
  "no network" criterion now says the hero image is the only server-backed
  content. The hero-imagery ⚠️ is superseded by the new criteria; a new ⚠️ asks
  whether CC BY / CC BY-SA require a tappable license link. Two questions moved
  to "resolved" (which screen; backend now serves the image).
- `design.md`: no longer "no Data layer" — added Entity, Repository, UseCase,
  Endpoint, DTO, Mapper, Repository impl, State fields, ViewModel/Hero view
  changes, localization key and DI wiring; added "API contract" (confirmed by
  `[BE]-InnerLamp`, 2026-10-07) and a one-step "Step-by-step Flow"; data flow
  and performance note updated.
- `tasks.md`: Phase 3 changed from "not applicable" to a real API-integration
  Phase (all `[ ]` — spec written, code not yet); Phase 4 hero-imagery item
  superseded, extra QA/host/tech-debt items added.
- Reason: backend delivered `GET /v1/calendar/image`; the day-detail screen is
  the natural place for a per-date picture and already had a pending image slot.
  Major bump because the feature gains a network layer.

## v1.1 — 2026-10-07

- Re-added Hạc thần (direction to avoid) to the travel-directions section, which
  v1.0's later design realignment (2026-09-28) had removed: Entity gains
  `craneStarDirection: String?`, StateModel `.crane` kind, ViewModel third
  direction card, View renders the three cards in one row.
  Then aligned to the design handoff: 3-column single row, glyph stacked above
  the name, red `ILColors.inauspicious` tone, copy "Nên tránh hướng này" /
  "Trên trời" / "Không kỵ hướng nào"; name kept as "Hạc thần" (design says
  "Hắc thần"). `requirements.md` and `design.md` updated. Tài thần table unchanged — see
  `Docs/Assumptions/LunarDayDetail/AS-LunarDayDetail-001-star-direction-tables.md`.

## v1.0 (initial) — 2026-09-27

- Initial spec written retroactively from the already-implemented
  LunarDayDetail feature (built by `il-screen-builder` from the design handoff),
  documenting what shipped: a pure client-side lunar-computation leaf screen
  owned by `ILHomeCoordinator`, with Entity / UseCase / StateModel / ViewModel /
  Coordinator / ViewController + 6 feature views and full unit tests. No Data
  layer (no API). Pending: hero imagery, non-Vietnamese localization, advice
  copy/position confirmation, and visual QA.
