# Tasks — AddTemple

Version: 1.2
Last updated: 2026-10-11
Status: in-progress (Phase 1–2 done; Phase 3 pending)

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI
- [x] `ILAddTempleViewController` (header, intro, fields, error line, pinned CTAs)
- [ ] Visual QA on device against `InnerLamp Prototype.dc.html` (block `isAddTp`)

## Phase 2 — Logic
- [x] `ILAddTempleUseCase` validation + normalisation, `ILAddTempleViewModel`, coordinator, DI wiring
- [x] Unit tests written (`ILAddTempleUseCaseTests`, SignUp view-model tests)
- [ ] Run the unit tests (test target does not build here — GRPC plugin)

- [x] Province / ward dropdowns: `ILSelectFieldView`, `ILOptionPickerViewController`, `ILAddressMetadataRepository` (mock)
- [ ] Visual QA of the dropdowns + picker sheet on device

## Phase 3 — Data
- [x] Replace the mock metadata with the administrative-unit API (`TD-AddTemple-001` resolved)
- [ ] Submit the proposal to the server once a contract exists (⚠️ Not confirmed)
- [ ] Documentation: `Docs/Knowledge/features/addtemple.md` (OKF concept, after device verification)
