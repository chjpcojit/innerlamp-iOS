# AddTemple

## Overview

Screen **"Thêm thông tin chùa"** — the prototype's `addtp` screen (sign-up path). Pushed by
`ILSignUpCoordinator` when the user taps "Không thấy chùa của bạn? Thêm thông tin chùa" in the
ordination-place picker; the sign-up form's `ILSignUpViewModel` passes the typed query (prefilled as the
temple name) and the already-loaded catalog (for the duplicate check). Leaf coordinator with a delegate:
`.back` pops + `finish()`, `.submitted(proposal)` pops, calls
`ILAddTempleCoordinatorDelegate.addTempleDidSubmit` and `finish()`.

- Header `ILNavBar` ("Thêm thông tin chùa" / "Gửi để InnerLamp duyệt"), intro text, 3 fields — tên chùa
  (required), tỉnh / thành phố (required), địa chỉ (optional) — an inline error line, and a pinned footer
  with "Gửi để duyệt" + "Hủy".
- Validation (`ILAddTempleUseCase`): name required → province required → duplicate of a catalog temple
  (same core name without the "Chùa/Thiền viện/…" prefix, province contained in the catalog address).
- A valid submission only returns an `ILTempleProposalEntity`; the sign-up screen selects it as the
  ordination place with the "Đang chờ duyệt" label. **Nothing is sent to a server** — see
  `Docs/Tech-Debt/SignUp/TD-SignUp-002-*.md` and `Docs/Assumptions/AddTemple/AS-AddTemple-001-*.md`.
- The prototype's "suggest" mode (opened from `findtp`, shows a "Đã gửi đề xuất" confirmation) is not built.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `Domain/Entities/ILTempleProposalEntity.swift` | Done | |
| Domain — UseCase | `Domain/UseCases/AddTemple/ILAddTempleUseCase.swift` | Done | Validation + name normalisation. |
| Presentation — StateModel | `ILAddTempleStateModel.swift` | Done | |
| Presentation — ViewModel | `ILAddTempleViewModel.swift` | Done | |
| Presentation — ViewController | `ILAddTempleViewController.swift` | Done | Visual QA on device pending. |
| Presentation — Coordinator | `ILAddTempleCoordinator.swift` | Done | |
| Tests | `InnerLampTests/ILAddTempleUseCaseTests.swift` | Written, not run | Test target does not build here (GRPC plugin). |
| Wiring | `DIContainer.makeAddTemple*` | Done | |

## Changelog

- 2026-10-10 — initial implementation from the updated prototype (`addtp`, sign-up path).
