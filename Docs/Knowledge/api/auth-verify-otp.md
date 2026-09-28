---
type: API Endpoint
title: POST /v1/auth/register/verify-otp
description: Verifies the 6-digit registration code and returns the account's first session (access + refresh tokens + user); the final step of registration, called by the OTP feature.
resource: InnerLamp/Data/DataSources/Remote/VerifyRegistrationOTPEndpoint.swift
tags: [api, auth]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/API/openapi.yaml
    kind: openapi
  - path: Docs/Specs/Otp/design.md
    kind: spec
  - path: InnerLamp/Data/DataSources/Remote/VerifyRegistrationOTPEndpoint.swift
    kind: code
  - path: InnerLamp/Data/DTOs/ILOtpDTO.swift
    kind: code
---

# Summary

[OTP Verification](../features/otp.md) calls this when the user taps "Xác nhận"
with a complete 6-digit code. On success (HTTP 201) it returns the account's
first session — `access_token`, `refresh_token`, and `user` — which
`ILOtpUseCaseImpl.verifyCode` persists to the Keychain and `ILUserRepository`
before navigating to the main app.

> ⚠️ **Contract status**: Confirmed against `Docs/Specs/API/openapi.yaml` v3.9
> (`VerifyOTPRequest` / `VerifyOTPData`). Not yet exercised against a
> real/staging backend.

# Request

```
POST /v1/auth/register/verify-otp
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `phone_number` | String | yes | The number the code was sent to |
| `otp_code` | String | yes | The 6-digit code |

Encoded with a plain `JSONEncoder()`; the DTO's explicit snake_case
`CodingKeys` map `phoneNumber` → `phone_number`, `otpCode` → `otp_code`.

**Headers**: none beyond `NetworkService` defaults. `requiresAuth == false`.

# Response

## Success (201)

```json
{
  "success": true,
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "user": {
      "id": 1,
      "email": "...",
      "phone_number": "...",
      "dharma_name": "...",
      "ordination_place": "..."
    }
  }
}
```

| Field | Type | Notes |
|---|---|---|
| `access_token` | String | Stored under `KeychainAuthTokenProviding.accessTokenKey` |
| `refresh_token` | String | Stored under `"refresh_token"` (consumed once the refresh flow exists) |
| `user.id` | Int64 | |
| `user.email` | String | |
| `user.phone_number` | String | |
| `user.dharma_name` | String? | Optional on the wire; mapped to `""` when absent |
| `user.ordination_place` | String? | Optional on the wire; mapped to `""` when absent |

Mapped by `ILOtpMapper.toDomain` to `ILAuthSessionEntity` (`ILUserEntity`).
`user.created_at` is deliberately not modeled.

## Error cases

| `error.code` | HTTP | Client mapping (`ILOtpError`, `.verify`) |
|---|---|---|
| `OTP_INVALID` | 400 | `.invalidCode` |
| `OTP_EXPIRED` | 400 | `.codeExpired` |
| `PENDING_REGISTRATION_EXPIRED` | 400 | `.registrationExpired` |
| `PHONE_TAKEN` / `EMAIL_TAKEN` | 409 | `.phoneTaken` / `.emailTaken` |
| `OTP_LOCKED` | 429 | `.otpLocked(lockedUntil: details.locked_until)` |
| `SMS_SEND_FAILED` | 500 | `.smsSendFailed` |
| `VALIDATION_ERROR` / `INVALID_EMAIL` / `INVALID_PHONE` / `INVALID_PASSWORD` / `PAYLOAD_TOO_LARGE` | 400/413 | `.invalidInput` |
| transport (offline / timeout) | — | `.networkUnavailable` / `.timedOut` |
| anything else | — | `.server` |

A storage failure after a successful verify (the account is already created)
surfaces as `ILOtpError.storageFailed` in the UseCase, not from this endpoint.

# Call sites

| Layer | File | Notes |
|---|---|---|
| Endpoint | `Data/DataSources/Remote/VerifyRegistrationOTPEndpoint.swift` | `requiresAuth = false` |
| Repository | `Data/Repositories/ILOtpRepositoryImpl.swift` | `verifyRegistrationOTP(phoneNumber:code:)` |
| UseCase | `Domain/UseCases/Otp/ILOtpUseCase.swift` | `verifyCode(phoneNumber:code:)` persists the session |

# Related concepts

- [OTP Verification](../features/otp.md) — the feature that calls this.
- [Sign Up](../features/signup.md) — the first half of the flow.
- [`request-otp`](auth-request-otp.md) / [`resend-otp`](auth-resend-otp.md) —
  the preceding request and the resend.
