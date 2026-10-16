# Changelog — Onboarding Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v2.2 (2026-10-16)

_Later the same day: product spec cite raised to @ v1.6 (BR-ONB-08 amended, FR-ONB-003 +2 scenarios); criterion 16a wording confirmed by anh Đức; `AS-Onboarding-001` → Validated._

Aligned with innerlamp-be `docs/specs/api/openapi.yaml` `info.version` 2.1.1, product spec `onboarding`
@ v1.5 (matrix column only, no requirement changed) and backend onboarding spec v8.3. Docs only; no code
changed.

- `requirements.md`: header cites openapi 2.1.1 as the contract; new criterion 16a for
  `409 REGISTRATION_IN_PROGRESS` (wording ⚠️ Not confirmed → `AS-Onboarding-001`); criterion 14 notes
  that an existing email gets a notice mail and then `OTP_INVALID`; new criterion 29 (no web-only
  headers), unit-test criterion renumbered 30; Error → UI and Data & API rows updated (`INVALID_TEMPLE`
  from verify, `RATE_LIMITED` wait, `resend_remaining` unused).
- `design.md`: Registration flow adds `REGISTRATION_IN_PROGRESS`, the send-limit cycle and `INVALID_TEMPLE`
  at verify; the "stubbed" note now says the backend work is uncommitted and not yet run against a server.
- `tasks.md`: error mapping, header and verify-error items added; criterion reference 29 → 30.
- `Docs/Assumptions/Onboarding/AS-Onboarding-001-registration-in-progress-copy.md` added.

## v2.1 (2026-10-15)

- Docs clean-up done after the four platform specs were approved (Android merged 2026-10-15). Deleted:
  `Docs/Specs/{SignUp,Otp,Splash,ForgotPassword}/`, `Login/SRS.md`, `Onboarding/SRS.md`,
  `Docs/Knowledge/features/{signup,otp,login,forgot-password,onboarding,splash}.md`, `Docs/Knowledge/api/`
  (three `auth-*` concepts), `Docs/Assumptions/{SignUp,Splash}/`, `TD-SignUp-001`, `TD-SignUp-005`.
  Kept: `TD-SignUp-002/003/004`, `TD-Splash-001/002` (still true of the code; closed when it changes).
  Links to the deleted files (Knowledge, scene READMEs, code comments, the `spec-writer` / `okf-writer` /
  `data-builder` skills) now point to this folder or say the file is in git history.
- `tasks.md`: the clean-up item ticked. `requirements.md` / `design.md` unchanged apart from the version.

## v2.0 (2026-10-14)

Rewritten against the product spec innerlamp-be `docs/product/onboarding/product.md` @ v1.2 (ADR-0003
Accepted: email + email code, no SMS) and the backend onboarding spec v8.0. Docs only; no code changed.

- Scope widened from the intro alone to the whole first run and registration: splash, intro, SignUp,
  email code, temple proposal. Replaces `Docs/Specs/{Splash,SignUp,Otp}/` (deleted in the clean-up step).
- `requirements.md`: header `Product spec` / `Contract` / `Architecture` / `Implements`; criteria 1–29
  tagged with product IDs. Changes from the old specs: launch with the intro seen and no session opens
  Login (was SignUp); "Tôi đã có tài khoản" marks the intro seen; dharma name optional and empty;
  password 8–64 characters after NFC; phone sent as `phone_country` + typed digits; email is the
  identifier and an existing email looks like a new one; temple
  proposal sent (public route, live in the backend) after the account exists; code screen by email with a live countdown, lock state,
  "Đổi email", no voice-call banner; registration expired returns to the filled form.
- `design.md`: one layers table over the five scenes with a State column; Step-by-step Flow 1–6.
- `tasks.md`: Phases 1–7; `[x]` only where the code was read and still matches.
- Review (anh Đức, 2026-10-14): the terms part is left for later (bundled sheet kept, criterion 12);
  launch routing confirmed (first launch → intro → SignUp, later launches → Login).
- Hand-offs: product — BR-ONB-11 "one text" deferred on iOS (tell `ba-writer` when it is picked up). Backend — none.
- Reason: anh Đức dropped SMS (2026-10-14).

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Onboarding
  feature (full 3-step flow, local `UserDefaultsService` persistence, no
  network).
- `requirements.md`: user story and 9 EARS acceptance criteria covering first-
  launch routing, load state, step advancement/CTA labels, last-step
  completion, skip, back navigation, chip/bell toggles, swipe-to-change-step,
  and the completion flag. "Pending" is explicitly empty; one resolved open
  question records that preferences are local (no backend).
- `design.md`: Layers & components table (noting the architectural drift that
  `ILOnboardingStateModel` lives in `Domain/Entities/ILOnboardingModel.swift`
  rather than Presentation), navigation flow, step-progression data flow, and
  a "Local persistence (no network)" section enumerating the three
  `UserDefaultsService` keys. No Step-by-step Flow — there are no API calls.
- `tasks.md`: Phases 1–2 and Phase 4's README checked (`[x]`); Phase 3 marked
  "not applicable" (no network); the OKF concept left `[ ]` as a separate
  `il-okf-writer` task.
- Reason: Onboarding was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
