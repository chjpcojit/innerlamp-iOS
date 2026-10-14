---
type: API Endpoint
title: POST /v1/auth/resend-otp
description: Reissues a registration OTP and returns fresh delivery timing; the OTP screen's "Gửi lại" action (purpose = "register"), a shared endpoint the server scopes by purpose.
resource: InnerLamp/Data/DataSources/Remote/ResendOTPEndpoint.swift
tags: [api, auth]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: innerlamp-be/docs/specs/api/openapi.yaml
    kind: openapi
  - path: Docs/Specs/Otp/design.md
    kind: spec
  - path: InnerLamp/Data/DataSources/Remote/ResendOTPEndpoint.swift
    kind: code
  - path: InnerLamp/Data/DTOs/ILOtpDTO.swift
    kind: code
---

# Summary

[OTP Verification](../features/otp.md) calls this when the user taps "Gửi lại"
after the cooldown. It reissues a registration OTP and returns new delivery
timing, which reseeds the screen's countdown and expiry copy. The endpoint is
**shared on the backend** — `purpose` selects the flow — but the OTP feature only
ever sends `purpose = "register"` (US-001).

> ⚠️ **Contract status**: Confirmed against `Docs/Specs/API/openapi.yaml` v3.9
> (`ResendOTPRequest` / `ResendOTPData`). Not yet exercised against a
> real/staging backend.

The voice-call banner does **not** reach this endpoint: the confirmed request has
no channel field, so `ILOtpUseCaseImpl.resendCode(channel: .voiceCall)` throws
`.voiceCallUnsupported` before any network call.

# Request

```
POST /v1/auth/resend-otp
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `phone_number` | String | yes | The number the code was sent to |
| `purpose` | String | yes | Always `"register"` for this feature |

Encoded with a plain `JSONEncoder()`; the DTO's explicit snake_case
`CodingKeys` map `phoneNumber` → `phone_number`.

**Headers**: none beyond `NetworkService` defaults. `requiresAuth == false`.

# Response

## Success (200)

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
| `message` | String | Server note (kept, not displayed) |
| `expires_in_seconds` | Int | Reseeds the code-expiry copy |
| `resend_after_seconds` | Int | Reseeds the countdown |

Mapped by `ILOtpMapper.toDomain` to `ILOtpTimingEntity`.

> Note (drift): `Docs/Specs/API/openapi.yaml` v3.9 also lists a `resend_remaining`
> field in the success data; `ILOtpResendResponseDTO` does not model it (only the
> three fields above), so it is not surfaced to the app.

## Error cases

| `error.code` | HTTP | Client mapping (`ILOtpError`, `.resend`) |
|---|---|---|
| `OTP_INVALID` | 400 | `.registrationExpired` (on resend this means "no pending registration") |
| `PENDING_REGISTRATION_EXPIRED` | 400 | `.registrationExpired` |
| `OTP_RESEND_TOO_SOON` | 429 | `.resendTooSoon(retryAfterSeconds: details.retry_after_seconds)` |
| `OTP_LOCKED` | 429 | `.otpLocked(lockedUntil: details.locked_until)` |
| `OTP_SEND_LIMITED` | 429 | `.sendLimited(lockedUntil: details.locked_until)` |
| `SMS_SEND_FAILED` | 500 | `.smsSendFailed` |
| transport (offline / timeout) | — | `.networkUnavailable` / `.timedOut` |
| anything else | — | `.server` |

# Call sites

| Layer | File | Notes |
|---|---|---|
| Endpoint | `Data/DataSources/Remote/ResendOTPEndpoint.swift` | `requiresAuth = false` |
| Repository | `Data/Repositories/ILOtpRepositoryImpl.swift` | `resendRegistrationOTP(phoneNumber:)` |
| UseCase | `Domain/UseCases/Otp/ILOtpUseCase.swift` | `resendCode(phoneNumber:channel:)` |

# Related concepts

- [OTP Verification](../features/otp.md) — the feature that calls this.
- [`request-otp`](auth-request-otp.md) / [`verify-otp`](auth-verify-otp.md) — the
  rest of the registration flow.
- [Forgot Password](../features/forgot-password.md) — would reuse `purpose =
  "reset_password"` once the server supports it (currently
  `UNSUPPORTED_OTP_PURPOSE`).
