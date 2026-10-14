# Design — Donate

Version: 1.1
Last updated: 2026-10-11
Status: implemented (build-verified); account details and QR payload are mocked

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Donate follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **modal
flow** owned by its own `ILDonateCoordinator`, started with `startModal()` from
`ILProfileCoordinator` on the `.openDonate` event (same shape as
`ILLightLampCoordinator.startModal()`). One view controller renders three steps
(form → transfer → thanks) from a single StateModel, so "Đổi số tiền" keeps the
typed amount/message and back/close behave uniformly. No network call: the
receiving account comes from a repository protocol with a mock implementation.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILDonationEntity.swift` | `ILDonationAccountEntity` (recipient, bank, qrPayload), `ILDonationTransferEntity` (account, amount, note). Foundation only. |
| Domain / Repository | `Domain/Repositories/ILDonationAccountRepository.swift` | `account() -> ILDonationAccountEntity` (sync, local). |
| Domain / UseCase | `Domain/UseCases/Donate/ILDonateUseCase.swift` | Amount rules (presets, default index, minimum 10.000, max 9 digits), `sanitizeCustom(_:)`, `isValid(amount:)`, `transfer(for:)`. Pure logic. |
| Data / Repository | `Data/Repositories/ILMockDonationAccountRepository.swift` | Placeholder account constants; **not** a scannable bank payload. |
| Presentation / State | `Presentation/Scenes/Donate/ILDonateStateModel.swift` | `step`, selected amount option, custom text, message, amount, `ctaTitle`, `isCTAEnabled`, transfer rows. No UIKit. |
| Presentation / ViewModel | `Presentation/Scenes/Donate/ILDonateViewModel.swift` | `Input -> Output`; `ILDonateNavEvent` (`close`). Owns step transitions and amount rules via UseCase. |
| Presentation / Coordinator | `Presentation/Scenes/Donate/ILDonateCoordinator.swift` | `startModal()`: present `BaseNavigationController(.fullScreen)`; `.close` dismisses and `finish()`. |
| Presentation / ViewController | `Presentation/Scenes/Donate/ILDonateViewController.swift` | Sticky header (`ILStickyHeaderBand` + `ILNavBar` close), scroll content switching by step, keyboard avoidance. |
| Feature-scoped views | `Presentation/Scenes/Donate/Views/ILDonateAmountGridView.swift`, `ILDonateQRView.swift`, `ILDonateInfoTableView.swift`, `ILDonateThanksView.swift` | Amount grid (3×2) + custom field, QR render, details table, thank-you. |

Reuse from the Design System: `ILStickyHeaderBand`, `ILNavBar` (close), `ILLogoView`,
`ILButton`, `ILField`/`ILInputCardView`, `ILSectionEyebrowView`, tokens only.
The CTA reuses the `.gold` `ILButton` variant (the prototype's gradient is not tokenized); `ILColors.qrBackground` (always white) was added for the QR card.

## Navigation flow

```
ILProfileCoordinator
  └─ .openDonate → ILDonateCoordinator.startModal()
       present BaseNavigationController(ILDonateViewController) fullScreen
       form ──"Ủng hộ <amount>"──▶ transfer ──"Tôi đã chuyển khoản"──▶ thanks
        ▲                              │
        └──────── "Đổi số tiền" ───────┘
       close / "Để sau" / "Quay lại" → dismiss + finish()
```

## Data flow

No sequential API calls → Step-by-step Flow not required.

1. Open → ViewModel builds initial state (default amount 50.000₫, empty message).
2. Pick amount / edit custom → UseCase sanitizes digits, ViewModel recomputes
   `amount`, `ctaTitle`, `isCTAEnabled`.
3. Tap action (only if valid) → `transfer(for: amount)` builds recipient, bank,
   amount, note → state step `.transfer`.
4. QR image is generated off the main thread from `qrPayload` (CoreImage) and
   assigned on main.
5. "Tôi đã chuyển khoản" → step `.thanks`. Nothing is sent or stored.

## Deliberately stubbed for now

`ILMockDonationAccountRepository` returns placeholder recipient/bank and a
non-bank QR payload, so the QR can never resolve to an invented account. The
transfer note keeps the prototype rule only as a placeholder. Recorded as
Assumptions (`Docs/Assumptions/Donate/`) with an inline `// @ai: assumption —
see …` comment at the code site and tracked by `tasks.md` Phase 3 (blocks
release).

## Design reference

Prototype `InnerLamp Prototype.dc.html`, screen `paywall` (`spForm`, `spQr`,
`spThanks`, `spAmts`, `spInfo`); entry card in screen `profile` (`goPaywall`).
