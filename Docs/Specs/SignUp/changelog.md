# Changelog — SignUp Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md`
in this folder. All three files share one changelog since they change
together as one spec unit.

## v1.13 (2026-09-23)

- `requirements.md`: prose sync to the shipped call. The submit acceptance
  criterion's success branch now says the OTP screen also receives the
  server's `expires_in_seconds` / `resend_after_seconds`; a new criterion
  records that `phone_number` is sent as the grouped display string
  (`+84 912 345 678`), which the contract normalizes to E.164 server-side.
  The "Pending" section no longer claims the call is a stub — its one real
  item is now the manual real/staging backend verification. The OTP-timing
  ⚠️ and the `phone_number` shape moved to "Open questions (resolved)".
  The "Out of scope" bullet now points at `Docs/Specs/Otp/`.
- `design.md`: the Layers table lost every "(not yet created)" marker for
  `ILSignUpOTPEntity` / `ILSignUpRepository` / `ILSignUpRepositoryImpl` /
  `ILSignUpDTO` / `ILSignUpMapper` / `RequestRegistrationOTPEndpoint`, and
  the UseCase row no longer calls `sendVerificationCode` a stub. The
  navigation flow and submit data-flow now show the timing parameters.
  Step 2's ⚠️ is replaced by the confirmed fact (timing rides along), and
  Steps 3–4 are shortened to cross-references into `Docs/Specs/Otp/design.md`
  instead of duplicating tables owned by that spec. The "Deliberately
  stubbed for now" section is replaced by "API integration (implemented)",
  describing the real chain, the `ILSignUpError.from(_:)` mapping, the DI
  wiring, and the two test suites.
- `tasks.md`: Phase 2's `sendVerificationCode` line no longer reads
  "stub only" and its test line records the Phase 3 rework; Phase 3's
  heading drops "(pending, blocks feature completion)", its contract note
  no longer calls `phone_number` an E.164 string (the contract normalizes
  any accepted shape server-side), its failure-case list no longer claims
  only `.phoneAlreadyRegistered` exists, its `ILSignUpError.from` line
  uses the 4-field `apiError(code:message:type:details:)`, and its
  test-double line describes the repository mock instead of the old
  UseCase mock; the Phase 4 OKF item now says the blocking condition is
  cleared and the existing `Docs/Knowledge/features/signup.md` is stale
  (rewrite via `il-okf-writer`); the "Deferred" section became a
  cross-reference to `Docs/Specs/Otp/` (those items are implemented and
  tracked there, not pending for SignUp).
- Reason: v1.11/v1.12 deliberately touched headers/checkboxes only and left
  the prose describing a `print("TODO: …")` stub, a "not yet created" data
  layer, and an open timing ⚠️ — all false since the API integration landed.
  This version is that owed prose sync.

## v1.12 (2026-09-23)

- `requirements.md`: header only — Status notes the OTP timing ⚠️ is resolved and that only the
  manual real-backend test remains; no line of prose changed.
- `design.md`: header only — same Status change; no line of prose changed. The "Deliberately
  stubbed for now" section, the Step-2 ⚠️, and the `ILSignUpOTPEntity` "not yet created" row are
  now stale for the implemented call but were left untouched (prose belongs to `il-spec-writer`).
- `tasks.md`: the "Resolve the ⚠️ …" item ticked — the decision was **pass the timing through**:
  `ILSignUpOTPEntity` is created (`Domain/Entities/`), `sendVerificationCode` returns it instead
  of `Void`, and `.didRequestVerification` / `ILSignUpCoordinatorDelegate` /
  `AppCoordinator.showOtp` carry `otpExpiresInSeconds` + `resendAfterSeconds`. The manual
  real-backend test stays `[ ]`.
- Code: `ILSignUpMapper.toDomain`, `ILSignUpRepository.requestRegistrationOTP` and
  `ILSignUpUseCase.sendVerificationCode` now return `ILSignUpOTPEntity`; the ViewModel emits the
  timing; `ILSignUpViewModelTests` / `ILSignUpRepositoryTests` updated. `ILSignUpError` now uses
  the shared `ILUnlockTimeFormatter` instead of its own private copy.
