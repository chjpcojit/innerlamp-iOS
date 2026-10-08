# Design — PhotoViewer

Version: 1.0
Last updated: 2026-10-07

> See `changelog.md` in this folder for the version history of this spec.

## Layers

| Layer | File | Notes |
|---|---|---|
| Presentation — StateModel | `ILPhotoViewerStateModel.swift` | `ILPhotoViewerItemModel`, `ILPhotoViewerAction`, `ILPhotoViewerHeroID`, `ILPhotoViewerStateModel` |
| Presentation — ViewModel | `ILPhotoViewerViewModel.swift` | 5 `Input`s (close, previous, next, favorite, action); failable init (unknown start id); in-memory favorites; toast timer |
| Presentation — ViewController | `ILPhotoViewerViewController.swift` | `TransitionProviding` (hero push/pop), swipe gestures, always-dark UI, light status bar |
| Presentation — Views | `Views/ILPhotoViewerIconButton`, `Views/ILPhotoViewerInfoPanelView` | feature-scoped |
| Presentation — Coordinator | `ILPhotoViewerCoordinator.swift` | leaf; `.close` → pop + `finish()`; child of `ILPhotosCoordinator` |
| Tokens | `ILIcons.viewer*`, `vi.json` `photoViewer.*` | 5 template icons in `Assets.xcassets/Icons` |

No Domain/Data layer yet: the screen is fed by the Photos grid's models (mapped
by `ILPhotosCoordinator`), and its actions are stubs.

## Flow

1. `ILPhotosViewModel` emits `.openPhoto(photos, selectedID)` on tile tap.
2. `ILPhotosCoordinator` maps `ILPhotosPhotoModel` → `ILPhotoViewerItemModel`,
   adds `ILPhotoViewerCoordinator` as child and starts it.
3. Hero: grid tile image and viewer image share `heroID = "photo-<id>"`
   (`HeroTransition`). The viewer re-tags its image on every photo change so the
   pop morphs into the tile of the photo currently shown.
4. The Photos screen keeps the bottom nav hidden while the viewer is on top (it
   restores it only when it is itself popped).

## Future API (not built)

`GET /v1/gallery/{id}` — author, license, `source_url`; `404 GALLERY_IMAGE_NOT_FOUND`.
⚠️ Not confirmed: field names / types. Do not implement until a real response is captured.
