# Design — ContactSupport

Version: 1.0
Last updated: 2026-10-10
Status: not started — prospective; channels and submit API are mocked

> See `changelog.md` in this folder for the version history of this spec.

## Overview

ContactSupport follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**section screen** owned by `ILSettingsCoordinator` (reached from Settings, and
from the footers of Help and Legal through their delegates). Channel actions are
launched by the coordinator through the system URL opener, never by the
ViewModel or ViewController. The only network-shaped action (submit) is a UseCase
stub behind a repository protocol until a contract exists. Shape reference:
`EditProfile` (form screen with validation).

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSupportEntity.swift` | `ILSupportChannelEntity` (kind: email / hotline / zalo, value, hours), `ILSupportTopic` enum, `ILSupportRequestEntity` (topic, message), `ILSupportReceiptEntity` (code, topic). Foundation only. |
| Domain / Repository | `Domain/Repositories/ILSupportRepository.swift` | `submit(_ request:) async throws -> ILSupportReceiptEntity`. (Implementation arrives with the API.) |
| Domain / UseCase | `Domain/UseCases/ContactSupport/ILContactSupportUseCase.swift` | `loadChannels()` (mock constants), `validate(message:)`, `submit(_:)` — **stub**: returns a locally generated receipt, see below. Maps failures to `ILContactSupportError`. |
| Presentation / State | `Presentation/Scenes/ContactSupport/ILContactSupportStateModel.swift` | UI-only state: channels, selected topic, message, validation error, sending flag, receipt, reply-phone text. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/ContactSupport/ILContactSupportViewModel.swift` | `Input -> Output`; owns `ILContactSupportNavEvent` (`openChannel(kind,value)`, `openHelp`, `goBack`); clears the error on edit. |
| Presentation / Coordinator | `Presentation/Scenes/ContactSupport/ILContactSupportCoordinator.swift` | Pushes the VC; opens `mailto:` / `tel:` / Zalo URL via `UIApplication.open`; reports an unopenable channel back to the ViewModel; `.openHelp` → delegate. |
| Presentation / ViewController | `Presentation/Scenes/ContactSupport/ILContactSupportViewController.swift` | Heading, channel card, form / confirmation card, FAQ shortcut. |
| Feature-scoped views | `Presentation/Scenes/ContactSupport/Views/ILSupportChannelRowView.swift`, `ILSupportRequestFormView.swift`, `ILSupportSentCardView.swift` | Channel row, form card, sent-confirmation card. |

Reuse from the Design System: chips (`ILChip`-style topic selector), `ILButton`,
`ILTextView`/field component if available, `ILCard`-style surfaces, tokens only.

## Navigation flow

```
ILSettingsCoordinator   (also reached from Help / Legal footer delegates)
  └─ showContactSupport() → ILContactSupportCoordinator
       push ILContactSupportViewController
       (tap channel) → openChannel → coordinator opens system URL
       (tap FAQ)     → openHelp    → delegate → pop to existing Help, else push Help
       (tap back)    → pop + finish()
```

## Data flow

Single network-shaped call (submit) → Step-by-step Flow not required:

1. Load → `loadChannels()` (mock) → render; reply note built from the signed-in
   user's phone (masked in logs).
2. Edit message → ViewModel updates state and clears the validation error.
3. Submit → ViewModel `validate(message:)`; on failure show the error, else set
   `sending` → `useCase.submit(request)` → success: show sent card with code;
   failure: show error, keep message.
4. "Gửi yêu cầu khác" → reset message and topic, show the form.

> ⚠️ Not confirmed: source of the signed-in user's phone number for the reply
> note (profile/session UseCase to be identified at build time) — blocks FR-005a;
> the note falls back to generic text without a number.

## Deliberately stubbed for now

`ILContactSupportUseCaseImpl.submit(_:)` has no repository call: it returns a
locally generated code of the form `#IL-<4 digits>`. Channel values
(`hotro@innerlamp.vn`, `1900 6868`, Zalo OA "InnerLamp") and hours (8:00–21:00)
are hardcoded mock constants. Both are recorded as Assumptions
(`Docs/Assumptions/ContactSupport/`) with an inline `// @ai: assumption — see …`
comment at the code site, and tracked by `tasks.md` Phase 3.

## Design reference

Prototype `InnerLamp Prototype.dc.html`, screen `contact` (`ctChannels`,
`ctTopics`, `ctSend`, `ctSentOn`).
