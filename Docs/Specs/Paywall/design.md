# Design — Paywall

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; StoreKit products unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Paywall follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **section
screen** (presented over a dark backdrop) owned by the Profile coordinator. Its
only dependency is StoreKit for products and purchase; there is no custom
backend call modeled yet, though entitlement verification may later require one.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILPaywallEntity.swift` | Pure business fields: plan id, title, price, per-month note, badge, isTrial. |
| Domain / UseCase | `Domain/UseCases/Paywall/ILPaywallUseCase.swift` | `loadPlans()` (delegates to repository), CTA/note derivation, `purchase(plan:)`. |
| Domain / Repository | `Domain/Repositories/ILPaywallRepository.swift` | `listPlans() async throws -> [ILPaywallEntity]`; `purchase(_:) async throws -> Void`. |
| Data / Repository | `Data/Repositories/ILPaywallRepositoryImpl.swift` | Wraps StoreKit (and later a receipt-validation call). (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Paywall/ILPaywallStateModel.swift` | UI-only state: plans, selected plan, CTA/note text, purchasing flag. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Paywall/ILPaywallViewModel.swift` | `Input -> Output`; owns `ILPaywallNavEvent` (purchased, dismiss). |
| Presentation / Coordinator | `Presentation/Scenes/Paywall/ILPaywallCoordinator.swift` | Presents `ILPaywallViewController`; dismisses on "Để sau". |
| Presentation / ViewController | `Presentation/Scenes/Paywall/ILPaywallViewController.swift` | Dark backdrop, benefits, plan radios, CTA + note, dismiss link. |

## Navigation flow

```
ProfileCoordinator
  └─ (tap "Sen Vàng") → showPaywall() → ILPaywallCoordinator
       present ILPaywallViewController
       (tap CTA) → purchase → confirmation / receipt
       (tap "Để sau, tôi dùng bản miễn phí") → dismiss
```

## Data flow

StoreKit purchase (single action, no multi-call sequence → Step-by-step Flow not
required):

1. `viewDidLoad` → `loadPlans()` → `ILPaywallRepository.listPlans()` (StoreKit
   products).
2. CTA → `purchase(plan:)` → StoreKit → on success emit `.purchased`.

## Deliberately stubbed for now

`ILPaywallUseCase.purchase(plan:)` is a one-line stub (`print("TODO: …")`) until
the StoreKit product identifiers and entitlement approach are confirmed — see
`requirements.md` Pending. No `ILPaywallRepositoryImpl` exists yet
(`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `paywall`, and `Mo-ta-tinh-nang.md` §6 "Gói Sen Vàng".
