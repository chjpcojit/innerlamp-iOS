# Requirements — Settings

Version: 1.1
Last updated: 2026-10-10
Status: in-progress — full settings UI with mock data; toggles are in-memory
only, and all sub-destinations (except Edit Profile) are not built; a new
"Hỗ trợ & pháp lý" section is specified but not yet built
Feature folder: `InnerLamp/Presentation/Scenes/Settings/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Settings
> feature. It documents the shipped behavior, including the mock data, the
> in-memory toggles, and the unimplemented destinations.

## User Story

As a signed-in user, I want to manage my account, bell/fast-day reminders, font
scale, dark mode, downloads, language, help, and privacy, so that I can
personalize the app.

## Acceptance Criteria (EARS notation)

- WHEN the Settings screen loads, THE SYSTEM SHALL show an account card (avatar,
  name, "Pháp danh … · SĐT"), then four grouped sections — Thời khóa (bell
  switch, fast-day switch, bell sound), Hiển thị & ngôn ngữ (font scale,
  bilingual switch, dark-mode value), Nội dung & trợ giúp (downloads / language
  / help), Riêng tư (hide-journal switch, export data) — and a footer (version +
  legal + offline link).
- WHEN the user toggles a switch (bell, fast-day, bilingual, hide-journal), THE
  SYSTEM SHALL update the in-memory state and reflect the new value.
- WHEN the user changes the font scale, THE SYSTEM SHALL update the in-memory
  font-scale value.
- WHEN the user taps the account card, THE SYSTEM SHALL open the EditProfile
  screen.
- WHEN the user taps "Tiếng chuông", "Chế độ tối", "Nghe không cần mạng",
  "Ngôn ngữ & hiển thị", "Trợ giúp & câu hỏi thường gặp", "Tải dữ liệu tu tập
  của tôi", or the offline-status link, THE SYSTEM SHALL emit the corresponding
  navigation event.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Settings
  screen and return to Profile.
- WHEN the Settings screen loads, THE SYSTEM SHALL show a "Hỗ trợ & pháp lý"
  section with three rows — "Liên hệ hỗ trợ" (sub "Email, hotline, Zalo · gửi
  yêu cầu"), "Điều khoản sử dụng", "Chính sách quyền riêng tư" — below
  "Nội dung & trợ giúp". (added v1.1)
- WHEN the user taps "Liên hệ hỗ trợ", THE SYSTEM SHALL open the Contact Support
  screen; WHEN the user taps "Điều khoản sử dụng" or "Chính sách quyền riêng
  tư", THE SYSTEM SHALL open the Legal screen on the matching document.
  (added v1.1; screens specified in `Docs/Specs/ContactSupport/` and
  `Docs/Specs/Legal/`)
- WHEN the user taps "Trợ giúp & câu hỏi thường gặp", THE SYSTEM SHALL open the
  Help screen (`Docs/Specs/Help/`). (clarified v1.1 — the event already existed)

  > ⚠️ Not confirmed: whether the existing footer legal line ("settings.footer.
  > legal") should become tappable or stay plain text once these rows exist —
  > left as plain text.

## Out of scope (this feature boundary, not backend work)

- The EditProfile screen (`.openProfile` is wired to `ILEditProfileCoordinator`).
- The Help, Contact Support and Legal screens themselves (own specs).

## Pending (not yet implemented — see `tasks.md`)

- A real settings persistence/API. `ILSettingsUseCaseImpl.getSettings()` returns
  static mock data with a TODO to replace with `ILSettingsRepository`
  (UserDefaults/network). (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the settings persistence/API contract — no settings
  > endpoint in `Docs/Specs/API/openapi.yaml` v3.9; whether toggles persist
  > locally (UserDefaults) or remotely. Blocks `tasks.md` Phase 3.

- Seven unimplemented destinations: `.openBellSound`, `.openDarkMode`,
  `.openLanguage`, `.openDownloads`, `.openHelp`, `.openExportData`, and
  `.openOffline` are TODOs in the coordinator.

- Toggles update the in-memory `ILSettingsStateModel` only — nothing is
  persisted.

- "Chế độ tối" shows a mock `.system` label and does not read/write
  `ThemeService`; the font-scale slider is not connected to the scripture
  reader's actual scaling; `appVersion` is a mock "1.4".

## Open questions (resolved during implementation)

- ~~Is the "Chế độ tối" value real or mock?~~ → Mock. The Domain
  `ILSettingsThemeMode` enum describes the setting for this screen, but the real
  value is managed by `ILThemeMode` (Core/Theme) + `ThemeService`, which the
  screen does not read/write yet. Resolved during implementation (see
  `Domain/Entities/ILSettingsEntity.swift`).
