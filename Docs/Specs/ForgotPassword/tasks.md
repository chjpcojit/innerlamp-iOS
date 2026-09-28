# Tasks — ForgotPassword

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built retroactively and reconciled with
> `il-screen-builder` rules (see the feature README changelog). Checked items
> below reflect what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILForgotPasswordViewController` extending `BaseViewController`
- [x] `setupViews()`: `ILNavBar` header, title/subtitle, `ILPhoneField`
      (reused — real input, not a static card), notice card, `ILButton`
      submit CTA, "Trở lại đăng nhập" link
- [x] `setupConstraints()`: `bottomStack` pinned to `keyboardLayoutGuide`,
      scroll area above, per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state` via `render(state:)`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isForgot`) —
      with the deliberate deviation that the phone/email switcher is omitted
- [x] Remove the phone/email switcher (`ILOptionCard` not used); `method` stays
      `.phone` default without breaking the ViewModel/tests

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILForgotPasswordEntity` (`fullPhone`, `fullEmail`) +
      `ILForgotPasswordMethod` (`phone`/`email`)
- [x] Create `ILForgotPasswordStateModel` (Presentation-side UI state, no UIKit
      import; `selectedContact` / `selectedFieldLabel` / `isPhoneValid` /
      `isSubmitEnabled` derived)
- [x] Create `ILForgotPasswordUseCase` / `ILForgotPasswordUseCaseImpl`:
      - `getInitialState()` (returns `ILForgotPasswordEntity.empty` — no
        Keychain read, per the "no local Repository call" rule)
      - `sendResetInstructions(method:contact:)` — **stub only**
      - `ILForgotPasswordError` (`.contactNotFound`)
- [x] Create `ILForgotPasswordViewModel` (`Input -> Output`,
      `ILForgotPasswordNavEvent`, `navigationEventPublisher`)
- [x] Create `ILForgotPasswordCoordinator` + `ILForgotPasswordCoordinatorDelegate`
- [x] Wire `DIContainer.makeForgotPasswordUseCase/ViewModel/Coordinator`
- [x] Wire `AppCoordinator.showForgotPassword()` + conform to
      `ILForgotPasswordCoordinatorDelegate` (phone → OTP, email → print TODO)
- [x] Unit tests: `InnerLampTests/ILForgotPasswordViewModelTests.swift` (11
      tests, driven via `Input` publishers, `MockILForgotPasswordUseCase`) —
      covering initial state, method change, phone/country change, back/back-to-
      login events, submit-without-contact no-op, phone→OTP, email→reset, and
      failure-stays-on-screen

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the reset-instructions endpoint does not exist in
> `Docs/Specs/API/openapi.yaml` v3.9 (see `requirements.md` Pending). Everything
> below is blocked until a reset contract is defined.

- [ ] Define the reset API contract with the backend team — request/response
      shape, error cases (e.g. `contactNotFound`), and whether it is a distinct
      route or a `purpose` on `resend-otp`
- [ ] Create `ILForgotPasswordRepository` protocol (Domain) — none exists yet
- [ ] Create `ILForgotPasswordDTO` + `ILForgotPasswordMapper` (once the contract
      is confirmed)
- [ ] Create the `Endpoint` conformance under `Data/DataSources/Remote/`
- [ ] Create `ILForgotPasswordRepositoryImpl` (`Data/Repositories/`) wrapping
      `NetworkService`; map `NetworkError` → `ILForgotPasswordError`
- [ ] Decide whether `getInitialState()` should pre-fill the registered contact
      (requires an Auth API / Keychain read — see ⚠️ in `requirements.md`)
- [ ] Inject `ILForgotPasswordRepository` into `ILForgotPasswordUseCaseImpl.init`
      and replace the `sendResetInstructions` stub body with the real call
- [ ] Update `ILForgotPasswordViewModelTests` + add a mock repository to cover
      real success/failure paths
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Email reset + true reset OTP (pending, separate scope)

- [ ] Build an email-verification screen (`.didRequestEmailReset` currently
      reaches a `print` in `AppCoordinator`)
- [ ] Resolve whether the phone path should use a dedicated reset OTP (the
      `purpose` enum lists `reset_password` but returns `UNSUPPORTED_OTP_PURPOSE`)
      instead of reusing the post-registration OTP screen
- [ ] Update `InnerLamp/Presentation/Scenes/ForgotPassword/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/ForgotPassword/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/forgot-password.md` (OKF concept) — hold off
      until the reset API (Phase 3) lands. See `Docs/Specs/OKF.md`.
