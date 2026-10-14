# Requirements — MeritBook

Version: 1.0
Last updated: 2026-10-11
Status: in-progress — UI and logic built against in-memory sample data; no API contract, donation navigation is a TODO
Feature folder: `InnerLamp/Presentation/Scenes/MeritBook/`

> See `changelog.md` in this folder for the version history of this spec. Business context: `SRS.md`.

## User Story

As a practitioner, I want a book of the offerings I have dedicated as merit, so that I can see what I
gave, what the temple confirmed, and how the temple uses donations.

## Acceptance Criteria (EARS notation)

### Header

- WHEN the screen loads, THE SYSTEM SHALL show a sticky header (`ILStickyHeaderBand` + `ILNavBar`)
  with back, title "Sổ công đức", subtitle "Công đức đã hồi hướng" and a pill "Cúng dường".
- WHEN the user taps back, THE SYSTEM SHALL pop the screen.
- WHEN the user taps "Cúng dường", THE SYSTEM SHALL emit an open-donate event (TODO destination).

### Statistics

- THE SYSTEM SHALL show three columns: year total (compact: `1,1 tr` / `300k`) captioned
  "tịnh tài năm <YYYY>", count of "Thỉnh đèn tại chùa" offerings captioned "đèn thỉnh tại chùa", and
  count of distinct temples captioned "chùa đã cúng dường".

### History

- THE SYSTEM SHALL list offerings newest first with purpose, "<temple> · dd/MM/yyyy", amount
  (`200.000đ`) and a pill "Chùa đã xác nhận" / "Chờ chùa xác nhận".
- WHEN there are no offerings, THE SYSTEM SHALL show a short empty note (⚠️ Not confirmed — wording assumed).

### Letter

- WHEN a letter exists, THE SYSTEM SHALL show the "Thư tùy hỷ" block with body and
  "<signer> · <title>" right-aligned italic; otherwise THE SYSTEM SHALL hide the block.

### Monthly support

- WHEN monthly support is active, THE SYSTEM SHALL show "Cúng dường Tam Bảo · <amount> / tháng",
  "<temple> · nhắc vào mùng Một" and a "Dừng" pill.
- WHEN the user taps "Dừng", THE SYSTEM SHALL stop monthly support and show the dashed note
  "Chưa bật hộ trì hằng tháng. Bật trong bước Người cúng khi cúng dường." (⚠️ Not confirmed:
  confirmation dialog / scheduled payment handling.)

### Financial disclosure

- WHEN a build project exists, THE SYSTEM SHALL show its name, "<temple> · <round>", a progress bar,
  "<raised> / <goal> triệu đồng", the percentage (rounded), the expense rows and
  "Cập nhật <dd/MM/yyyy> · ban hộ tự công bố"; otherwise THE SYSTEM SHALL hide the block.

### Failure

- WHEN loading fails, THE SYSTEM SHALL hide the content and show an error state.

## Pending

- ⚠️ Not confirmed: API contract (history, letter, monthly, disclosure, stop monthly).
- ⚠️ Not confirmed: "Cúng dường" destination.
- ⚠️ Not confirmed: pending offerings counted in year total / lamp count (assumed yes).
- ⚠️ Not confirmed: stop-monthly confirmation and scheduled-payment handling.
- ⚠️ Not confirmed: offline behavior.
