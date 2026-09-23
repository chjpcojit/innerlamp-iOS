# Knowledge Bundle Update Log

## 2026-09-23

- Rewrote `features/signup.md` (`status: draft`) after re-reading the
  SignUp code end to end. The concept had described a feature whose
  backend call was a `print("TODO: …")` stub and whose data layer did not
  exist; both are now false. Documented the real chain
  (`ILSignUpUseCaseImpl.sendVerificationCode` → `ILSignUpRepositoryImpl` →
  `ILSignUpMapper` → `RequestRegistrationOTPEndpoint` →
  `NetworkService`), added the new `ILSignUpOTPEntity`, the DTO / mapper /
  endpoint / two test files to the Architecture table, added a
  "Submit flow and error mapping" section with the
  `NetworkError` → `ILSignUpError` table (including the 429
  `locked_until` / `retry_after_seconds` timing from `error.details`), and
  corrected the Summary: the server timing rides along to the OTP screen,
  and `phoneAlreadyRegistered` keeps the user on SignUp with an alert —
  it no longer navigates to Login, which the previous revision claimed.
- Rewrote the Pending work section: the remaining items are the manual
  real/staging verification, the unwired ToS/Privacy links (no real URLs
  provided — no placeholders invented), and the unconfirmed
  ordination-place copy/position.
- Still `draft` — the code is implemented and unit-tested, but the flow
  has not been exercised against a real/staging backend. Promote to
  `stable` once it has (same trigger as `Docs/Specs/SignUp`).
- `generated.at` refreshed; `generated.by` stays `claude-code`.
- Updated `index.md`: refreshed the `features/signup.md` status reason and
  corrected the `api/` "planned" line, which said endpoint concepts would
  be added "once real backend contracts exist" — the `request-otp`
  contract exists and is implemented, so what is actually missing is the
  concept.

## 2026-09-21 (2)

- Updated `features/signup.md` (`status: draft`) after the user confirmed
  that `phoneAlreadyRegistered` should redirect to Login. The spec
  (`Docs/Specs/SignUp/` v1.8) now matches the code, so the "Known gaps vs.
  spec" section was removed and the behavior moved into the Summary and
  "Known gaps vs. design" (the open question of whether the "phone
  already registered" message is shown after the redirect is kept there).
  Still `draft` for the same reasons as the entry below (stubbed
  `sendVerificationCode`; ordination-place copy pending the designer).

## 2026-09-21

- Updated `features/signup.md` (`status: draft`) after re-reading the
  SignUp code (`ILSignUpUseCase`, `ILSignUpEntity`, `ILSignUpStateModel`,
  `ILSignUpViewModel`, `ILSignUpViewController`, `ILEmailValidator`,
  tests). Email is now required (empty or badly formatted email blocks
  submit); the password minimum is 8 characters, up from 6; and the new
  optional ordination-place field ("Nơi xuất gia", the temple/monastery
  where a monastic was ordained) is documented in the summary,
  architecture table, field order and validation rules. Also added
  `ILEmailValidator` and the two test files to the Architecture table,
  and corrected the "stay on screen" claim: the code navigates to Login
  on `phoneAlreadyRegistered`.
- Marked `draft` because `sendVerificationCode` is still a `print("TODO")`
  stub (Phase 3 of `Docs/Specs/SignUp/tasks.md`), and because the
  ordination-place copy/position is awaiting the designer — promote to
  `stable` once the Auth API lands and the flow is verified against a
  real/staging backend.
- Flagged spec drift in `features/signup.md` ("Known gaps vs. spec"):
  the `phoneAlreadyRegistered` → Login navigation is not reflected in
  `Docs/Specs/SignUp/`. `Docs/Specs/` was not modified.
- `generated.by` changed from `copilot-cli` to `claude-code` since this
  revision was rewritten by `claude-code`. `index.md` row description
  refreshed.

## 2026-09-15 (2)

- Reviewed the Login screen (`Presentation/Scenes/Login/`, Domain
  Login entity/UseCase) and added `features/login.md` (`status: draft`).
  Documents ViewModel/Coordinator/State, navigation (incl. the
  Forgot Password push on the same nav stack), validation rules, and
  pending backend work (`login` is a stub, SMS-code login and guest
  preview are unwired TODOs). Marked `draft` for the same reason as
  SignUp — promote to `stable` once the Auth API lands and the flow is
  verified end-to-end.
- Linked `features/login.md` in `index.md`'s concept table.

## 2026-09-15

- Added `features/signup.md` (`status: draft`). Documents the SignUp
  feature (Presentation/Domain layers, navigation flow, validation
  rules) as implemented so far. Marked `draft` because backend API
  integration (`Docs/Specs/SignUp/tasks.md` Phase 3) is still pending —
  promote to `stable` once that lands and the end-to-end flow is
  verified against a real/staging backend.
- Created the bundle (`index.md`, `log.md`) as the first concept in
  `Docs/Knowledge/`.
