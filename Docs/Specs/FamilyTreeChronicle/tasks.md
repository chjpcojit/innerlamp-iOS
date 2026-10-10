# Tasks — FamilyTreeChronicle

Version: 1.0
Last updated: 2026-10-04
Source: design.md v1.0

- [x] Entity: `ILFamilyChronicleEntity`, `ILFamilyMilestoneEntity`, `ILFamilyTreeEntity.chronicle`
- [x] UseCase: draft, apply (validation), clan-head candidates / change, save stub
- [x] StateModel / ViewModel (16 input triggers) / ViewController / Coordinator
- [x] Views: masthead, founder card, text card, timeline, milestone editor, shrine card, plaque, people, head picker, shared controls
- [x] Unit tests written: `ILFamilyTreeChronicleViewModelTests`, `ILFamilyTreeChronicleUseCaseTests` (not executed)
- [x] Tech debt + assumptions recorded (TD-001…004, AS-001…003)
- [ ] Wiring: `DIContainer` factories + `ILFamilyTreeCoordinator` (seal tap, switcher row) — done by the FamilyTree work
- [ ] `xcodebuild build` (generic/platform=iOS) passes
- [ ] Persistence (`data-builder`) once an API / store is confirmed
