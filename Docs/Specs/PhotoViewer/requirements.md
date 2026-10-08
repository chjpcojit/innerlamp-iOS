# Requirements — PhotoViewer

Version: 1.0
Last updated: 2026-10-07
Status: Phase 1 (UI + local logic) coded; API detail call pending backend sample

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Full-screen viewer ("lightbox") for one Buddhist photo, opened by tapping a tile
in the Photos grid (`Docs/Specs/Photos/`). Source of truth for the layout:
`Docs/innerlamp-project/project/InnerLamp Prototype.dc.html` (screen `photos`,
`pvOpen` block).

## Acceptance criteria (EARS)

- WHEN the user taps a photo tile in the Photos grid, THE SYSTEM SHALL open the
  viewer on that photo, morphing the tile into the large image (hero transition),
  over the list currently shown (respecting the active category filter).
- THE SYSTEM SHALL show a dark background, a close (×) control, a counter
  "N / total", a favorite heart, the photo at full width with a 4:3 frame, the
  category (uppercase eyebrow), title, place, and three actions: Lưu ảnh,
  Đặt hình nền, Chia sẻ.
- WHEN the user swipes left / taps the right arrow, THE SYSTEM SHALL show the next
  photo; swipe right / left arrow shows the previous one; the arrow at either end
  of the list SHALL be hidden.
- WHEN the user taps the heart, THE SYSTEM SHALL toggle that photo's favorite state
  for this session and show "Đã thêm vào yêu thích" / "Đã bỏ yêu thích".
- WHEN the user taps an action, THE SYSTEM SHALL show its confirmation toast
  (Lưu ảnh → "Đã lưu vào thư viện ảnh", Đặt hình nền → "Đã đặt làm hình nền",
  Chia sẻ → "Đã sao chép liên kết") for about 1.8 s. The actions themselves are
  stubs (see Pending).
- WHEN the user changes photo, THE SYSTEM SHALL clear any toast.
- WHEN the user taps ×, THE SYSTEM SHALL close the viewer and morph back into the
  tile of the photo being shown (crossfade if that tile is off screen).

## Out of scope

- Loading more pages while paging inside the viewer (the list is a snapshot).
- Pinch-to-zoom.

## Pending (not yet implemented)

- ⚠️ Not confirmed: `GET /v1/gallery/{id}` response shape (author, license,
  `source_url`). The dev backend had an empty gallery on 2026-10-07, so no real
  sample could be captured. Needed for `TD-Photos-001` (CC BY attribution).
- Real Save / Set wallpaper / Share and persisted favorites:
  `Docs/Tech-Debt/PhotoViewer/TD-PhotoViewer-001-stub-actions.md`.
