# Sangha

## Overview

Tab 3 of `ILMainTabBarController`, labelled **"Chùa"** in the bottom nav (formerly "Đạo tràng"),
owned by `ILMainTabCoordinator`. It is the user's **practice temple** ("chùa tu tập") — not a
catalogue of every temple in Vietnam. Design: prototype screen `sangha` (`Docs/innerlamp-project/`,
read-only reference — do not edit it).

Two states, plus a shared block:

- **Practice temple chosen** — eyebrow "CHÙA TU TẬP CỦA TÔI" + "Đổi chùa"; temple card (cover
  placeholder, name, address, open/closed pill, abbot) → Trang chùa; "Thông báo từ chùa"; "Khóa tu & lễ
  sắp tới" (+ "Tất cả", "Nhắc tôi" / "Giữ chỗ" pills); "Pháp thoại tại chùa"; "Công đức · cúng dường";
  practitioner-count card.
- **No temple chosen** — "Bạn chưa chọn chùa tu tập" card; "Chùa gần bạn" (map placeholder + rows with
  "Chọn"); "Chùa trực tuyến"; "Khóa tu sắp diễn ra".
- **Both** — "Ngày lễ & ngày chay sắp tới" (4 mock days, "Nhắc tôi" pill,
  "Lịch lễ" → Festivals).

**UI only for now:** the tab makes no API / Core Data call and has no loading or error state — all content
is synchronous mock data from `ILSanghaUseCaseImpl`. The practice temple id is stored in `UserDefaults`
(`sangha.myTempleID`, default Chùa Từ Quang, also used when the stored value is empty; the "no temple" state only appears for an unknown id). "Chọn" saves the id and re-renders; "Đổi chùa" opens the
**TempleFinder** screen (`Presentation/Scenes/TempleFinder/`, pick mode of the prototype `findtp`) — search the whole directory,
pick a temple, or propose a missing one (UI only). The tab reloads on `viewWillAppear`; a temple picked from the directory is stored
as id + name/address snapshot (`sangha.myTempleSnapshot`) — see `TD-Sangha-002`. See
`Docs/Assumptions/Sangha/AS-Sangha-001-*.md` and `AS-Sangha-002-*.md`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `Domain/Entities/ILSanghaEntity.swift` | Done | Announcement / event / talk / online session / my-temple / chooser. |
| Domain — UseCase | `Domain/UseCases/Sangha/ILSanghaUseCase.swift` | Partial | Practice temple id is stored locally; **everything else is mock** (temples, announcements, events, talks, peers, online sessions, retreats, festival days). No network / Core Data. |
| Presentation — StateModel | `ILSanghaStateModel.swift` | Done | |
| Presentation — ViewModel | `ILSanghaViewModel.swift` | Done | 13 Inputs, status / count / date formatting, local toggles. |
| Presentation — ViewController | `ILSanghaViewController.swift` | Done | Rebuilds sections per state; no loading / error UI. Visual QA pending. |
| Presentation — Coordinator | `ILSanghaCoordinator.swift` | Partial | Temple / Events / Talk / Festivals wired; Offer and online sessions TODO. |
| Feature-scoped views | `Views/` (card, date row, pill, my-temple card, online card, peers card, announcement row, temple row, placeholder) | Done | |
| Tests | `ILSanghaViewModelTests.swift`, `ILSanghaUseCaseTests.swift` | Written, not run | Test target does not compile in this environment (GRPC plugin / clang scan errors). |
| Wiring | `DIContainer` + `ILMainTabCoordinator` | Done | |

## Navigation events

- `openTemple(id)` — temple card / nearby row → `ILTempleCoordinator`.
- `openEvents` — "Tất cả" or any event / retreat row → `ILEventsCoordinator`.
- `openTalk(id)` — talk row → `ILTalkCoordinator`.
- `openFestivals` — "Lịch lễ" or a festival day row → `ILFestivalsCoordinator`.
- `openTempleFinder` — "Đổi chùa" → `ILTempleFinderCoordinator`.
- `openOffer`, `openOnlineSession(id)` — TODO (destination screens not built).

## Known gaps

See `Docs/Tech-Debt/Sangha/TD-Sangha-001-*.md`: mock content, display-only reminder toggles, no swap icon
on "Đổi chùa", Post scene unreachable, `Docs/Specs/Sangha/` not rewritten. "Chùa gần bạn" is the featured
list (no location) — AS-Sangha-002.

## Changelog

- 2026-10-05 — "Đổi chùa" now opens the new TempleFinder screen instead of clearing the choice (`clearMyTemple` removed);
  new `viewWillAppear` Input reloads the tab; `selectMyTemple(_ temple:)` + snapshot for directory temples.
- 2026-10-05 — rebuilt to match the prototype `sangha` screen (practice temple / chooser / festival days);
  bottom nav label "Đạo tràng" → "Chùa"; old community feed removed.
- 2026-09-26 / 2026-09-20 — previous community-feed implementation (removed).
