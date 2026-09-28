# Requirements — Language

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-only (no backend contract required)
Feature folder: `InnerLamp/Presentation/Scenes/Language/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner, I want to choose the app language, sutra font size, and
light/dark appearance, so that the app matches my reading and display
preferences.

## Acceptance Criteria (EARS notation)

- WHEN the Language screen loads, THE SYSTEM SHALL show three sections: Ngôn
  ngữ, Cỡ chữ kinh văn, and Giao diện.
- WHEN the user selects a language (Tiếng Việt · English · 中文 · 繁體), THE
  SYSTEM SHALL apply it app-wide with single-select behavior (radio, gold
  border).
- WHEN the user selects a font size (Nhỏ, Vừa, Lớn, Rất lớn), THE SYSTEM SHALL
  immediately update the preview sentence to the corresponding size (14 / 16 /
  19 / 22 px).
- WHEN the user selects an appearance (Sáng, Tối, Theo máy), THE SYSTEM SHALL
  apply the theme immediately app-wide.
- WHEN "Theo máy" is selected, THE SYSTEM SHALL follow the device's
  `prefers-color-scheme` and update live when the device changes mode.

## Out of scope (this feature boundary, not backend work)

- The Settings "Hiển thị & ngôn ngữ" row (and dark-mode row) that navigate here
  — owned by the Settings feature.
- The actual localization infrastructure and theme provider — shared Core
  concerns; this screen only writes the user's choices.

## Pending (not yet implemented — see `tasks.md`)

- None requiring a backend — local-only (UserDefaults via the shared
  localization/theme services).

## Open questions (resolved during implementation)

- <!-- none yet -->
