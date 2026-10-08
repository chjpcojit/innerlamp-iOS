# Tasks — FamilyTreeMember

Version: 1.0
Last updated: 2026-10-04
Status: code written; wiring, build and tests pending (owned by the FamilyTree rework)

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — Domain
- [x] `ILFamilyTreeMemberDraft`, field / issue types, `ILFamilyTreeMemberUseCase` + `Impl` (validation and member replacement are real; `save` is a stub — `TD-FamilyTreeMember-001`)

## Phase 2 — Presentation
- [x] StateModel, ViewModel (view + edit modes), ViewController, Coordinator
- [x] Views: hero, pill, info card, note box, memorial tiles, relation row

## Phase 3 — Wiring (done by the FamilyTree rework, not by this scene)
- [ ] `DIContainer`: `makeFamilyTreeMemberUseCase()`, `makeFamilyTreeMemberViewModel(tree:memberID:kinship:)`, `makeFamilyTreeMemberCoordinator(navigationController:tree:memberID:kinship:)`
- [ ] `ILFamilyTreeCoordinator`: `.openProfile` pushes this scene; implements `ILFamilyTreeMemberCoordinatorDelegate`
- [ ] Merge `familyTreeMember.*` strings into `vi.json`

## Phase 4 — Verification & records
- [x] Unit tests written: `ILFamilyTreeMemberViewModelTests`, `ILFamilyTreeMemberUseCaseTests` (not executed)
- [x] Tech-debt (`TD-FamilyTreeMember-001…003`) and assumption (`AS-FamilyTreeMember-001…003`) entries
- [ ] `xcodebuild build` (generic/platform=iOS) passes
- [ ] Run the unit tests
- [ ] Check on a device
