# Design — Offering

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; payment & receipt contracts unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Offering follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**cross-section feature** with two screens (offering → receipt) reached from
Temple and Profile. The main action is a payment flow whose exact call structure
is unconfirmed; it is modeled as a two-step sequence below pending that
confirmation.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILOfferingEntity.swift` | Pure business fields: amount, dedication, temple, offering id, receipt code, timestamp. |
| Domain / UseCase | `Domain/UseCases/Offering/ILOfferingUseCase.swift` | `submitOffering(...)` + `getReceipt(...)` (delegate to repository); `ILOfferingError` maps failures. |
| Domain / Repository | `Domain/Repositories/ILOfferingRepository.swift` | `submitOffering(_:) async throws -> ILOfferingEntity`; `getReceipt(_:) async throws -> ILOfferingEntity` (if a separate call). Entity in/out. |
| Data / Repository | `Data/Repositories/ILOfferingRepositoryImpl.swift` | Wraps `NetworkService` (+ payment provider); DTO ↔ Entity, `NetworkError` → `ILOfferingError`. (Not yet created.) |
| Data / DTO + Mapper | `Data/DTOs/ILOfferingDTO.swift` + `Data/DTOs/Mappers/ILOfferingMapper.swift` | Wire shapes for the offering/receipt; Entity ↔ DTO. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Offering/ILOfferingStateModel.swift` | UI-only state: selected amount, custom input, dedication/temple, paying flag, receipt fields. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Offering/ILOfferingViewModel.swift` | `Input -> Output`; owns `ILOfferingNavEvent` (showReceipt, backToHome). |
| Presentation / Coordinator | `Presentation/Scenes/Offering/ILOfferingCoordinator.swift` | Pushes offering → receipt controllers; forwards nav events to the owning section. |
| Presentation / ViewController | `Presentation/Scenes/Offering/ILOfferingViewController.swift` (+ `ILOfferingReceiptViewController`) | Amount options, dedication/temple, payment button; receipt table + save/home actions. |

## Navigation flow

```
TempleCoordinator / ProfileCoordinator
  └─ (tap "Cúng dường" / "Công đức") → showOffering() → ILOfferingCoordinator
       push ILOfferingViewController
       (tap payment) → submit → push ILOfferingReceiptViewController
       (tap "Về trang chủ") → clear stack → Home
```

## Step-by-step Flow — Lamp offering (offering → receipt)

This flow involves payment and receipt generation. Whether these are one or two
API calls is unconfirmed; the structure below records that uncertainty inline.

```
Step 1 — Submit offering + pay (this feature)
- Trigger: user taps the payment button with a valid amount/dedication/temple
- Pre-condition: amount selected (or custom value entered), local validation passes
- API: POST <offering/payment endpoint> (amount, dedication, temple)
  ⚠️ Not confirmed: endpoint path, request/response shape, and whether a
  payment-provider redirect/confirmation is interposed here — blocks Phase 3.
    - Success → receive an offering id + receipt payload, go to Step 2
    - Failure (payment declined) → show error, stay on the offering screen
    - Failure (validation) → show per-field error, stay

Step 2 — Show receipt (this feature, boundary)
- Trigger: Step 1 success
- Effect: ILOfferingCoordinator pushes ILOfferingReceiptViewController with the
  receipt (Số tiền, Nơi nhận, Hồi hướng cho, Thời gian, Mã biên nhận).
  ⚠️ Not confirmed: whether the receipt is returned by Step 1's response, or
  needs a separate GET receipt call (in which case a Step 3 is added).
```

## Deliberately stubbed for now

`ILOfferingUseCase.submitOffering(...)` (and `getReceipt(...)` if that separate
call turns out to exist) are one-line stubs (`print("TODO: …")`) until the
payment contract lands — see `requirements.md` Pending. No DTO / Mapper /
Endpoint / `ILOfferingRepositoryImpl` exist yet (`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screens `offer` and `receipt`, and `Mo-ta-tinh-nang.md` §6 "Cúng dường đèn" /
"Biên nhận".
