# Changelog — Deity Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v1.1 (2026-10-15)

- Translated to English per the repo Language policy; no requirement, design or task change.
- `requirements.md`, `design.md`, `tasks.md`, `changelog.md`: the prose was already English; quoted
  Vietnamese UI copy and Vietnamese domain terms (vía (feast day), Phật (Buddha), Bồ Tát
  (bodhisattva), Chư Thiên (devas)) now carry an English gloss in parentheses on first use in each file. Copy text, localisation keys, IDs, criteria numbering,
  `⚠️ Not confirmed` markers and task states are unchanged; version headers 1.0 → 1.1.
- Reason: editorial change to meet the `AGENTS.md` language rule (English Markdown docs).

## v1.0 (initial)

Initial spec written retroactively from the already-implemented Deity (deity page) and Deities
(catalogue) scenes plus the Home / Library deity carousels, and prospectively for the changes of the
cross-platform product spec innerlamp-be `docs/product/deity/product.md` @ v1.0. Docs only; no code
changed. 2026-10-15.

- `requirements.md`: header cites product v1.0, contract `openapi.yaml` @ a8a016b and the planned shape
  in backend deity `requirements.md` v3.0 (designed, contract not yet in `openapi.yaml`); implements
  BR-DTY-01…08, FR-DTY-001…010, NFR-DTY-01/02 (FR-DTY-011 backend only). 32 EARS criteria, each tagged
  with a product ID or `(platform)`; error → UI mapping; 11 open `⚠️ Not confirmed` markers (10 product
  hand-backs + the backend delivery date).
- `design.md`: layers table naming the real files and what changes; Step-by-step Flows for the catalogue
  (first page, next page, chip change) and the deity page (detail + related sutras in parallel, sutra
  page boundary); network-first caching; product vectors plan.
- `tasks.md`: Phase 1 records what is built and still matches product v1.0 (`[x]`, verified in code);
  Phase 2–8 list the drift to fix: deva label "Chư Thiên" (devas; was "Thiên Nữ" (celestial maidens), AS-Deity-DEVA); server pages
  of 12 + server `type` filter (was every page loaded, filtered on the device); vía (a deity's feast day, kept on a lunar date) from the backend with
  device-date countdown (was a 400-day on-device lunar scan in UTC+7 and a "Đản/Vía" (birth anniversary / feast day) name match);
  related sutras from `GET /v1/deities/{id}/sutras` (was a hard-coded title table); iconography, name
  block and canonical source shown; one chant / share action row; "Báo thông tin sai" (Report incorrect information) removed; prototype
  empty / error state on the catalogue and a block empty state on Home / Library; cached list pages that
  never expired → network-first; dead bundled catalogue (`getAllDeities`, `ILDeityRepository`,
  `makeDeityRepository`, `ILDeityLocalDataSource`) removed.
- Reason: product §1.5 merges the former `Deity` and `Deities` scene docs into one platform spec
  `Docs/Specs/Deity/`; no spec existed for either. The scene READMEs and `AS-Deity-DEVA-label.md` are
  kept (never deleted); their update / closure is tracked in `tasks.md` Phase 8.
