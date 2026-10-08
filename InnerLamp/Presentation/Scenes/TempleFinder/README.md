# TempleFinder

## Overview

Screen **"Chọn chùa tu tập"** — the prototype's `findtp` screen in *pick mode*. Pushed from the Chùa tab
("Đổi chùa", `ILSanghaCoordinator.showTempleFinder()`); leaf coordinator, no delegate (`.back` / `.picked`
pop + `finish()`). Design: `Docs/innerlamp-project/` prototype, screen `findtp` (read-only reference).

- Sticky header: `ILNavBar` (subtitle "Chùa hiện tại: …"), `ILSearchInputView`, 4 region chips
  (Tất cả / Miền Bắc / Miền Trung / Miền Nam).
- List: every temple of the catalog, "Chọn" pill per row (the current temple shows "Chùa của bạn"
  instead); tapping a row opens the Temple page. The last row, "Không thấy chùa bạn tìm?", opens the
  **"Đề xuất thêm chùa"** form in place of the list (name, address, province, phone — name and province
  required, duplicates of a listed temple rejected).
- Data: `ILTempleRepository.loadTemples(page:)` read page by page until `hasMore == false` (≈179 temples,
  local-first Core Data cache). Search/filter is client-side (diacritic-insensitive over name + address).
- "Chọn" → `ILSanghaUseCase.selectMyTemple(_:)` (id + name/address snapshot in `UserDefaults`), then the
  screen closes and the Chùa tab reloads on `viewWillAppear`.

**Proposal is UI only:** a valid submission closes the form and shows the green "Đã gửi đề xuất …" banner —
nothing is sent or stored, and the proposed temple is **not** selected. See
`Docs/Assumptions/TempleFinder/AS-TempleFinder-001-*.md` and `Docs/Tech-Debt/TempleFinder/TD-TempleFinder-001-*.md`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — UseCase | `Domain/UseCases/TempleFinder/ILTempleFinderUseCase.swift` | Done | All-pages load + id de-dup; pick delegates to `ILSanghaUseCase`. |
| Presentation — StateModel | `ILTempleFinderStateModel.swift` | Done | |
| Presentation — ViewModel | `ILTempleFinderViewModel.swift` | Done | 10 Inputs; search, region filter, pick, proposal validation. |
| Presentation — ViewController | `ILTempleFinderViewController.swift` | Done | Visual QA on device pending. |
| Presentation — Coordinator | `ILTempleFinderCoordinator.swift` | Done | |
| Feature-scoped views | `Views/ILTempleFinderCells.swift`, `Views/ILTempleFinderAddFormView.swift` | Done | Reuses `ILSanghaPillButton` from the Sangha feature. |
| Tests | `ILTempleFinderViewModelTests.swift`, `ILTempleFinderUseCaseTests.swift` | Written, not run | Test target does not compile in this environment (GRPC plugin / module errors). |
| Wiring | `DIContainer.makeTempleFinder*` | Done | |

## Changelog

- 2026-10-05 — initial implementation from the updated prototype (`findtp`).
