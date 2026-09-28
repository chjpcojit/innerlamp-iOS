---
type: Architecture Pattern
title: Logging Groups
description: The four independent logging/metrics channels — crash reports (Sentry), security alerts, metrics, and flow tracking — each with its own destination, trigger, and protocol, so none is used as a substitute for another.
resource: InnerLamp/Core/Logging/LoggingService.swift
tags: [architecture, logging]
status: stable
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Mobile Logging Architecture.md
    kind: spec
  - path: InnerLamp/Core/Logging/README.md
    kind: implementation-notes
  - path: InnerLamp/Core/Logging/LoggingService.swift
    kind: code
---

# Summary

InnerLamp logs and metrics through **four independent groups**, each answering a
different question with a different destination, trigger, and protocol. They are
not interchangeable — pick the right one for the purpose. Three of the four
destinations (security-alert, metrics, analytics) are **mocked** (`MockLogTransport`
prints to console in `#if DEBUG`); only Sentry (crash) is a real integration.

Feature code obtains each group through `DIContainer` via its protocol —
`LoggingService`, `SecurityAlertReporting`, `MetricsCollecting`, `FlowTracking` —
and never imports `Sentry` or the concrete reporters directly.

# The rule

Never import `Sentry`, `SecurityAlertReporter`, `MetricsCollector`, or
`FlowTracker` in feature code. Obtain them via `DIContainer` through their
protocols, and pick the group that matches the purpose (crash / security alert /
metrics / flow tracking). Every log must pass through `PIIMasker` — raw PII
(account numbers, real amounts, tokens) must never leave the app, and
categorical values must be chosen over raw values.

# Shape

| Group | Question | Destination | Trigger | Entry point (protocol / impl) |
|---|---|---|---|---|
| 1 — Crash Reports | Where/why did it crash? | Sentry (`sentry-cocoa`) | Next app launch | `LoggingService` / `SentryLoggingService` |
| 2 — Security Alerts | Are we under attack? | Risk server (**mock**) | Immediately, no buffer | `SecurityAlertReporting` / `SecurityAlertReporter` |
| 3 — Metrics | Is the app healthy? | Metrics server (**mock**) | Batch: 50 rec / 5 min / background / Wi-Fi | `MetricsCollecting` / `MetricsCollector` |
| 4 — Flow Tracking | Where/why did the user drop? | Analytics server (**mock**) | One payload at flow end | `FlowTracking` / `FlowTracker` |

## Key components

| File | Responsibility |
|---|---|
| `LoggingService.swift` / `SentryLoggingService.swift` | Group 1 — the only file that imports Sentry; auto-applies `PIIMasker` |
| `SecurityEvent.swift` / `SecurityAlertReporting.swift` / `SecurityAlertReporter.swift` | Group 2 — fixed vocabulary (jailbreak, debugger, frida, cert pinning, emulator) |
| `MetricsCollecting.swift` / `MetricsCollector.swift` | Group 3 — buffer + `NWPathMonitor` + `Timer` |
| `FlowModels.swift` / `FlowTracking.swift` / `FlowTracker.swift` | Group 4 — open-ended `FlowType` / `FlowStep`, accumulates steps in memory |
| `LogTransport.swift` / `MockLogTransport.swift` | Shared push interface for Groups 2/3/4 (mock impl) |
| `CorrelationContext.swift` | Owns `sessionId` / `correlationId`; `Endpoint` auto-injects the headers |
| `PIIMasker.swift` | Blocks `pin`/`password`/`token`/`email`/`phone`/… (see `blockedKeys`) |
| `UserContext.swift`, `DeviceTier.swift`, `LoggingConfig.swift`, `BreadcrumbCategory.swift`, `LogLevel.swift` | Supporting models/config |

# Canonical example

`Core/Networking/NetworkLogger.swift` is the canonical Group 1 consumer: it turns
one request into one `LoggingService` record (method, path, status, duration) and
routes credential-shaped data through `PIIMasker`. For Group 4, a feature
declares its own `FlowType` / `FlowStep` (e.g. `.onboarding` → `.selectIntents`)
and calls `startFlow` / `enterStep` / `completeStep` / `endFlow(outcome:)`.

# Common mistakes

- Using Group 3 (metrics) to record a security event, or Group 1 (crash) to track
  a business flow — the four groups have different destinations and retention.
- Logging raw `amount` instead of `PIIMasker.categorizeAmount(amount)` — the
  masker cannot infer business meaning from a number.
- Importing `Sentry` in a feature to emit a breadcrumb — use
  `container.loggingService.breadcrumb(...)`.

# Related concepts

- [Networking layer](networking.md) — `NetworkLogger` and `CorrelationContext`
  link request logs and headers into these groups.
- `PIIMaskerTests` (`InnerLampTests/PIIMaskerTests.swift`) — the mandatory test
  suite for any new PII format.
