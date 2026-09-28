# Changelog — Login Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.1 (2026-09-27)

- `requirements.md`: removed the incorrect ⚠️ "login API contract not
  confirmed" — the contract is confirmed in `Docs/Specs/API/openapi.yaml` v3.9
  (`POST /v1/auth/login`). The submit acceptance criterion now enumerates the
  confirmed failure branches (401 INVALID_CREDENTIALS incl. the 5-fail/15-min
  lock rule, 400 validation family, 429 LOGIN_LOCKED, 413, 500). "Pending" now
  states the contract is confirmed and names the two real gaps instead: the
  entity lacks the required `device` object, and `ILLoginError` only has
  `.invalidCredentials`. The ⚠️ moved to the SMS-code item, where it actually
  belongs (the `purpose` enum lists `login` but is documented as returning
  `UNSUPPORTED_OTP_PURPOSE`).
- `design.md`: added a "Login API contract (confirmed)" section with the
  route/request/success/failure table and the two Domain gaps; the
  "Deliberately stubbed for now" section is unchanged in substance but now
  correctly says "contract confirmed, Data layer not built".
- `tasks.md`: Phase 3 heading changed from "blocked on backend contract" to
  "contract confirmed, Data layer not built"; dropped the "confirm the
  contract" task and added concrete DTO/Mapper/Endpoint/Repository/error-mapping
  tasks grounded in the confirmed contract, plus an explicit `ILLoginEntity`
  `device` gap task.
- Reason: reading `Docs/Specs/API/openapi.yaml` v3.9 while writing the
  ForgotPassword spec revealed the login contract already exists — the v1.0
  "not confirmed" claim was wrong and would have misdirected Phase 3.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Login
  feature (UI + local validation + navigation done; the login network call is
  a one-line stub with no confirmed backend contract).
- `requirements.md`: user story (returning user signs in with phone +
  password, or continues as guest) and EARS acceptance criteria for load
  state, country picker, field-error clearing, submit validation, submit
  success/failure, double-submit guard, and the four navigation paths
  (back → Onboarding, create account → SignUp, forgot → ForgotPassword, guest
  → Main). "Pending" records the stubbed `login` call and the SMS-code TODO
  with a ⚠️ Not confirmed marker on the login API contract.
- `design.md`: Layers & components table naming the actual files (Entity,
  shared `ILAuthSessionEntity`, UseCase, Repository protocol with no Data impl,
  StateModel, ViewModel, Coordinator, ViewController, `ILDividerRow`), the
  navigation flow, the submit data flow, and a "Deliberately stubbed for now"
  section explaining why the login call is a stub and what's missing.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI and logic
  plus the 9 unit tests; Phase 3 (API integration) and Phase 4 (SMS-code
  login) pending, and Phase 5's OKF concept left `[ ]` until the API lands.
- Reason: Login was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
