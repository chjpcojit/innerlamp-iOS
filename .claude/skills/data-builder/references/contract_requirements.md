# What Counts as a Confirmed Contract

**Read this first. This skill's single biggest failure mode is inventing a plausible-looking API
and writing code against it.**

`ui-builder` deliberately refuses to guess network calls and leaves a
`print("TODO: ...")` stub. That refusal is only worth anything if the skill that *does* implement
the call holds the same line — otherwise the guess just moves one layer down and now has tests
around it, which makes it look verified.

## The bar

A contract is confirmed when all six of these are true. Anything less is a **stop**.

| # | Item | Example (a confirmed one) | Example of a non-confirmation |
|---|---|---|---|
| 1 | HTTP method + full path | `POST /auth/signup/send-code` | "the signup endpoint", "something like /auth/register" |
| 2 | Request body field names **and** types | `displayName: String`, `phoneNumber: String` (E.164), `password: String` | "sends the form data" |
| 3 | Success response shape | `202`, body `{ "otpSessionId": "..." }` | "returns ok" |
| 4 | Every named failure case, with the discriminator the server uses | `409` + `{ "code": "PHONE_ALREADY_REGISTERED" }` → `phoneAlreadyRegistered` | "returns an error if the phone exists" |
| 5 | Auth requirements | `Authorization: Bearer <token>` required, or explicitly public | unstated |
| 6 | Encoding quirks | snake_case body, ISO-8601 dates | unstated |

A contract the user pasted from a Swagger/OpenAPI export, a backend teammate's message, or an
already-working call elsewhere in the codebase all count. A contract you inferred from field
names on the Entity does **not**.

## Where to read it

`Docs/Specs/<Feature>/design.md` — in this order:

1. The **Step-by-step Flow** section (`references/step_by_step_flow.md` in `spec-writer`) — this
   is where per-step `API:` lines live, each naming method + path + success/failure branches.
2. The **Deliberately stubbed for now** section — names what is *not* yet real and why.
3. `requirements.md`'s **Pending** section — the canonical `⚠️ Not confirmed` markers.

## Stop conditions — report, do not code

Stop and report if any holds:

- No `Docs/Specs/<Feature>/` folder exists. (Run `spec-writer` first — say so.)
- `design.md` has no Step-by-step Flow / Data flow naming a real endpoint for the stubbed method.
- Any of the six rows above is missing or hedged. Quote the line you're missing in your report.
- A `⚠️ Not confirmed` marker covers the contract you'd be implementing.
- **No host to point `baseURL` at** — see "Host configuration" below.
- The contract needs a request field the Entity doesn't have, or the response carries a business
  field the Entity lacks → this is a Domain change (`ui-builder`'s layer), not something to
  quietly widen here.
- The ViewModel switches on an `IL<Feature>Error` case whose behaviour would have to change →
  that's a `design.md` + ViewModel change, so hand back to `spec-writer`/`ui-builder`.

## Worked example — SignUp Phase 3 is a stop, not a green light

From the former `Docs/Specs/SignUp/tasks.md` Phase 3 (in git history), the task *"Define `POST /auth/signup/send-code` (or
equivalent) contract with backend team"* is **unchecked**, and `design.md` carries
```
⚠️ Chưa xác nhận: the actual URL string values for ToS/Privacy
```

So `sendVerificationCode` is **not ready**. The `(or equivalent)` wording is itself the tell: the
path is a placeholder. The right move is to say exactly that, not to implement
`POST /auth/signup/send-code` because the string happens to be spelled out.

Contrast — the *same* spec's confirmed half: `design.md` Step 1 states as confirmed fact
(2026-09-15) that the server checks phone existence inside the `send-code` call and returns
`phoneAlreadyRegistered` in that response, with no separate pre-check call. That half **is**
implementable. When part of a contract is confirmed and part isn't, implement only the confirmed
part and report the rest — never fill the gap by extrapolation.

## What to say when stopping

Short and concrete — name the file, name the missing field, name what it blocks:

```
Chưa implement được: contract chưa confirmed.
- Thiếu: response shape của POST /auth/signup/send-code (chỉ có request).
- Nguồn: Docs/Specs/SignUp/design.md cũ (git history) Step 1 — "Success → emit .didRequestVerification"
  không nói body trả gì.
- Cần: chạy spec-writer để chốt contract, hoặc bạn cho tôi response thật.
Không viết DTO/Endpoint nào cho tới lúc đó.
```
