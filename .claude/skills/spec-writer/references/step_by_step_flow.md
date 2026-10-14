# Step-by-step Flow in design.md

## Why this section exists

A one-sentence user story ("user registers with phone + password") cannot represent multi-call
flows accurately — it silently hides steps like "check the phone isn't already registered before
sending an OTP" or "verify the OTP before creating the account". Those hidden steps are exactly the
kind of detail that causes an AI (or a developer) to implement an incomplete or wrong flow, because
nothing in the spec ever named them explicitly.

The Step-by-step Flow section fixes this by forcing every sequential API/network call in the flow
to be written out individually, with its trigger, precondition, and both success and failure
branches — so nothing is assumed or invented later.

## When it is mandatory

Per `SKILL.md` rule 5: **whenever a user flow involves 2 or more sequential API/network calls**,
even if some of those calls are owned by a *different* feature (e.g. this feature sends a code, a
different screen then verifies it). If the flow has only one API call total, a full Step-by-step
Flow section is optional — the existing "Data flow" style single-paragraph description is enough.

## Required shape per step

```
Step N — <short name>
- Trigger: <what the user does, or what state causes this step to run>
- Pre-condition: <what must already be true — e.g. prior validation passed, a session is
  still valid>
- API: <METHOD> <path> (<key request fields>)
  <any known constraint or confirmed/unconfirmed detail about this call itself>
    - Success → <what happens, which step comes next>
    - Failure (<specific failure case>) → <what the user sees, where they end up>
    - Failure (<another failure case, if applicable>) → <...>
```

Steps belonging to a different feature than the one this spec is for must say so explicitly (e.g.
"Step 3 — Verify OTP (OTP feature, out of this feature's scope)") and should point to that other
feature's own `design.md` for its full detail rather than duplicating it.

## Worked example (from Docs/Specs/SignUp/design.md)

```
Step 1 — Submit SignUp form (this feature)
- Trigger: user taps "Gửi mã xác thực", local validation passes
- Pre-condition: displayName/phoneNumber/password pass useCase.validateXxx (client-side only)
- API: POST /auth/signup/send-code (displayName, phoneNumber E.164, password)
  Confirmed: the server checks phone existence as part of handling this same call and
  returns `phoneAlreadyRegistered` in its response — no separate check-phone call.
    - Success → emit .didRequestVerification(phoneNumber:), go to Step 2
    - Failure (phoneAlreadyRegistered) → set submitError, stay on SignUp screen, no navigation

Step 2 — Navigate to OTP screen (this feature, boundary)
- Trigger: Step 1 success
- Effect: forwards to the OTP feature's coordinator — this feature's responsibility ends here.

Step 3 — Verify OTP (OTP feature, out of this feature's scope)
- Trigger: user enters code, taps confirm
- Pre-condition: OTP session still valid (not expired / not over retry limit)
- API: POST /auth/otp/verify (otpSessionId, code) — contract owned by OTP feature
    - Success → Step 4
    - Failure (wrong code) → allow retry, show remaining attempts
    - Failure (expired) → offer "resend code", loops back to Step 1's send-code call
```

## How unconfirmed details show up here

If a step's exact contract or behavior isn't confirmed yet, mark it inline in that step (not just
in `requirements.md`), since this is the most specific location for a technical detail:

```
- API: POST /auth/signup/send-code (...)
  ⚠️ Not confirmed: whether "phone already registered" is part of this same response, or a
  separate "check phone exists" call happens before this step.
```

When the user answers it, update the step to state the confirmed behavior as fact (see the worked
example above, which shows the *resolved* version of exactly this question), and record the
resolution in `changelog.md` — including whether the answer changed the step count/structure or
just removed an uncertainty marker (both are valid outcomes; state which one happened).
