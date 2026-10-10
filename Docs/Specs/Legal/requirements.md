# Requirements — Legal

Version: 1.0
Last updated: 2026-10-10
Status: not started — prospective; document text is bundled mock, API unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Legal/`

> See `changelog.md` in this folder for the version history of this spec.
> Source of truth for business intent: `SRS.md` in this folder.

## User Story

As a practitioner, I want to read the Terms of Use and the Privacy Policy as a
full page from Settings, so that I know the rules and how my data is handled.

## Acceptance Criteria (EARS notation)

- WHEN the user taps "Điều khoản sử dụng" or "Chính sách quyền riêng tư" in
  Settings, THE SYSTEM SHALL open the Legal screen on the matching document.
  (FR-001)
- WHEN the screen loads, THE SYSTEM SHALL show the segmented control (Điều khoản
  | Quyền riêng tư), the document title, the effective line and all sections of
  the document in order — 6 for Terms, 5 for Privacy. (FR-003)
- WHEN the user taps the other segment, THE SYSTEM SHALL show that document and
  update the title and navigation bar title. (FR-002)
- WHEN the user switches document, THE SYSTEM SHALL scroll back to the top.
  (FR-002)

  > ⚠️ Not confirmed: whether switching resets the scroll position (prototype
  > is silent) — reset assumed.

- WHEN the document content cannot be loaded, THE SYSTEM SHALL show an error
  state with a retry action. (FR-003)
- WHEN the user taps the "Có câu hỏi về {điều khoản | quyền riêng tư}?" card,
  THE SYSTEM SHALL open Contact Support. (FR-004)
- WHEN the user taps back, THE SYSTEM SHALL pop Legal.

## Out of scope (this feature boundary, not backend work)

- The sign-up bottom sheet (`ILSignUpLegalSheetViewController`, SignUp feature)
  and any consent/acceptance recording.
- Account deletion.
- The Settings rows that open this screen (Settings feature).

## Pending (not yet implemented — see `tasks.md`)

- Legal-document API; text is the bundled `legal.*` localization shared with the
  sign-up sheet.

  > ⚠️ Not confirmed: legal-document API (endpoint, versioning, effective date,
  > language) — blocks `tasks.md` Phase 3.

- Effective date and version line ("Hiệu lực từ 01/09/2026 · InnerLamp 1.4") is
  mock text.

  > ⚠️ Not confirmed: source of the effective date and version (API vs the app's
  > `CFBundleShortVersionString`) — mock used.

- The Terms state that an account can be deleted "trong Cài đặt".

  > ⚠️ Not confirmed: whether account deletion exists in the app — blocks
  > legal-copy sign-off; text kept verbatim.

## Open questions (resolved during implementation)

- ~~How to treat the effective date and legal text?~~ → Mock verbatim, recorded
  as an Assumption (2026-10-10).
- ~~Content source~~ → Bundled mock now; API supplied later by the product owner
  (2026-10-10).