- Reason: implementing the OTP feature (see `Docs/Specs/Otp/`) required the OTP screen to know
  the server's real `expires_in_seconds` / `resend_after_seconds`, and the user chose to use the
  server values rather than keep the hardcoded ones — which is exactly the decision this ⚠️ was
  holding open.

## v1.11 (2026-09-22)

- `requirements.md`: header only — Status moved from "integration still
  pending" to "API integration done, manual real-backend test pending"; no
  line of prose changed.
- `design.md`: header only — same Status change; no line of prose changed.
  Two prose passages are now stale for the implemented call but were left
  untouched, because prose belongs to `il-spec-writer`: the "Deliberately
  stubbed for now" section (the stub is gone) and the Step-2 ⚠️ about
  whether `expires_in_seconds`/`resend_after_seconds` ride along in
  `.didRequestVerification`.
- `tasks.md`: Phase 3 items ticked for the work that actually landed —
  request/response DTOs, `ILSignUpMapper`, `RequestRegistrationOTPEndpoint`,
  `ILSignUpRepository` + `ILSignUpRepositoryImpl`, the `ILSignUpError`
  extension + `ILSignUpError.from(NetworkError)`, repository injection into
  `ILSignUpUseCaseImpl`, `DIContainer` wiring, and the `MockILSignUpRepository`
  test rework. Two stay `[ ]`: resolving the `.didRequestVerification` timing
  ⚠️ — the call was implemented on the design's "keep `Void`" fallback, so
  the OTP-screen decision is still open — and the manual real/staging backend
  test.
