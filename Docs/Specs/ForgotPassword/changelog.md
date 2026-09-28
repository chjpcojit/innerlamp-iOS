# Changelog — ForgotPassword Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented
  ForgotPassword feature (UI + local validation + navigation done; the
  `sendResetInstructions` call is a one-line stub with no confirmed contract).
- `requirements.md`: user story (forgot-password user gets reset instructions
  via phone or email) and EARS acceptance criteria for load state, country
  picker, phone entry/validity, submit success (phone→OTP, email→reset event)
  / failure, double-submit guard, and back navigation. "Pending" records the
  stubbed `sendResetInstructions` and the empty `getInitialState()` with two
  ⚠️ markers (no reset endpoint in the OpenAPI file; whether to pre-fill the
  contact). Two resolved open questions (no phone/email switcher in shipped UI;
  phone path reuses the OTP screen as a stopgap).
- `design.md`: Layers & components table (Entity + `ILForgotPasswordMethod`,
  UseCase, StateModel, ViewModel, Coordinator, ViewController), navigation
  flow, submit data flow, a **Step-by-step Flow** (mandatory — the reset flow
  spans ForgotPassword and the OTP feature), and a "Deliberately stubbed for
  now" section. Notes the phone/email switcher from the design handoff is
  intentionally absent from the shipped UI.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI and logic
  plus the 11 unit tests; Phase 3 (API integration, blocked on the reset
  contract), Phase 4 (email reset + true reset OTP), and Phase 5's OKF concept
  left pending.
- Reason: ForgotPassword was one of the implemented features with no spec
  folder; written to close documentation debt, matching the
  `Docs/Specs/SignUp/` example.
