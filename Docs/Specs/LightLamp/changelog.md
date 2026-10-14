# Changelog — LightLamp Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v1.3 — 2026-10-11

- Reason: Profile now has a sign-out (`Docs/Specs/Profile/`, v1.4) and the product owner decided
  lamps are cleared with the rest of the account's local data (mock data; a lamp API is planned).
- `SRS.md` v0.3: FR-014 added. `requirements.md`: Data criterion added. No change to lighting or
  garden behavior; the clearing itself is implemented by the Profile feature's session data cleaner.

## v1.2 — 2026-10-11

- The center tab-bar lamp button now opens Thắp đèn (product owner instruction), replacing
  Chuẩn bị thiền; removed it from out-of-scope. `AS-LightLamp-005` validated for the button, still
  open for other entry points (Memorial, Temple).

## v1.1 — 2026-10-11

- Built the feature. Spec adjusted to what was implemented: no owner name is stored (cards show
  "Của bạn · <intention>", `AS-LightLamp-004`) because the app has no real display-name source; the
  repository exposes `loadAll()` and the use case filters expiry; Home row `.offering` →
  `.openLightLamp` is the only entry point (`AS-LightLamp-005`). Behavior of the requirements is
  otherwise unchanged. `tasks.md` Phases 1–3 ticked except the unit-test run.

## v1.0 (initial) — 2026-10-11

- Initial spec written before implementation, as the work order for building LightLamp (Thắp đèn +
  Vườn đèn), derived from `SRS.md` v0.1. Local Core Data persistence, no API; unconfirmed items
  carried inline with interim defaults.