- Code (SignUp): `sendVerificationCode(...)` is no longer a stub — it builds
  an `ILSignUpEntity`, maps it through `ILSignUpMapper`, and calls
  `POST /v1/auth/register/request-otp` (`requiresAuth = false`) through
  `ILSignUpRepositoryImpl`, which maps every `NetworkError` to an
  `ILSignUpError` case (reading `PHONE_TAKEN` / `EMAIL_TAKEN` / `OTP_LOCKED` /
  `OTP_SEND_LIMITED` / `OTP_RESEND_TOO_SOON` / `SMS_SEND_FAILED` from the
  envelope's `error.code`, with the 429 timing taken from `details`). New
  `signup.error.*` keys added to `vi.json`. Tests: `ILSignUpViewModelTests`
  reworked to inject `MockILSignUpRepository` into the real `ILSignUpUseCaseImpl`,
  plus a new `ILSignUpRepositoryTests` (error mapping, mapper, wire shapes);
  all SignUp and `NetworkService` tests pass. One pre-existing, unrelated
  failure remains in `ILSplashViewModelTests` (`handleSplashFinished` returns
  `.goToMain`, marked "TEMP DEBUG — revert") — not touched.
- Core (separate work, explicitly authorized by the user): `NetworkError.apiError`
  now carries the envelope's `details` (`[String: AnyCodable]?`) and
  `NetworkServiceImpl` forwards `envelope.details` on both the 2xx
  `success == false` and 4xx/5xx paths — required for the 429 lock/cooldown
  timing. `APIEnvelope.swift`'s `AnyCodable` gained `@unchecked Sendable`
  (immutable decoded JSON) and a `value` initializer, and `NetworkServiceTests`
  covers detail forwarding. **Owed:** `Docs/Specs/Networking/design.md` still
  documents `apiError(code:message:type:)` (3 fields) and Steps 4–5 without
  `details`, and `requirements.md` Pending still carries the already-resolved
  `details` ⚠️ — a Networking spec prose sync via `il-spec-writer`.
- Reason: the user asked `il-data-layer-builder` to build the SignUp APIs
  against the contract confirmed in `Docs/Specs/API/openapi.yaml` v3.9.

## v1.10 (2026-09-22)

- Resolved the ⚠️ open question carried since v1.6 about whether
  `openapi.yaml`'s `/auth/register/request-otp` differs from the
  `/auth/signup/send-code` name this spec assumed: the real registration
  contract is now documented from `Docs/Specs/API/openapi.yaml` v3.9.
- `requirements.md`: the submit criterion now names the actual call
  (`POST /v1/auth/register/request-otp`) and enumerates its confirmed
  failure branches (`409 PHONE_TAKEN` / `EMAIL_TAKEN`, `429 OTP_LOCKED` /
  `OTP_SEND_LIMITED` / `OTP_RESEND_TOO_SOON`, `500 SMS_SEND_FAILED` /
  `INTERNAL_ERROR`, `400`/`413`, transport) instead of the single generic
  failure line; added a criterion that a second tap while a submit is in
  flight is ignored. "Out of scope" clarifies that account creation is the
  follow-on `verify-otp` call, not a separate create-account endpoint.
  The Pending item now states the confirmed endpoint/fields and carries a
  new ⚠️ (whether the server's `expires_in_seconds` /
  `resend_after_seconds` are passed through to the OTP screen, whose copy
  hardcodes 10 phút / 60s — blocks the `.didRequestVerification` payload
  and whether a response Entity exists). Path-reconciliation question moved
  to "Open questions (resolved)"; the stale `send-code` wording in the
  phone-already-registered resolved entry was re-confirmed against v3.9.
- `design.md`: added the confirmed registration contract (route table:
  request-otp / verify-otp / resend-otp with request, success data, and
  confirmed failures; envelope + `error.code` discriminator). Rewrote the
  Step-by-step Flow from the old speculative `send-code → otp-verify →
  create-account` to the confirmed two-call flow where `verify-otp`
  creates the account — Steps 3–4 now spell out every branch and note the
  OTP feature has no spec folder yet. Added the Data-layer rows (DTOs,
  Mapper, `RequestRegistrationOTPEndpoint` under `Data/DataSources/Remote/`,
  `ILSignUpRepository` / `ILSignUpRepositoryImpl`, optional
  `ILSignUpOTPEntity`) and corrected the endpoint placement away from
  `Core/Networking/`. Rewrote "Deliberately stubbed for now" to the
  concrete Phase 3 plan.
- `tasks.md`: Phase 3 replaced with concrete, contract-grounded items
  (DTOs, Mapper, correctly-placed Endpoint, Repository, `ILSignUpError`
  extension + `from(NetworkError)`, DI wiring, mock-repository tests);
  removed the now-resolved "reconcile the contract" task. The Deferred
  section now lists the OTP feature's `verify-otp` / `resend-otp`
  integration (previously a one-line "account creation" note), flagged as
  not owned by SignUp and having no spec folder yet.
- Reason: the user asked for the registration integration documentation
  based on `Docs/Specs/API/openapi.yaml`, and the OpenAPI file (v3.9,
  up from the v3.2 the spec referenced) confirms the previously-flagged
  path/fields and reveals the flow is two calls, not three. No code was
  changed — this is a spec-only update; Phase 3 remains `[ ]` pending.

## v1.9 (2026-09-21)

- `requirements.md`: the submit criterion reverts to a single failure
  branch — **any** failure, including "phone already registered", shows
  an error alert and stays on the SignUp screen so the user can fix the
  phone number in place. Removed the v1.8 Login-redirect branch and the
  `⚠️ Not confirmed` about whether the message is visible after the
  redirect (moot once nothing is replaced). The "stay or go to Login?"
  entry in "Open questions (resolved)" was rewritten to record **stay on
  SignUp** and note that it supersedes the v1.8 answer.
- `design.md`: Navigation flow diagram and Data flow (submit) drop the
  second route to Login; Step 1's failure branch is back to a single
  "set `submitError`, stay, no navigation" line. The code comment in
  `ILSignUpViewModel.handleSubmit` now states the same.
- `tasks.md`: no change needed, verified — the redirect was never a task
  item and Phase 3's error-mapping item is unaffected; only the version
  header bumped.
- Code: `ILSignUpViewModel` no longer emits `.goToLogin` from the
  `catch` block (`.goToLogin` still exists for "Tôi đã có tài khoản");
  `test_submitTapped_whenPhoneAlreadyRegistered_navigatesToLogin` renamed
  to `..._showsErrorAndStaysOnScreen` and now asserts `submitError` is
  set, `isSubmitting == false`, and no nav event fires. Verified with a
  simulator run of `ILSignUpViewModelTests` — 22 tests, all passing.
- Reason: user decision reversing v1.8 — "vậy thôi chỉ cần hiện thông
  báo lỗi số điện thoại đã đăng ký cho đơn giản" (just show the
  phone-already-registered error message).

