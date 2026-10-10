# Design — Legal

Version: 1.0
Last updated: 2026-10-10
Status: not started — prospective; document text is bundled mock

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Legal follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **section
screen** owned by `ILSettingsCoordinator`; the initial document is a parameter of
the coordinator (`.terms` or `.privacy`), chosen by the Settings row. Text comes
from `ILLegalRepository`; the bundled implementation reads the existing `legal.*`
localization keys already used by `ILSignUpLegalSheetViewController`, so both
surfaces share one text source. Shape reference: `Language` (leaf screen from
Settings).

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLegalDocumentEntity.swift` | `ILLegalDocumentKind` (terms / privacy), `ILLegalDocumentEntity` (kind, title, effective text, `[ILLegalSectionEntity(heading, body)]`). Foundation only. |
| Domain / Repository | `Domain/Repositories/ILLegalRepository.swift` | `document(for kind:) async throws -> ILLegalDocumentEntity`. |
| Domain / UseCase | `Domain/UseCases/Legal/ILLegalUseCase.swift` | `loadDocument(kind:)`; maps failures to `ILLegalError`. |
| Data / Repository | `Data/Repositories/ILLegalRepositoryImpl.swift` | Bundled mock: keys `legal.<kind>.title`, `legal.<kind>.section<i>.heading/body` (6 terms, 5 privacy), `legal.effective`. Replaced by `NetworkService` once a contract exists. |
| Presentation / State | `Presentation/Scenes/Legal/ILLegalStateModel.swift` | UI-only state: selected kind, titles per kind, sections, loading/error, contact-card text. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Legal/ILLegalViewModel.swift` | `Input -> Output` (`selectDocument`, `retry`, `contactTapped`, `backTapped`); owns `ILLegalNavEvent` (`openContact`, `goBack`). |
| Presentation / Coordinator | `Presentation/Scenes/Legal/ILLegalCoordinator.swift` | `init(initial: ILLegalDocumentKind)`; pushes the VC; `.openContact` → delegate; `.goBack` → pop + finish. |
| Presentation / ViewController | `Presentation/Scenes/Legal/ILLegalViewController.swift` | Segmented control, title, effective line, sections card, contact card. |
| Feature-scoped views | `Presentation/Scenes/Legal/Views/ILLegalSegmentedControl.swift`, `ILLegalSectionView.swift`, `ILLegalContactCardView.swift` | Pill segmented control, one section, contact card. |

## Navigation flow

```
ILSettingsCoordinator
  └─ (.openTerms)   → showLegal(.terms)   → ILLegalCoordinator(initial: .terms)
     (.openPrivacy) → showLegal(.privacy) → ILLegalCoordinator(initial: .privacy)
       push ILLegalViewController
       (tap contact card) → openContact → delegate → showContactSupport()
       (tap back)         → pop + finish()
```

## Data flow

Single load, no multi-call sequence → Step-by-step Flow not required:

1. `viewDidLoad` → `loadDocument(initial)` → repository → StateModel → render.
2. Segment tap → ViewModel `selectDocument(kind)`; documents already loaded are
   reused (cached in the ViewModel), the other is loaded on demand; VC scrolls
   to top.
3. Failure → error state with retry.

The sections list is rebuilt only when the selected document changes
(`if sections != oldValue`), per AGENTS §4.6.

## Deliberately stubbed for now

The text, effective line ("Hiệu lực từ 01/09/2026 · InnerLamp 1.4") and the
account-deletion claim are bundled mock content, not a backend response. Tracked
in `tasks.md` Phase 3 and Assumption/Tech-Debt entries under
`Docs/Assumptions/Legal/` and `Docs/Tech-Debt/Legal/`.

## Design reference

Prototype `InnerLamp Prototype.dc.html`, screen `legal` (`Component.LEGAL`,
`lgpTabs`, `lgpSecs`).
