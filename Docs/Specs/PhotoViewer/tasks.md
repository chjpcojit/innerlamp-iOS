# Tasks — PhotoViewer

Version: 1.0
Last updated: 2026-10-07
Status: Phase 1 coded; build verified, tests written but not run

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI + local logic

- [x] Icon assets + `ILIcons.viewer*`, `photoViewer.*` copy keys
- [x] `ILPhotoViewerStateModel`, `ILPhotoViewerViewModel`, `ILPhotoViewerViewController`, 2 views, coordinator
- [x] `DIContainer.makePhotoViewerViewModel/Coordinator`; `ILPhotosCoordinator` opens it (`.openPhoto`)
- [x] Hero transition from grid tile; Photos keeps bottom nav hidden under the viewer
- [x] `InnerLampTests/ILPhotoViewerViewModelTests.swift`; 2 tests added to `ILPhotosViewModelTests`
- [ ] Run tests (needs a device or stable simulator)
- [ ] Visual QA on device (hero morph both ways, swipe, dark/light system mode)

## Phase 2 — API / real actions (blocked)

- [ ] Capture a real `GET /v1/gallery/{id}` response (backend gallery was empty on 2026-10-07), confirm in `design.md`
- [ ] Data layer + attribution UI (author, license, source link) — resolves `TD-Photos-001`
- [ ] Real Save (Photos library), Share sheet, favorites persistence — resolves `TD-PhotoViewer-001`

## Phase 3 — Documentation

- [x] `InnerLamp/Presentation/Scenes/PhotoViewer/README.md`
- [ ] `Docs/Knowledge/features/photo-viewer.md` (OKF) — after device verification
