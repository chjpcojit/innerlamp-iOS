# Tasks — Onboarding

Version: 2.3
Last updated: 2026-10-27
Status: in-progress — registration call and email code screen (Phases 3 and 5, core items) built on 2026-10-27, not yet built or tested on a Mac; Phases 1, 2, 4, 6, 7 and the listed Phase 3/5 items open

> See `changelog.md` in this folder for the version history of this spec.

Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flow.

## Phase 1 — Splash and intro

- [x] Fresh install deletes a leftover Keychain session before routing (`ILSplashUseCase.hasSession`) (criterion 2)
- [x] Intro steps, toggles, "Bỏ qua" / "Tạo tài khoản" save the choices locally and set `has_completed_onboarding` (`ILOnboardingUseCase.savePreferences`) (criteria 3–5)
- [ ] `ILSplashViewModel` + `AppCoordinator`: intro seen and no session → `.goToLogin` → `showLogin()` as root; remove `.goToSignup` / `splashDidRequestSignup` (criterion 1)
- [ ] `ILOnboardingViewModel.handleBack` on step 1 ("Tôi đã có tài khoản"): `savePreferences` before `.goToLogin` (criterion 4)
- [ ] Unit tests: splash routes (session / not seen / seen without session), intro flag set on all three exits

## Phase 2 — Rules + product vectors

- [ ] `Domain/Validation/ILSignUpRules.swift`: phone normalisation per country, email trim + lowercase + ≤ 254, password 8–64 characters after NFC, full name 1–300, dharma name optional ≤ 255 (criterion 9)
- [ ] `ILCountry.all` stays the 12 countries of BR-ONB-04 (already exact lengths, Malaysia present) — keep; remove `nationalDigitRange` use for the wire format
- [ ] `Scripts/sync-product-vectors.sh` (shared with Memorial) copies `../innerlamp-be/docs/product/onboarding/rules/{phone-number,email,password,names}.json` into `InnerLampTests/ProductVectors/onboarding/` with the source commit; `ILOnboardingProductVectorTests` runs every case (criterion 30)

## Phase 3 — Registration call

- [x] `ILSignUpEntity`: `phoneCountry`, `dharmaName?`; `ILSignUpDTO` + `ILSignUpMapper`: `email`, `password`, `phone_country`, `phone_number` (typed digits), `full_name`, `dharma_name?`, `ordination_temple_id?` (criterion 13)
- [x] `ILSignUpRepositoryImpl` error mapping per `requirements.md` Error → UI; remove `EMAIL_TAKEN`, `SMS_SEND_FAILED`, `OTP_LOCKED` branches; add `EMAIL_SEND_FAILED`, `REGISTRATION_IN_PROGRESS` (reads `details.retry_after_seconds`), `RATE_LIMITED` (criteria 13–15, 16a, 27)
- [x] `ILSignUpUseCase`: dharma name not required, not pre-filled; length limits after NFC (full name ≤ 300, dharma name ≤ 255, email ≤ 254, password 8–64); strength stays advice (criteria 8–10)
- [ ] Move the validators into `ILSignUpRules` (Phase 2)
- [x] Submit ignored while one is in flight (`ILSignUpViewModel.handleSubmit`) (criterion 16)
- [x] Temple picker: `GET /v1/temples/options`, paged, debounced server search, stale answers dropped (`ILOrdinationPlaceFieldView`, `ILSignUpViewModel`) (criterion 17)
- [ ] Auth requests carry no `X-API-Key` / `X-InnerLamp-Client-IP` (criterion 29)
- [x] Unit tests: request body (no E.164 rebuild, optional fields omitted), every mapped error incl. `REGISTRATION_IN_PROGRESS` (written, not yet run)
- [ ] Unit test: `PHONE_TAKEN` keeps values (with criterion 26a)

## Phase 4 — SignUp screen

- [x] `ILSignUpViewController` + state: dharma name empty by default, email hint (sign-in + code), button "Đăng ký" (criterion 7)
- [ ] Phone error with Login link (criterion 15) — `PHONE_TAKEN` shows under the phone field without the link
- [x] Terms links open the bundled legal sheet without touching the form (`ILSignUpLegalSheetViewController`) — kept as is in v2.0 (criterion 12)
- [x] Terms unchecked keeps the button disabled (`ILSignUpStateModel.isSubmitEnabled`) (criterion 11)
- [x] AddTemple: name, province and ward from the administrative-unit list, optional street line (`ILAddTempleUseCase`) (criterion 18)

## Phase 5 — Email code screen

- [x] `ILOtpUseCase`, `ILOtpRepositoryImpl`, `ILOtpDTO`, `ILOtpMapper`, `VerifyOTPEndpoint`, `ResendOTPEndpoint`: email instead of phone, resend path `/v1/auth/register/resend-otp`, no `purpose`; user DTO reads `ordination_temple_id` (criteria 21, 23)
- [ ] `ILOtpStateModel` / `ILOtpViewModel`: live validity countdown, expired state, lock until `locked_until`, send-limited keeps the entry (criteria 20, 22, 24)
- [x] Resend wait seeded from the server and restarted after a resend (`ILOtpViewModel`) (criterion 23, timer part)
- [x] `ILOtpViewController`: "Đã gửi tới <email>", "Đổi email"; delete `ILOtpVoiceCallBannerView` and its strings (criteria 20, 25)
- [x] `ILOtpCoordinator` / `AppCoordinator.showOtp(email:…)`; "Đổi email" pops back to SignUp (criterion 25)
- [ ] `PENDING_REGISTRATION_EXPIRED` pops to the filled SignUp (criterion 26) — today it shows the error on the code screen
- [ ] Verify `INVALID_TEMPLE` and `PHONE_TAKEN` pop to SignUp with every value kept and the field error (Step 4, criterion 26a)
- [x] Unit tests: verify success stores the session, each error, resend wait (written, not yet run)
- [ ] Unit tests: live validity countdown and lock state (with the state-model item above)

## Phase 6 — Temple proposal sent

- [ ] `ILTempleSuggestionRepository` + `ILTempleSuggestionRepositoryImpl` over the existing `TempleSuggestionEndpoint`; called once after verify succeeds, result ignored for the user (criterion 19, Step 6); close `TD-SignUp-002`
- [ ] Unit test: proposal sent once after verify; failure still opens Main; no proposal when none kept

## Phase 7 — Strings, logging, QA

- [x] `vi.json` (+ `en.json` if present): delete SMS / voice-call / "Đổi số" / email-taken keys; add email, rate-limit and code-screen keys (criterion 27; copy missing from product §3.1.1 is `AS-Onboarding-002`)
- [ ] Check `NetworkLogger` never prints request bodies of `/v1/auth/*` (password, code, tokens) (criterion 28)
- [ ] Manual run against the backend dev build (fixed dev code `111111`; the backend is still uncommitted and untested against a server): new email, existing email looks the same, phone taken, registration in progress, "Đổi email", expired registration, lock
- [ ] Update the iOS column of product §4.2 when done (tell `ba-writer`)
- [x] Delete `Docs/Specs/{Splash,SignUp,Otp}/`, `Onboarding/SRS.md` and the related `Docs/Knowledge`, `Docs/Assumptions`, `Docs/Tech-Debt` files in the docs clean-up step (2026-10-15; `TD-SignUp-002`, `-003`, `-004` and `TD-Splash-001`, `-002` kept: they describe code that is still there and close when it changes)
