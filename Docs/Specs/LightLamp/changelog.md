# Changelog — LightLamp Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v2.0 — 2026-10-17

- Reason: the cross-platform product spec for the lamp feature now exists (innerlamp-be
  `docs/product/lamp/product.md` v1.0, confirmed by the product owner on 2026-10-16) and settles
  what the iOS app does against the backend; this spec is rebased on it (migration of a legacy spec,
  the same way as `Memorial` and `Login`). Major bump: scope change (local-only → server-driven,
  sign-in gate, community garden) and new phases in `tasks.md`.
- `requirements.md`: rewritten in English with the `Product spec:` / `Contract:` / `Implements:`
  header; 33 numbered EARS criteria each tagged with its `FR-LMP-*` / `BR-LMP-*` or `(iOS)`; an
  Error → UI table; "Pending" lists the drift. Replaced behavior: calendar-day expiry and "Sáng đến
  hết hôm nay" → server end moment with "Còn N ngày" / "Còn dưới 1 ngày"; own lamps only and
  "Của bạn · <intention>" → everyone's lit lamps, lighter's name, "Của bạn" from the server, intention
  and prayer never in the garden; no limits → 100 / 300 characters and the limit of lit lamps shown
  from the server; guests get an introduction and a sign-in button; "Ẩn tên tôi" switch and the
  visibility notice added; blank recipient allowed ("Tất cả chúng sanh" supplied by the app); sign-out
  no longer deletes lamps (supersedes v1.3 FR-014); the stored Core Data lamps are dropped. The
  legacy `SRS.md` (v0.3) is superseded by the product spec and is not updated. The interim
  assumptions `AS-LightLamp-001…008` are resolved by the product spec (listed under "Open questions
  (resolved)"). Open `⚠️`: guest introduction copy, shared prompt vs lamp-specific guest view, the
  lighting-screen count line, the switch state after "Thắp thêm đèn", whether the card shows the end
  date, English copy, sharing; contract `⚠️`: optional recipient and the own-lamp flag (planned
  openapi 3.0.0).
- `design.md`: rewritten. Layers & components table with a state column; Step-by-step Flows for
  lighting (gate → local check → `POST /v1/lamps` → confirm) and the garden (`GET /v1/lamps`: first
  page, filter, load more); new Domain rules `ILLampInputValidator` and `ILLampRemaining`; removal of
  `ILLampMO` / `ILLampLocalDataSource` / the Core Data `Lamp` entity and of the lamp deletion in
  `ILSessionDataCleanerImpl`; product vectors section (two client-run files); "Known gaps" table from
  reading the code (replaces the v1.1 "Sign-out clearing" and "Data flow" sections).
- `tasks.md`: restructured into Phase 1 (built shell, ticked after reading the code) and new Phase 2–6
  (Domain, Data, Presentation, Tests and vectors, Documentation), all `[ ]`. Nothing is ticked on the
  strength of the unit tests, which have never been run (`TD-LightLamp-004`).
- Checked, no change needed: entry points (center button, Home row) and the absence of a temple-lamp
  card already meet the product spec (kept as ticked Phase 1 items).

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
