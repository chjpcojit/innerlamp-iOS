# Donate — "Ủng hộ InnerLamp"

Voluntary one-off donation by bank transfer. A single modal screen with three steps
(form → transfer QR → thanks), presented from the Profile "Ủng hộ InnerLamp" card.
Spec: `Docs/Specs/Donate/`. Prototype screen: `paywall`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `Domain/Entities/ILDonationEntity.swift` | Done | Account + transfer |
| Domain — Repository | `Domain/Repositories/ILDonationAccountRepository.swift` | Done | Protocol only |
| Domain — UseCase | `Domain/UseCases/Donate/ILDonateUseCase.swift` | Done | Amount rules, transfer note (placeholder rule) |
| Data — Repository | `Data/Repositories/ILMockDonationAccountRepository.swift` | Mock | Placeholder account; blocks release (TD-Donate-001) |
| Presentation — StateModel | `ILDonateStateModel.swift` | Done | |
| Presentation — ViewModel | `ILDonateViewModel.swift` | Done | Unit-tested |
| Presentation — Coordinator | `ILDonateCoordinator.swift` | Done | `startModal()` full screen |
| Presentation — ViewController | `ILDonateViewController.swift` | Done | Not yet checked on device |
| Presentation — Views | `Views/ILDonate*View.swift` | Done | Amount grid, QR, info table, thanks |

## Navigation events

- `close` — close button, "Để sau" or "Quay lại": dismiss the modal and `finish()`.

## Known gaps

- Receiving account and QR payload are mocked (AS-Donate-001, TD-Donate-001) — blocks release.
- Transfer note rule collides for 20.000 / 200.000 (AS-Donate-002).
- The message is never delivered and no receipt is created (AS-Donate-003).
- Gold CTA uses the existing `.gold` button variant, not the prototype's gradient.

## Changelog

- 2026-10-11 — initial implementation from prototype `paywall`.
