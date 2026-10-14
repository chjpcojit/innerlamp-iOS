# Tasks — Onboarding

Version: 2.0
Last updated: 2026-10-14
Status: in-progress (drift) — Phase 1–7 not started for v2.0; items marked `[x]` were read in code on 2026-10-14 and still match

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
- [ ] `Scripts/sync-product-vectors.sh` (shared with Memorial) copies `../innerlamp-be/docs/product/onboarding/rules/{phone-number,email,password,names}.json` into `InnerLampTests/ProductVectors/onboarding/` with the source commit; `ILOnboardingProductVectorTests` runs every case (criterion 29)

## Phase 3 — Registration call

- [ ] `ILSignUpEntity`: `phoneCountry`, `dharmaName?`; `ILSignUpDTO` + `ILSignUpMapper`: `email`, `password`, `phone_country`, `phone_number` (typed digits), `full_name`, `dharma_name?`, `ordination_temple_id?` (criterion 13)
- [ ] `ILSignUpRepositoryImpl` error mapping per `requirements.md` Error → UI; remove `EMAIL_TAKEN`, `SMS_SEND_FAILED`, `OTP_LOCKED` branches; add `EMAIL_SEND_FAILED`, `RATE_LIMITED` (criteria 13–15, 27)
- [ ] `ILSignUpUseCase`: validators via `ILSignUpRules`; dharma name not required, not pre-filled; strength stays advice (criteria 8–10)
- [x] Submit ignored while one is in flight (`ILSignUpViewModel.handleSubmit`) (criterion 16)
- [x] Temple picker: `GET /v1/temples/options`, paged, debounced server search, stale answers dropped (`ILOrdinationPlaceFieldView`, `ILSignUpViewModel`) (criterion 17)
- [ ] Unit tests: request body (no E.164 rebuild, optional fields omitted), every mapped error, `PHONE_TAKEN` keeps values

## Phase 4 — SignUp screen

- [ ] `ILSignUpViewController` + state: dharma name empty by default, email hint (sign-in + code), button "Đăng ký", phone error with Login link (criteria 7, 15)
- [ ] Remove `ILSignUpLegalSheetViewController` and the bundled legal strings; `ILSignUpCoordinator.presentLegal` with `SFSafariViewController` on `<websiteBaseURL>/terms` and `/privacy`; `websiteBaseURL` per build configuration (criterion 12) — production value ⚠️
- [x] Terms unchecked keeps the button disabled (`ILSignUpStateModel.isSubmitEnabled`) (criterion 11)
- [x] AddTemple: name, province and ward from the administrative-unit list, optional street line (`ILAddTempleUseCase`) (criterion 18)

## Phase 5 — Email code screen

- [ ] `ILOtpUseCase`, `ILOtpRepositoryImpl`, `ILOtpDTO`, `ILOtpMapper`, `VerifyOTPEndpoint`, `ResendOTPEndpoint`: email instead of phone, resend path `/v1/auth/register/resend-otp`, no `purpose`; user DTO reads `ordination_temple_id` (criteria 21, 23)
- [ ] `ILOtpStateModel` / `ILOtpViewModel`: live validity countdown, expired state, lock until `locked_until`, send-limited keeps the entry (criteria 20, 22, 24)
- [x] Resend wait seeded from the server and restarted after a resend (`ILOtpViewModel`) (criterion 23, timer part)
- [ ] `ILOtpViewController`: "Đã gửi tới <email>", "Đổi email"; delete `ILOtpVoiceCallBannerView` and its strings (criteria 20, 25)
- [ ] `ILOtpCoordinator` / `AppCoordinator.showOtp(email:…)`; "Đổi email" and `PENDING_REGISTRATION_EXPIRED` pop to the filled SignUp (criteria 25, 26)
- [ ] Unit tests: verify success stores the session, each error, timers, lock

## Phase 6 — Temple proposal sent

- [ ] `ILTempleSuggestionRepository` + `ILTempleSuggestionRepositoryImpl` over the existing `TempleSuggestionEndpoint`; called once after verify succeeds, result ignored for the user (criterion 19, Step 6); close `TD-SignUp-002`
- [ ] Unit test: proposal sent once after verify; failure still opens Main; no proposal when none kept

## Phase 7 — Strings, logging, QA

- [ ] `vi.json` (+ `en.json` if present): new copy of product §3.1.1; delete SMS / voice-call / "Đổi số" / email-taken keys (criterion 27)
- [ ] Check `NetworkLogger` never prints request bodies of `/v1/auth/*` (password, code, tokens) (criterion 28)
- [ ] Manual run against the backend dev build (fixed dev code): new email, existing email looks the same, phone taken, "Đổi email", expired registration, lock
- [ ] Update the iOS column of product §4.2 when done (tell `ba-writer`)
- [ ] Delete `Docs/Specs/{Splash,SignUp,Otp}/`, `Onboarding/SRS.md` and the related `Docs/Knowledge`, `Docs/Assumptions`, `Docs/Tech-Debt` files in the docs clean-up step
