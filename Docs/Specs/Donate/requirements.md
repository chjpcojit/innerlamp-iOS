# Requirements — Donate

Version: 1.1
Last updated: 2026-10-11
Status: implemented; receiving account, QR payload and receipt are mocked / unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Donate/`

> See `changelog.md` in this folder for the version history of this spec.
> Source of truth for business intent: `SRS.md` in this folder.

## User Story

As a practitioner who finds InnerLamp useful, I want to make a voluntary one-off
donation to the InnerLamp team by bank transfer, so that the app can stay free
for everyone without any plan, subscription or auto-renewal.

## Acceptance Criteria (EARS notation)

- WHEN the user taps the "Ủng hộ InnerLamp" card on Profile, THE SYSTEM SHALL
  present the donation screen as a modal in the form state. (FR-001)
- WHEN the form is shown, THE SYSTEM SHALL show the logo, the heading "Miễn phí
  trọn đời cho mọi người", the explanatory text, the three "Khoản ủng hộ dùng
  cho" items, the amounts 20.000₫ / 50.000₫ / 100.000₫ / 200.000₫ / 500.000₫ /
  "Tùy tâm" with 50.000₫ selected, the message field, the action button, the
  no-subscription note and "Để sau". (FR-002)
- WHEN the user taps an amount, THE SYSTEM SHALL select only that amount and
  show it in the action button as "Ủng hộ <amount>". (FR-002)
- WHEN the user selects "Tùy tâm", THE SYSTEM SHALL show a numeric field that
  keeps digits only (at most 9) and groups them with "." separators. (FR-003)
- WHILE the effective amount is below 10.000₫, THE SYSTEM SHALL disable the
  action button and show "Nhập từ 10.000₫". (FR-003)
- WHEN the user types a message, THE SYSTEM SHALL accept at most 120
  characters; the message is optional. (FR-004)

  > ⚠️ Not confirmed: where the optional message goes — with no API it is not
  > delivered to anyone; blocks the field's purpose and helper copy.

- WHEN the user taps the enabled action button, THE SYSTEM SHALL show "Quét mã
  để chuyển khoản", a QR code and a details table (Người nhận, Ngân hàng, Số
  tiền, Nội dung). (FR-005)
- WHEN the user taps "Đổi số tiền", THE SYSTEM SHALL return to the form keeping
  the amount and message. (FR-005)

  > ⚠️ Not confirmed: real recipient, bank, account number and QR payload —
  > values are placeholders; blocks release.

  > ⚠️ Not confirmed: transfer-note rule — the prototype ("UNGHO IL" + first
  > three digits of the amount) collides for 20.000 and 200.000; blocks
  > donation reconciliation.

- WHEN the user taps "Tôi đã chuyển khoản", THE SYSTEM SHALL show "Cảm ơn bạn"
  with the amount and a "Quay lại" button, and SHALL NOT claim the transfer was
  verified. (FR-006)

  > ⚠️ Not confirmed: the line "Biên nhận đã được gửi vào Thông báo" — nothing
  > is sent without a backend; the line is not shown until a real receipt exists.

- WHEN the user taps the close button, "Để sau" or "Quay lại", THE SYSTEM SHALL
  dismiss the modal and return to Profile, keeping no state. (FR-007)

## Out of scope (this feature boundary)

- Any in-app payment, subscription or recurring charge.
- Server-side recording or verification of a transfer.
- Donation history / "Sổ công đức" and the temple offering flow ("Cúng dường").
- Entry points other than the Profile card.

## Pending (not yet implemented — see `tasks.md`)

- Real account details and QR payload (mock provider until confirmed).
- App Store acceptability of an in-app external bank-transfer donation.

  > ⚠️ Not confirmed: App Store review acceptance — may change presentation
  > before release.

## Open questions (resolved)

- ~~Real account / QR available?~~ → No, mock provider, blocks release (2026-10-11).
- ~~What does "Tôi đã chuyển khoản" do?~~ → Only shows the thank-you state, no API (2026-10-11).
- ~~Amount and message rules~~ → As prototype (2026-10-11).
- ~~Entry points~~ → Profile card only (2026-10-11).
