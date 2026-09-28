---
type: API Endpoint
title: POST /v1/auth/register/request-otp
description: Requests a registration OTP for a new account; the first half of the signup flow, called by the SignUp feature's requestVerificationCode submit.
resource: InnerLamp/Data/DataSources/Remote/RequestOTPEndpoint.swift
tags: [api, auth]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/API/openapi.yaml
    kind: openapi
  - path: Docs/Specs/SignUp/design.md
    kind: spec
  - path: InnerLamp/Data/DataSources/Remote/RequestOTPEndpoint.swift
    kind: code
  - path: InnerLamp/Data/DTOs/ILSignUpDTO.swift
    kind: code
---

# Summary

[Sign Up](../features/signup.md) calls this endpoint when the user taps "Gửi mã
xác thực" with a valid form. On success it returns the OTP delivery timing
(`expires_in_seconds` / `resend_after_seconds`), which SignUp carries to the
[OTP](../features/otp.md) screen to seed its countdown and expiry copy.

> ⚠️ **Contract status**: Confirmed against `Docs/Specs/API/openapi.yaml` v3.9
> (`RequestOTPRequest` / `RequestOTPData`). Not yet exercised against a
> real/staging backend.

The endpoint type is `RequestRegistrationOTPEndpoint` (a `nonisolated struct`
conforming to `Endpoint`); the file is named `RequestOTPEndpoint.swift` — the
`<Action>Endpoint` naming has no `IL` prefix, a deliberate exception to the
project's `IL` rule.

# Request

```
POST /v1/auth/register/request-otp
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `dharma_name` | String | yes | The user's chosen dharma name (from the fixed suggestion list) |
| `ordination_place` | String | no | Sent as an empty string when blank (trimmed otherwise) |
| `phone_number` | String | yes | Grouped, dial-code-prefixed display string (e.g. `+84 912 345 678`); server normalizes |
| `email` | String | yes | For donation receipts, not a login identifier |
| `password` | String | yes | Minimum 8 characters (registration rule) |

The body is encoded with a plain `JSONEncoder()` — no key strategy — so the
request DTO's explicit snake_case `CodingKeys` make the body match the contract.

**Headers**: none beyond `NetworkService`'s defaults (`Content-Type`,
`Accept`, `X-Session-ID`, `X-Correlation-ID`). `requiresAuth == false`
guarantees no `Authorization` header, regardless of Keychain state.

# Response

## Success

```json
{
  "success": true,
  "data": {
    "message": "...",
    "expires_in_seconds": 90,
    "resend_after_seconds": 60
  }
}
```

| Field | Type | Notes |
|---|---|---|
| `message` | String | Server's own human-readable note — kept but not displayed by the app |
| `expires_in_seconds` | Int | Seeds the OTP screen's code-expiry copy |
| `resend_after_seconds` | Int | Seeds the OTP screen's "Gửi lại" countdown |

Mapped by `ILSignUpMapper.toDomain` to `ILSignUpOTPEntity`.

## Error cases

| `error.code` | HTTP | Client mapping (`ILSignUpError`) |
|---|---|---|
| `PHONE_TAKEN` | 409 | `.phoneAlreadyRegistered` |
| `EMAIL_TAKEN` | 409 | `.emailTaken` |
| `OTP_LOCKED` | 429 | `.otpLocked(lockedUntil: details.locked_until)` |
| `OTP_SEND_LIMITED` | 429 | `.otpSendLimited(lockedUntil: details.locked_until)` |
| `OTP_RESEND_TOO_SOON` | 429 | `.otpResendTooSoon(retryAfterSeconds: details.retry_after_seconds)` |
| `SMS_SEND_FAILED` | 500 | `.smsSendFailed` |
| `VALIDATION_ERROR` / `INVALID_EMAIL` / `INVALID_PHONE` / `INVALID_PASSWORD` / `PAYLOAD_TOO_LARGE` | 400/413 | `.invalidInput` |
| transport (offline / timeout) | — | `.networkUnavailable` / `.timedOut` |
| anything else | — | `.server` |

# Call sites

| Layer | File | Notes |
|---|---|---|
| Endpoint | `Data/DataSources/Remote/RequestOTPEndpoint.swift` | `RequestRegistrationOTPEndpoint`, `requiresAuth = false` |
| Repository | `Data/Repositories/ILSignUpRepositoryImpl.swift` | `requestRegistrationOTP(_:)` maps `NetworkError` → `ILSignUpError` |
| UseCase | `Domain/UseCases/SignUp/ILSignUpUseCase.swift` | `sendVerificationCode(...)` returns `ILSignUpOTPEntity` |

# Related concepts

- [Sign Up](../features/signup.md) — the feature that calls this.
- [OTP Verification](../features/otp.md) — consumes the returned timing.
- [`verify-otp`](auth-verify-otp.md) / [`resend-otp`](auth-resend-otp.md) — the
  second half of the flow (verify) and its resend.
