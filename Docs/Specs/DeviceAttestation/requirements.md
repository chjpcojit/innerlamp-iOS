# Requirements — DeviceAttestation

Version: 1.2
Last updated: 2026-09-23
Status: in progress — Phases 1–3 implemented (Domain, Data, wiring); Phase 4 (API) blocked on backend contract
Feature folder: `Domain/UseCases/DeviceAttestation/` (core service — no Presentation scene)

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written **prospectively** — the feature does not exist in code yet.

## User Story

As the InnerLamp operator (server / security team), I want every sensitive client action to be
backed by cryptographic proof — via Apple App Attest — that it comes from a genuine, untampered
app instance running on a genuine Apple device, so that I can reject requests from re-signed,
modified, or fake apps.

## Scope clarification (read first)

App Attest proves, cryptographically (Secure Enclave), that a specific app instance is genuine and
running on a genuine Apple device. The check is scoped to the **app**, not to a persistent device
identity: one key per app install, certified by Apple — as opposed to `DCDevice`/DeviceCheck, which
tracks a device identity.

App Attest does **not** detect jailbreak/root. A jailbroken device is still a genuine Apple device,
and a genuinely signed app on it still produces a valid attestation — Apple exposes no API that
reports jailbreak status. **Jailbreak/root detection is therefore explicitly out of scope for this
feature** (see "Out of scope"): this feature protects against tampered/fake apps, which is the
primary API-abuse vector.

This is a core, UI-less service. **When** it is invoked (app launch, per sensitive request, before a
specific action) is deliberately left to the caller and is out of scope for this spec.

## Acceptance Criteria (EARS notation)

- WHEN the app invokes `attestDevice()`, THE SYSTEM SHALL determine whether App Attest is supported
  on the device, and then either:
  - on a supported device: reuse the persisted, already-attested key, or generate and persist a new
    key and perform the full attestation (fetch challenge → attest → submit to server for
    verification), or
  - on an unsupported device with the bypass flag OFF: throw `ILDeviceAttestationError.unsupported`
    and SHALL NOT contact the server (fail-closed).
- WHEN `attestDevice()` completes, THE SYSTEM SHALL return an `ILDeviceAttestationEntity` reflecting
  `keyId`, `isAttested`, and `isSupported`.
- WHEN any step of attestation fails — key generation, the challenge fetch, Apple's attestation
  call, or the server's verification — THE SYSTEM SHALL throw the corresponding
  `ILDeviceAttestationError` and SHALL NOT mark the key as attested (fail-closed).
- WHEN the persisted `keyId` no longer matches a live Secure Enclave key (e.g. after an app
  reinstall or a factory reset, surfacing as `DCError.invalidKey`), THE SYSTEM SHALL discard the
  stale `keyId`, generate a new key, and re-attest automatically within the same `attestDevice()`
  call.
- WHEN the app invokes `generateAssertion(clientData:)`, THE SYSTEM SHALL load the persisted
  `keyId`, fetch a fresh one-time challenge from the server, and return a signed assertion over the
  SHA-256 hash of the client data; on any failure THE SYSTEM SHALL throw (fail-closed) rather than
  return an unverifiable assertion.
- WHEN the bypass flag is enabled, THE SYSTEM SHALL short-circuit `attestDevice()` to a synthetic
  success (`isAttested = true`, `isBypassed = true`) WITHOUT contacting Apple or the server, and
  `generateAssertion(...)` SHALL throw `ILDeviceAttestationError.bypassed` (there is no real key) —
  the caller is expected to skip attaching the assertion in this dev-only mode.
- WHEN Apple reports the attestation service temporarily unavailable (`DCError.serverUnavailable`),
  THE SYSTEM SHALL surface it as a retryable `ILDeviceAttestationError` rather than silently
  treating the key as attested.

## Out of scope (this feature boundary, not backend work)

- **Jailbreak/root detection** — App Attest does not provide it and Apple exposes no such API; local
  heuristic detection (folder/file/scheme checks) is a separate concern, deliberately deferred
  (possibly a future feature or a third-party RASP SDK).
- The decision of **when** to invoke `attestDevice()` / `generateAssertion(...)` (launch,
  per-request, per-action) — owned by the caller; this spec only provides the callable core.
- Server-side verification logic itself: validating the attestation certificate chain, the App ID
  hash, the nonce `SHA256(authData ‖ SHA256(challenge))`, the assertion signature/counter, and
  one-time-challenge replay protection. That is backend work; this spec only defines the *client*
  data fetched and sent.
- User-facing blocking UI (e.g. a "device blocked" screen) — there is none in this feature; callers
  render any such state.
- `DCDevice` (DeviceCheck) tokens — the chosen mechanism is App Attest; DeviceCheck is out of scope
  (kept as a possible future fallback only).

## Pending (not yet implemented)

- The entire feature (prospective). Tracked across `tasks.md` Phases 1–5.

> ⚠️ Not confirmed: exact error codes for the server's reject/verify responses (e.g.
> `ATTESTATION_INVALID`, `KEY_ALREADY_ATTESTED`, `CHALLENGE_EXPIRED`). The envelope + mechanism are
> confirmed (see below); the concrete error-code vocabulary is the backend team's to define. Does
> not block the client (the repository maps whatever `error.code` arrives).

## Open questions (resolved during implementation)

- ~~Backend contract: envelope, paths, mechanism?~~ → **Confirmed per proposal**: reuse the shared
  `ApiResponse` envelope, Apple-standard challenge/verify/assert data. Provisional paths
  `GET /v1/attestation/challenge`, `POST /v1/attestation/verify`, `GET /v1/assertion/challenge` —
  the user may rename these later. Only the concrete error codes remain TBD (see Pending). Resolved
  2026-09-23 (user).
- ~~Should the feature include local root/jailbreak heuristics (Part B)?~~ → **No — App Attest
  only.** After confirming App Attest does not detect jailbreak, the user chose to protect against
  tampered/fake apps only and treat jailbreak detection as out of scope. Part B (local heuristic
  detection) is dropped. Resolved 2026-09-23 (user).
- ~~Key scope: per-device, per-account-per-device, or per-app?~~ → **Per-app** — one App Attest key
  per app install (the natural App Attest model), scoped to the app instance, not a device identity
  (`DCDevice`/DeviceCheck) and not per-account. Resolved 2026-09-23 (user).
- ~~App Attest vs DeviceCheck?~~ → **App Attest** (`DCAppAttestService`), not `DCDevice` tokens.
  Resolved 2026-09-23 (user).
- ~~UI screen or background service?~~ → **Background core service, no UI.** No Coordinator /
  ViewController / ViewModel. Resolved 2026-09-23 (user).
- ~~Fail-open or fail-closed on failure?~~ → **Fail-closed**: any failure throws and the caller
  blocks the action. Resolved 2026-09-23 (user).
- ~~Behavior on unsupported devices (Simulator, iOS < 14)?~~ → **Unsupported = failed by default**;
  a `UserDefaults` bypass flag, when set `true`, makes the core skip the check for local/dev runs.
  Resolved 2026-09-23 (user).
- ~~Re-attest after reinstall / factory reset?~~ → **Auto-detect and re-attest**: a stale `keyId`
  (`.invalidKey`) is discarded and a new key is generated + attested in the same `attestDevice()`
  call. Resolved 2026-09-23 (user).
