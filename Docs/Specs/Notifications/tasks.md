# Tasks — Notifications

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first with mock data. Checked items reflect
> what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILNotificationsViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header, hero card (2 pills),
      "HÔM NAY" eyebrow, notification rows — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILNotificationsHeroCardView`,
      `ILNotificationRowView`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `notif`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILNotificationEntity` + `ILNotificationKind` +
      `ILNotificationUpcomingEntity`
- [x] Create `ILNotificationsStateModel` + `ILNotificationItemModel` +
      `ILNotificationsHeroModel`
- [x] Create `ILNotificationsUseCase` / `ILNotificationsUseCaseImpl` (mocks)
- [x] Create `ILNotificationsViewModel` (`Input -> Output`, `ILNotificationsNavEvent`,
      relative-time formatting, skipTonight)
- [x] Create `ILNotificationsCoordinator` (goBack pop+finish; openSetup TODO)
- [x] Wire `DIContainer.makeNotificationsUseCase/ViewModel/Coordinator`
- [x] Wire `ILProfileCoordinator` (`openNotifications` push)
- [x] Unit tests: `InnerLampTests/ILNotificationsViewModelTests.swift` (7 tests) —
      per-Input, state mapping, relative-time formatting

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the notifications / push / upcoming-session API contract(s)
> (see `requirements.md` Pending). Everything below is blocked until a contract
> exists.

- [ ] Define the notifications/push/upcoming-session API contract(s) with the
      backend team
- [ ] Create `ILNotificationsDTO` + `ILNotificationsMapper` (once confirmed)
- [ ] Create `NotificationsEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILNotificationsRepository` protocol + implementation wrapping
      `NetworkService` (+ push payload handling)
- [ ] Replace the mocks in `ILNotificationsUseCaseImpl` with real data
- [ ] Add mark-as-read flow
- [ ] Add `.failure` rendering
- [ ] Update `ILNotificationsViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — "Ngồi ngay" destination (pending; not blocked)

- [ ] Wire `.openSetup` → `showMeditationSetup()` (the MeditationSetup
      coordinator now exists — see the resolved open question in
      `requirements.md`)
- [ ] Update `InnerLamp/Presentation/Scenes/Notifications/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Notifications/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/notifications.md` (OKF concept) — hold off until
      the notifications API (Phase 3) lands. See `Docs/Specs/OKF.md`.
