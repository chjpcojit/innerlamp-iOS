# Changelog — Donate Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this
folder. All three files share one changelog since they change together as one
spec unit. Newest version first.

## v1.1 — 2026-10-11

- Implementation landed: Domain / Data(mock) / Presentation / DI / Profile wiring,
  localization keys, unit tests, Assumptions AS-Donate-001…003, Tech Debt TD-Donate-001.
- `tasks.md`: Phases 1–2 and README ticked `[x]` (build-verified; unit tests not run
  yet, device QA pending). Phase 3 and OKF remain open.
- `design.md`: CTA reuses the `.gold` button variant instead of a new gradient
  token; added `ILColors.qrBackground`. `requirements.md`: header status only,
  criteria unchanged.

## v1.0 (initial) — 2026-10-11

- Initial spec written before implementation, derived from `SRS.md` and the
  prototype screen `paywall`.
- `requirements.md`: EARS criteria for entry, amounts, custom amount, message,
  transfer QR, thank-you, dismiss. Open items kept as ⚠️ Not confirmed: real
  account/QR, transfer-note rule, receipt claim, message destination, App Store
  acceptance.
- `design.md`: own modal coordinator, UseCase for amount rules, mock account
  repository, one VC with three steps; no Step-by-step Flow (no API).
- `tasks.md`: Phases 1–2 all `[ ]`; Phase 3 blocks release; Phase 4 docs.
- Reason: product owner asked for the "Ủng hộ InnerLamp" page and chose mock
  account, no API on confirm, prototype amount rules, Profile-only entry
  (2026-10-11).