## v1.8 (2026-09-21)

- `requirements.md`: the "phone already registered" branch of the submit
  criterion now says the user is navigated to **Login** (SignUp
  finishes), not "alert and stay on SignUp"; other failures still show
  an alert and stay. Moved the "stay or go to Login?" question to "Open
  questions (resolved)". Added a `⚠️ Not confirmed`: whether the "phone
  already registered" message must be visible after the redirect (the
  ViewModel sets `submitError`, but the screen is replaced right after).
- `design.md`: Data flow (submit) and Step 1 of the Step-by-step Flow
  now show `phoneAlreadyRegistered` → `.goToLogin` →
  `AppCoordinator.showLogin()`, with other failures unchanged; the
  Navigation flow diagram lists the second route to Login. The
  Step-by-step Flow itself is unchanged in shape (same single call).
- `tasks.md`: no change needed, verified — the redirect is already
  implemented and tested (`ILSignUpViewModelTests`, 22 tests), and
  Phase 3's error-mapping item is unaffected; only the version header
  bumped.
- Reason: the spec had drifted from the code, which already redirects to
  Login on `phoneAlreadyRegistered`; found while updating the OKF concept
  and confirmed by the user as the intended behavior.

## v1.7 (2026-09-21)

- `requirements.md`: the "Nơi xuất gia" `⚠️ Not confirmed` marker is
  narrowed — meaning (place of ordination: temple / monastery, "chùa /
  tịnh xá") and optionality are confirmed by the user and moved to
  "Open questions (resolved)". Still open: final copy and position (the
  design handoff has no such field). The audience part of the old marker
  is dropped: the field is optional and shown to everyone, as built.
- `design.md`: "Ordination place field" section records the
  confirmation and narrows its `⚠️` to copy/position. No structural
  change needed, verified — the implementation already matched.
- `tasks.md`: no change needed, verified — no item added, removed or
  re-checked; only the version header bumped.
- Reason: user confirmed the field's meaning and that it is optional,
  after being asked while checking the v1.6 spec against the code.

## v1.6 (2026-09-21)

- `requirements.md`: User Story and acceptance criteria updated —
  email is now **required** (empty → "Vui lòng nhập email", bad format
  → "Email chưa đúng định dạng", both block submit; this reverses v1.5's
  "optional, never blocks submit"); password minimum length is now **8**
  (was 6); new optional **ordination place** ("Nơi xuất gia") field
  added with a `⚠️ Not confirmed` marker since the design handoff has no
  such field (copy/position/audience unconfirmed). Two questions moved to
  "Open questions (resolved)": email required, min password length 8
  (both 2026-09-21, user request; both also match
  `Docs/Specs/API/openapi.yaml`).
- `design.md`: `ILSignUpEntity` row now lists `ordinationPlace` and
  required `email`; UseCase row lists `validateEmail`, min-8 rule and the
  new `sendVerificationCode` signature; new `Domain/Validation/ILEmailValidator.swift`
  row (single email regex, extracted so `validateEmail` and
  `ILSignUpStateModel.isEmailFormatValid` no longer carry separate copies); submit data flow updated; "Email field" section rewritten
  as required; new "Ordination place field" and "Password rule" sections
  (the latter records that Login stays non-empty-only and ForgotPassword
  has no password/email input, so neither changed); Step 1 payload
  updated, plus a `⚠️ Not confirmed` about `openapi.yaml`'s
  `/auth/register/request-otp` path/snake_case fields differing from the
  `/auth/signup/send-code` name used here.
- `tasks.md`: Phase 1/2 items updated for the new field, required email,
  `validateEmail` and `ILEmailValidator` (done, `[x]`); test count 15 → 22
  (`ILSignUpViewModelTests`) plus 3 new `ILEmailValidatorTests`; Phase 3
  contract item reworded to reconcile with `openapi.yaml` and include the
  new fields. No new Phase, no items un-checked — `sendVerificationCode`
  is still a stub, so Phase 3 stays pending.
- Code: `ILSignUpEntity.ordinationPlace`, `ILSignUpStateModel.ordinationPlace`/
  `emailError`, `ILSignUpUseCase.validateEmail` +
  `minimumPasswordLength = 8`, `ILSignUpViewModel.handleOrdinationPlaceChanged`
  and email validation in `handleSubmit`, `ordinationPlaceField` in
  `ILSignUpViewController`, `signup.field.ordinationPlace.*` /
  `signup.error.emailRequired` keys and updated password strings in
  `vi.json`, `ILEmailValidator`. Verified with a simulator test run of
  `ILSignUpViewModelTests` + `ILEmailValidatorTests`.
- Reason: user requested email to be mandatory and password min length 8
  and asked for the ordination place field; the OpenAPI contract already
  required both. Login/ForgotPassword have no `Docs/Specs/` folder, so no
  spec exists to update for them.

## v1.5 (2026-09-18)

- Re-audited the implemented SignUp screen against
  `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
  (block `isSignup`) per a user request to check the design handoff and
  update the UI code. Found the design's **Email** field (optional, for
  donation receipts — also documented in the design handoff's own
  top-level `README.md` under screen `signup`) was completely absent
  from `requirements.md`/`design.md` and from the implementation.
- `requirements.md`: User Story updated to mention the optional email;
  added one acceptance criterion for its live, non-blocking format
  validation.
- `design.md`: added `email` to the `ILSignUpEntity` row and to Step 1's
  API payload description; added a new "Email field (optional, added
  v1.5)" section explaining it never blocks submit (matches `signupNext`
  in the design handoff — gated only on the terms checkbox).
- `tasks.md`: Phase 1/2 checklist items updated to mention the email
  field; test count 13 → 15.
- Code: `ILSignUpEntity.email`, `ILSignUpStateModel.email`/
  `hasEmailValue`/`isEmailFormatValid`, `emailField` in
  `ILSignUpViewController` (between phone and password, matching design
  order), `ILSignUpViewModel.handleEmailChanged`, `email` parameter
  added to `ILSignUpUseCase.sendVerificationCode`. 2 new tests in
  `ILSignUpViewModelTests`. Verified with a build + full test run on
  simulator, plus a screenshot comparison against the design.
- Reason: this was a real, silent design/implementation drift — not
  flagged anywhere as a pending/⚠️ item — likely lost when an earlier
  email+password auth prototype was ripped out in favor of phone+OTP
  (see `Presentation/Scenes/SignUp/README.md` intro), taking the
  unrelated *optional* email field with it by accident.

## v1.4 (2026-09-15)

- Resolved the ⚠️ open question from v1.1 on `send-code` API shape:
  confirmed by user that the server checks phone existence as part of
  the **same** `send-code` call and returns `phoneAlreadyRegistered` in
  its response — there is **no separate "check phone exists" API**.
- `requirements.md`: moved this from Pending/⚠️ to "Open questions
  (resolved)".
- `design.md`: Step 1 of the Step-by-step Flow updated to state this as
  confirmed fact instead of an open assumption — no structural change
  to the flow itself (it was already modeled as one call), just removed
  the uncertainty marker.
- `tasks.md` Phase 3: removed the now-resolved "confirm with backend"
  task; the endpoint-contract task note now states the confirmed
  behavior inline.
- Remaining open item: exact ToS/Privacy URL values (see v1.3), still
  unresolved.
- Reason: demonstrates resolving an open question that turns out to
  *not* change the design (the flow was already correctly modeled) —
  contrast with v1.3, where resolving a question did simplify the
  design. Not every answered ⚠️ requires a structural change, but the
  spec must still record that it was explicitly confirmed rather than
  left as an unstated assumption.

## v1.3 (2026-09-15)

- Resolved the ⚠️ open question from v1.2 on ToS/Privacy content
  source: confirmed by user as a **public URL loaded in a web view**
  (`WKWebView`), not bundled static text and not a custom backend/CMS
  API — moved to "Open questions (resolved)" in `requirements.md`.
- `requirements.md`: added 2 new acceptance criteria (content loads from
  a public URL; error/retry state on load failure / no connection).
  Added a new, narrower ⚠️ follow-up question: the actual URL string
  values themselves are still not provided.
- `design.md`: simplified the Terms of Service / Privacy Policy screen
  design now that content source is known — dropped the previously
  speculative `ILLegalContentType` enum in favor of a plain URL
  parameter; confirmed **no Domain/UseCase/Repository layer is needed**
  since it's pure Presentation (`WKWebView` wrapper).
- `tasks.md` Phase 5: replaced the "resolve content source" task (now
  done) with "get real URL values" as the new blocking task; added
  loading/error state and WebView wrapping to the
  `ILLegalContentViewController` task.
- Reason: demonstrates resolving one open question can immediately
  simplify the design (removed a layer/enum that's no longer needed)
  while still surfacing a new, more specific open question (concrete
  URLs) rather than silently assuming placeholder values.

## v1.2 (2026-09-15)

- Scope change: Terms of Service / Privacy Policy links, previously
  listed under "Out of scope" (v1.0), are now **in-scope** per new
  requirement — tapping either link must present a screen with the
  corresponding content.
- `requirements.md`: removed the item from "Out of scope"; added 3 new
  EARS acceptance criteria; added an unresolved ⚠️ question on content
  source (static vs CMS/API-fetched), since this determines whether a
  Domain/Repository layer is needed.
- `design.md`: added a new "Terms of Service / Privacy Policy screen"
  section describing the (not yet implemented) navigation branch —
  `ILLegalContentViewController` under `Presentation/Common/` (shared,
  reusable by other auth screens), plus required modification to
  `ILCheckboxRow` to expose tap targets. Added corresponding rows to the
  Layers & components table, explicitly marked "not yet created" /
  "needs modification".
- `tasks.md`: removed the item from "Deferred", added new **Phase 5**
  with all items unchecked (`[ ]`) — this is planned work, not done.
  Phase 5 is blocked on resolving the content-source open question
  first.
- Reason: demonstrates how a requirement change cascades through
  `requirements.md` → `design.md` → `tasks.md` in that order, and that
  newly-scoped work is recorded as pending, never marked complete
  ahead of actual implementation.

## v1.1 (2026-09-15)

- Added `Version` / `Last updated` header to all three spec files.
- `design.md`: added **Step-by-step Flow — Full Registration** section,
  spelling out the SignUp → OTP sequence (send-code → navigate → verify
  OTP → create account) as explicit steps with trigger/pre-condition/
  API/success-failure branches, instead of leaving it implied by the
  high-level user story. Flags an open question (⚠️) on whether
  "phone already registered" is returned by the same `send-code`
  endpoint or requires a separate check-phone call.
- `requirements.md`: added the same ⚠️ open question to the Pending
  section, cross-referenced with `design.md`.
- `tasks.md` Phase 3: added a task to resolve that open question with
  the backend team before implementing the endpoint/repository.
- Reason: adopted a new project-wide convention (see discussion in
  `Docs/Specs/OKF.md`-adjacent session) requiring specs to (1) version
  and log changes explicitly, and (2) break multi-API flows into an
  explicit step-by-step sequence in `design.md` rather than a single
  vague sentence, so implementers/AI agents don't have to infer hidden
  steps (e.g. phone-exists checks, OTP verification ordering).

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented
  SignUp feature (UI + local logic done, API integration stubbed), as a
  worked example of the requirements/design/tasks format — see
  `Docs/Specs/OKF.md`.
