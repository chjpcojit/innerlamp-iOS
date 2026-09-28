# Design — Share

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; share-to-community unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Share follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **modal
sheet** presented from Reader and Article, purely local in behavior (card
styling + native share/copy) except for the "Đạo tràng" destination, whose
posting behavior is unconfirmed. The shape follows a lightweight leaf feature.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILShareEntity.swift` | Pure business fields: verse text, kicker ("KINH PHÁP CÚ · KỆ 1"), source. |
| Domain / UseCase | `Domain/UseCases/Share/ILShareUseCase.swift` | Pure styling/selection logic + `copyToClipboard`/`shareToCommunity` (community call is a stub until confirmed). |
| Presentation / State | `Presentation/Scenes/Share/ILShareStateModel.swift` | UI-only state: selected background style, card text, active destination. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Share/ILShareViewModel.swift` | `Input -> Output`; owns `ILShareNavEvent` (dismiss, shareToCommunity). |
| Presentation / Coordinator | `Presentation/Scenes/Share/ILShareCoordinator.swift` | Modally presents `ILShareViewController`; dismisses on ✕. |
| Presentation / ViewController | `Presentation/Scenes/Share/ILShareViewController.swift` | Card preview, 3 background chips, 4 destination buttons. |

## Navigation flow

```
ReaderCoordinator / ArticleCoordinator
  └─ (tap "Chia sẻ") → presentShare(verse:) → ILShareCoordinator
       present (sheet) ILShareViewController
       (tap destination) → native share / copy / shareToCommunity
       (tap ✕) → dismiss
```

## Data flow

No mandatory network call (single local action per destination → Step-by-step
Flow not required):

1. Reader/Article pass the verse → `ILShareViewModel` renders the card.
2. Background selection is pure local state.
3. Destinations: Zalo/Facebook → native share sheet; Sao chép → clipboard;
   Đạo tràng → `shareToCommunity` (stub — unconfirmed API).

## Deliberately stubbed for now

`ILShareUseCase.shareToCommunity()` is a one-line stub (`print("TODO: …")`)
until the community-posting behavior is confirmed — see `requirements.md`
Pending. No Repository / Data layer exists for the other destinations because
they are native/local actions, not network calls.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `share`, and `Mo-ta-tinh-nang.md` §3 "Chia sẻ câu kinh".
