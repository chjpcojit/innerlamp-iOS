# PhotoViewer

## Overview

Full-screen dark viewer for one Buddhist photo (lightbox of the `photos` screen in
`Docs/innerlamp-project/`). Opened from the Photos grid with a hero transition; swipe or arrows
page through the list currently shown; heart, counter and three action buttons. Leaf screen owned
by `ILPhotosCoordinator`; × pops back.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Presentation — StateModel | `ILPhotoViewerStateModel.swift` | Done | Item/action/hero-id/state. |
| Presentation — ViewModel | `ILPhotoViewerViewModel.swift` | Done (stub actions) | Paging, in-memory favorites, toast timer. Save/wallpaper/share only toast: `TD-PhotoViewer-001`. |
| Presentation — ViewController + Views | `ILPhotoViewerViewController.swift`, `Views/` | Done | Hero push/pop, swipe. Not seen on a device. |
| Presentation — Coordinator | `ILPhotoViewerCoordinator.swift` | Done | `.close` → pop + `finish()`. |
| Domain / Data | — | Not started | No API call; `GET /v1/gallery/{id}` contract unconfirmed. |
| Tests | `ILPhotoViewerViewModelTests.swift` | Written, not run | Test target could not be compiled with the generic iOS destination here. |

## Navigation events

- `.close` — × button: pop and `finish()`.

Entry: `ILPhotosNavEvent.openPhoto` (tap on a grid tile).

## Known gaps / not implemented yet

- Author / license / source (CC BY) — needs `GET /v1/gallery/{id}`: `TD-Photos-001`.
- Real save/share/favorites: `TD-PhotoViewer-001`. List is a snapshot: `TD-PhotoViewer-002`.
- 4:3 frame for every photo: `AS-PhotoViewer-001`.
- Not checked visually (hero morph, swipe, dark mode) on a device.

## Changelog

- 2026-10-07 — initial build: viewer UI, hero transition, paging, stub actions, Photos wiring, tests
