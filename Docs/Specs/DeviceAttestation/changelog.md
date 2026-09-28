# Changelog — DeviceAttestation Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v1.2 (2026-09-23)

- `requirements.md`: no change needed, verified — behavior is unchanged; this version implements
  Phases 1–3 exactly as the spec described. Header `Status` synced to "in progress".
- `design.md`: no change needed, verified — implemented as written, including the
  § "Deliberately stubbed for now" contract: the three server ops are `// TODO` stubs that fail
  closed. Header `Status` synced to "in progress".
- `tasks.md`: Phase 1 (all 4 items) and Phase 2 (all 3 items) ticked. Phase 3 ticked for the
  `DIContainer` wiring, the App Attest environment entitlement, and the `deviceAttestation.bypass`
  flag; the "Keychain `keyId` survives app updates / wiped on reinstall" manual check left pending.
- Reason: `il-data-layer-builder` implemented the DeviceAttestation core service (Domain +
  Data + wiring + tests). Phase 4 (API integration) stays unticked — the backend contract is still
  blocked (`⚠️` in `requirements.md`), so no DTO/Mapper/Endpoint exists and `NetworkService` is
  deliberately **not** injected into the Repository yet; Phase 5 (OKF doc) is deferred per the spec.

## v1.1 (2026-09-23)

- Scope change: **dropped Part B (local root/jailbreak heuristics)**. After the user asked why
  folder detection was needed and it was confirmed (via Apple's docs and independent sources) that
  App Attest does **not** detect jailbreak — a jailbroken device is still a genuine Apple device and
  Apple exposes no jailbreak-status API — the user chose to protect against tampered/fake apps only.
  Jailbreak/root detection moved to "Out of scope".
- `requirements.md`: removed the Part B acceptance criteria and the two Part-B ⚠️ markers (indicator
  list; root-vs-jailbreak event cases). User story and scope clarification now describe App Attest
  only. Added "jailbreak/root detection" to Out of scope. Backend contract moved to "Open questions
  (resolved)" (envelope = shared `ApiResponse`, Apple-standard challenge/verify/assert, provisional
  paths) with one narrowed ⚠️ remaining for the concrete error-code vocabulary. Added a resolved
  entry for dropping Part B.
- `design.md`: removed the Part B Layers-table row and the "local detection" section; removed
  `SecurityAlertReporting` from the reused-Core table (no longer used). Step-by-step Flow, data
  shapes, error mapping, bypass/key/environment notes unchanged except the endpoint convention is
  now stated as confirmed (envelope) with provisional paths.
- `tasks.md`: removed the `ILJailbreakDetectionUseCase` items and its test from Phase 1 (phase
  count unchanged, still Phases 1–5); added jailbreak/root detection to "Deferred". Nothing else
  changed — no item checked off.
- Reason: resolving the jailbreak-detection question (the user asked why local folder detection is
  needed, learned App Attest doesn't cover it, and chose App Attest-only) removed a whole sub-feature
  and confirmed the backend convention — a real scope change, not a wording fix.

## v1.0 (initial)

- Initial spec written **prospectively** — the feature does not exist in code yet — as the work
  order for building the DeviceAttestation core service.
- `requirements.md`: user story + EARS acceptance criteria for Part A (App Attest server-verifiable
  proof) and Part B (local root/jailbreak heuristics), with scope clarification (App Attest proves
  app-instance integrity, not a literal jailbreak scan; the check is scoped to the app, not a
  device identity). Resolved questions recorded under "Open questions (resolved)": App Attest over
  DeviceCheck, background service (no UI), fail-closed, bypass flag for unsupported/Simulator,
  auto-re-attest on stale key, and per-app key scope. Open ⚠️ markers: backend contract, the exact
  root/jailbreak indicator list, and whether root vs jailbreak map to distinct `SecurityEvent`
  cases.
- `design.md`: Layers & components tables (Part A + Part B + reused Core services), the deferred
  invocation model, the Step-by-step Flow for both the attestation and assertion sequences (each
  2+ calls, so the section is mandatory), Apple-standard data shapes with ⚠️ endpoint contract,
  server-side verification responsibilities (out of scope, for the backend team), bypass/key
  persistence/environment notes, the `ILDeviceAttestationError` mapping, and a "Deliberately
  stubbed for now" section for the three server endpoints.
- `tasks.md`: five Phases (Domain, Data, Wiring & config, API integration [blocked on contract],
  Documentation) plus a Deferred section for the caller's invocation decision, blocking UI, and
  DeviceCheck fallback — all items `[ ]`, nothing implemented.
- Reason: initial work order for a new prospective feature, gathered from the user across two
  interview rounds (mechanism, UI, fail policy, unsupported-device behavior, re-attest, scope, and
  key scope).
