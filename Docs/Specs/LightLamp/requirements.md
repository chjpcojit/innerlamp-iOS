# Requirements — LightLamp

Version: 2.0
Last updated: 2026-10-17
Status: in-progress (drift) — the two screens, the lamp artwork, the entry points and the form shell are built against local Core Data and local rules (build-verified, tests written but not run); v2.0 replaces the local behavior with the server-driven one of the product spec: sign-in gate, `POST /v1/lamps` / `GET /v1/lamps`, community garden, own-lamp mark, hide-name switch, visibility notice, server end moment, new remaining-time label, input limits, vectors (`tasks.md` Phase 2–6). Two contract changes are not in `openapi.yaml` yet (optional recipient, own-lamp flag) and block parts of Phase 3.
Feature folder: `InnerLamp/Presentation/Scenes/LightLamp/`
Product spec: innerlamp-be `docs/product/lamp/product.md` @ v1.0
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ 7214104 (`info.version` 2.1.1, tag `Lamps`: `POST /v1/lamps`, `GET /v1/lamps`); backend feature spec `docs/specs/features/lamp/requirements.md` @ v2.0 (its contract changes land as `info.version` 3.0.0 with the backend code — not in `openapi.yaml` yet)
Implements: BR-LMP-01, BR-LMP-02, BR-LMP-03 (display), BR-LMP-04, BR-LMP-05 (show the refusal), BR-LMP-06, BR-LMP-07, BR-LMP-08 (ignore a second tap), BR-LMP-09 (display), BR-LMP-10, BR-LMP-11, BR-LMP-12, BR-LMP-13, BR-LMP-14, FR-LMP-001, FR-LMP-002, FR-LMP-003, FR-LMP-004, FR-LMP-005, FR-LMP-006, FR-LMP-007, FR-LMP-008, FR-LMP-009, FR-LMP-010, FR-LMP-011, FR-LMP-012, FR-LMP-013, FR-LMP-014, NFR-LMP-03
Not on iOS: NFR-LMP-01 and NFR-LMP-02 (Backend only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of lighting a lamp ("Thắp đèn") and the lamp garden ("Vườn đèn"). Product behavior — the closed sets, burn durations, the end moment, the limit, the recipient and prayer rules, the double-submission window, the lighter's name, what other users see, garden order and counts, the remaining-time label, final lamps, sign-in — lives in the product spec and is **not** restated here; this file only says how the iOS app implements those `BR-LMP-*` / `FR-LMP-*`. Written prospectively (v1.0, 2026-10-11, local-only), built (v1.1–v1.3), rewritten in v2.0 to cite the product spec; v2.0 replaces the whole data model (Core Data → server) but keeps the two screens and their layout. `(iOS)` after a criterion is the skill's `(platform)` tag: behavior that exists only because of this platform.

> Layout source: the design prototype `InnerLamp Prototype.dc.html` (product spec §1.5), screens `offer` (lighting) and `garden`, artwork `IL-LampArt.dc.html`. The prototype's temple-lamp card and its "center button opens meditation" are overridden by the product spec (FR-LMP-014, FR-LMP-001). Copy source: product spec §3.1.1.

## User Story

As a signed-in practitioner, I want to light a free symbolic lamp with an intention and a dedication, optionally without my name, and see the community's lit lamps and mine in a garden, so that I keep a small daily act of dedication together with others.

## Constraints from the product spec

- **Server decides, the app displays** (product §2.7, NFR-LMP-03): the lighting moment, the end moment, which lamps are lit, the limit and the double-submission window are the server's. The app sends no time, no id and no name; it uses the device clock only to format the remaining-time label and the end date.
- **Nothing is stored on the device** (product §2.4, §3.7, Appendix A): no lamp copy, no offline garden. The lamps that the pre-v2.0 app stored in Core Data are dropped, not uploaded; sign-out no longer touches lamps.
- **Online only** (product §2.4): with no connection lighting fails with a message and the garden shows its error state.
- **Free, no temple lamp** (FR-LMP-014): no "Thỉnh đèn tại chùa", donation or payment control on any lamp screen.
- **Scope of this spec**: light a lamp and the garden. The English copy of every message is not defined yet (⚠️ below).

## Acceptance Criteria (EARS notation)

### Entry and access

1. WHEN a signed-in user taps the center lamp button of the tab bar, THE SYSTEM SHALL present Thắp đèn full-screen over the tab bar. (FR-LMP-001)
2. WHEN a signed-in user taps Home's suggested-session row "Thắp đèn — Vu Lan", THE SYSTEM SHALL push Thắp đèn. (FR-LMP-001)
3. WHEN the user looks for meditation, THE SYSTEM SHALL keep it reachable from Home's meditation row and from the Meditation area of the Library tab, and the center button SHALL NOT open it. (FR-LMP-001)
4. WHEN a guest (no stored session) opens Thắp đèn from either entry, THE SYSTEM SHALL show a short introduction to the lamp and the button "Đăng nhập để thắp đèn" instead of the form and the garden, SHALL NOT call `POST /v1/lamps` or `GET /v1/lamps`, and SHALL show no lamp and no count; the button leads to sign-in. (FR-LMP-013, BR-LMP-14)

    > ⚠️ Not confirmed (product): the text of the guest introduction (product §3.1.1 names the screen and the button but gives no copy) — blocks the guest view copy (`tasks.md` Phase 4); hand back to ba-writer in innerlamp-be.

    > ⚠️ Not confirmed: whether the guest view reuses the shared sign-in prompt of `Docs/Specs/Login/` (criterion 21 there: explanation + "Đăng nhập" + "Tạo tài khoản") with the lamp copy, or is a lamp-specific view with only "Đăng nhập để thắp đèn" — blocks `tasks.md` Phase 4 "Guest view"; the shared prompt itself is Login's Phase 6.

5. WHEN a lamp request is refused with `401` because the session cannot be refreshed, THE SYSTEM SHALL follow the session-ended behavior of `Docs/Specs/Login/` and SHALL show no lamp data; WHEN the user has no session at all, a `401` SHALL NOT be treated as an ended session (the guest view of criterion 4 applies). (FR-LMP-013, BR-LMP-14)

### Lighting form ("Thắp đèn")

6. WHEN the lighting screen opens for a signed-in user, THE SYSTEM SHALL show an unlit lamp on the hero stage, the headline "Thắp một ngọn đèn, hồi hướng cho người thương", the groups lamp type (3), intention (4) and burn duration (1, 7, 21, 49 days), the recipient field "Dành cho", the optional prayer field "Lời nguyện", the switch "Ẩn tên tôi", the button "Thắp đèn" and the header action "Vườn đèn". (FR-LMP-002, BR-LMP-01, BR-LMP-02)

    > ⚠️ Not confirmed (product): what the count line under the headline shows now that lamps are the server's (the pre-v2.0 line "Bạn có N ngọn đèn trong vườn" counted the user's own local lamps; the contract has no own-lamp count and product §3.1.1 defines no such line) — blocks the count line on the lighting screen (`tasks.md` Phase 4); hand back to ba-writer in innerlamp-be.

7. WHEN the form opens, THE SYSTEM SHALL preselect "Đèn dầu", "Cầu an" and 7 days and leave "Ẩn tên tôi" off. (FR-LMP-002)
8. WHEN the user taps an option of the type, intention or duration group, THE SYSTEM SHALL select it exclusively; for a type change THE SYSTEM SHALL update the kicker "ĐÈN · <TYPE>" and the lamp artwork. (FR-LMP-002)
9. THE SYSTEM SHALL show under the recipient field the notice "Người khác sẽ thấy tên người nhận.". (FR-LMP-002, BR-LMP-10)
10. WHEN the recipient is empty or only spaces, THE SYSTEM SHALL light the lamp without a recipient and show it as dedicated to "Tất cả chúng sanh" (the app supplies this wording; the server returns no text for it); WHEN the prayer is empty or only spaces, THE SYSTEM SHALL light the lamp without a prayer. (FR-LMP-003, BR-LMP-06, BR-LMP-07)

    > ⚠️ Not confirmed: not in openapi.yaml yet (planned 3.0.0, be spec v2.0) — an optional, nullable recipient on `POST /v1/lamps` and in the responses. Until it ships the service (2.1.1) rejects a lamp without a recipient; this blocks lighting a lamp with a blank recipient and `tasks.md` Phase 3 "Light" end-to-end. The app does not work around it by sending the words "Tất cả chúng sanh" as the recipient.

### Lighting a lamp

11. WHEN the user taps "Thắp đèn" and the content fails the local check — an unknown type, intention or duration; a recipient of more than 100 characters or a prayer of more than 300 after trimming both ends, counted as characters after Unicode NFC normalization — THE SYSTEM SHALL send nothing, show "Thông tin chưa hợp lệ. Vui lòng kiểm tra lại người nhận và lời nguyện.", stay on the form and keep every value. (FR-LMP-003, BR-LMP-01, BR-LMP-02, BR-LMP-06, BR-LMP-07)
12. WHEN the content passes the local check, THE SYSTEM SHALL disable the button, show "Đang thắp…", ignite the lamp artwork and send the lamp to the server (design, "Light a lamp"); WHILE lighting, THE SYSTEM SHALL ignore further taps and changes. (FR-LMP-003, BR-LMP-08)
13. WHEN the server answers that the lamp is lit — whether it created the lamp or returned the identical lamp lit within the last seconds — THE SYSTEM SHALL show the confirmation built from the lamp the server returned: "Đèn đã được thắp", the caption "<type> · <intention> · sáng <N> ngày", the line "Nguyện đem công đức này hồi hướng cho <recipient | tất cả chúng sanh>", the prayer in quotation marks when there is one, until when the lamp burns (the end moment in the device's time zone), and the actions "Thắp thêm đèn" and "Vào vườn đèn". (FR-LMP-003, FR-LMP-005, BR-LMP-03, BR-LMP-06, BR-LMP-08, BR-LMP-10)
14. WHEN the switch "Ẩn tên tôi" is on at lighting, THE SYSTEM SHALL tell the server to hide the name; THE SYSTEM SHALL NOT send any name, the account's full name or any time. (FR-LMP-003, BR-LMP-09, BR-LMP-14, NFR-LMP-03)
15. WHEN the server refuses because the user already has the maximum number of lit lamps, THE SYSTEM SHALL show "Bạn đã có 20 ngọn đèn đang sáng, mức tối đa cho mỗi người. Hãy thắp thêm khi có đèn tắt.", stay on the form and add no lamp; the app SHALL NOT count the user's lamps itself. (FR-LMP-004, BR-LMP-05)
16. WHEN the server rejects the content as invalid, THE SYSTEM SHALL show the message of criterion 11 and keep the form. (FR-LMP-003, BR-LMP-06, BR-LMP-07)
17. WHEN lighting fails because the server cannot be reached, times out or answers with a server error, THE SYSTEM SHALL show "Chưa thắp được đèn. Vui lòng thử lại.", return to the form with every value kept and add no lamp. (FR-LMP-003)
18. WHEN the user taps "Thắp thêm đèn", THE SYSTEM SHALL return to the form with an unlit lamp, an empty recipient and prayer, and the previous type, intention and duration kept. (FR-LMP-003)

    > ⚠️ Not confirmed (product): whether "Ẩn tên tôi" stays on or goes back to off after "Thắp thêm đèn" (FR-LMP-003 lists only type, intention and duration as kept) — blocks the switch state in criterion 18; hand back to ba-writer in innerlamp-be.

19. THE SYSTEM SHALL show no "Thỉnh đèn tại chùa" card and no donation or payment control on the form, the confirmation or the garden, and no action to put out, edit, extend or relight a lamp. (FR-LMP-014, BR-LMP-13)

### Garden ("Vườn đèn")

20. WHEN a signed-in user taps "Vườn đèn" in the lighting header or "Vào vườn đèn" in the confirmation, THE SYSTEM SHALL open the garden and load its first page from the server; THE SYSTEM SHALL show no sample lamp and no base number. (FR-LMP-007, FR-LMP-011)
21. WHEN a page has loaded, THE SYSTEM SHALL show the subtitle "<N> ngọn đèn đang sáng" with N the total from the server response, the chips "Tất cả" and one per lamp type each with the server's count for it (0 when none), and one card per lamp in the order the server sent them. (FR-LMP-007, FR-LMP-011, BR-LMP-11)
22. WHEN a card is rendered, THE SYSTEM SHALL show the artwork, the lamp type, the lighter's name as the server sent it, "Cho <recipient>" — or "Cho tất cả chúng sanh" when the lamp has no recipient — and the remaining-time label, and SHALL NOT show an intention or a prayer on any card, including the user's own. (FR-LMP-007, BR-LMP-06, BR-LMP-09, BR-LMP-10)

    > ⚠️ Not confirmed (product): whether the garden card also shows the lamp's end date and time (FR-LMP-006's scenario "End date follows the viewer's time zone" says the garden shows it; the card of §3.1.1 lists only the remaining time) — blocks the card layout; hand back to ba-writer in innerlamp-be. The confirmation shows the end moment either way (criterion 13).

23. WHEN the server marks a lamp as the signed-in user's, THE SYSTEM SHALL highlight its card and label it "Của bạn" instead of the lighter's name, including a lamp lit anonymously and on a different device; the mark SHALL come only from the server's answer, never from lamps remembered on the device. (FR-LMP-008, BR-LMP-10)

    > ⚠️ Not confirmed: not in openapi.yaml yet (planned 3.0.0, be spec v2.0) — the per-lamp "is mine" flag on garden items. Blocks criterion 23 and `tasks.md` Phase 3 "Garden".

24. WHEN a lamp has 24 hours or more left, THE SYSTEM SHALL label it "Còn N ngày", N being the remaining days rounded up; WHEN it has less than 24 hours left, "Còn dưới 1 ngày"; WHEN no time is left, THE SYSTEM SHALL NOT show the card. The remaining time is the lamp's end moment minus the device's current moment, recomputed whenever the cards are drawn; the device clock decides nothing else. (FR-LMP-006, FR-LMP-007, BR-LMP-04, BR-LMP-12, NFR-LMP-03)
25. WHEN the user taps a type chip, THE SYSTEM SHALL ask the server for the first page of that type and replace the list; WHEN the user taps "Tất cả", THE SYSTEM SHALL ask for the first page of every type; the total and the counts SHALL come from the latest answer and SHALL NOT be recomputed by the app. WHILE a filter answer is awaited, THE SYSTEM SHALL ignore the answer of any earlier request. (FR-LMP-009, BR-LMP-11)
26. WHEN the server says more lamps exist, THE SYSTEM SHALL show "Xem thêm đèn", which appends the next page without repeating a lamp; WHEN the server says there are no more, THE SYSTEM SHALL NOT offer it; WHILE a page is loading, THE SYSTEM SHALL ignore a second tap. (FR-LMP-010, BR-LMP-11)
27. WHEN no lit lamp matches (nothing lit by anyone, or none of the chosen type), THE SYSTEM SHALL show "Vườn đèn còn trống" with "Thắp một ngọn đèn để nó sáng ở đây." and a button that opens a fresh lighting form; with a filter the chips SHALL still show every type's count. (FR-LMP-012, FR-LMP-009)
28. WHEN the garden cannot be loaded (no connection, timeout, server error), THE SYSTEM SHALL show "Chưa tải được vườn đèn. Vui lòng thử lại sau." and keep lighting available; WHEN only "Xem thêm đèn" fails, THE SYSTEM SHALL keep the lamps already shown. (FR-LMP-012)
29. WHEN the user taps "Thắp đèn" in the garden header, THE SYSTEM SHALL open a fresh lighting form. (iOS)

### Data, privacy and copy

30. THE SYSTEM SHALL NOT store a lamp, the garden or an own-lamp mark on the device, and WHEN the user signs out THE SYSTEM SHALL NOT delete or otherwise act on lamps. (iOS; product §2.4, Appendix A "Lamps already stored on iOS")
31. WHEN the lamp feature or its error handling logs (network logger, Sentry, analytics), THE SYSTEM SHALL NOT include the recipient or the prayer — only method, path, status and timing. (iOS; product §3.7)
32. THE SYSTEM SHALL take every message from product §3.1.1 in Vietnamese; the English copy waits for the product owner. (iOS)

    > ⚠️ Not confirmed (product): English copy for every message of §3.1.1 and the English name of the anonymous label (product Appendix A) — blocks an English locale of the lamp screens; the app has only `vi.json` today.

33. WHEN the unit tests run, THE SYSTEM SHALL pass every case of the client product vector files `rules/lamp-input-validation.json` (the local check of criterion 11) and `rules/lamp-remaining-label.json` (criterion 24); `rules/lamp-lifetime.json` and `rules/lamp-lighter-name.json` are decided by the backend and are run there (product §4.1). (BR-LMP-01, BR-LMP-02, BR-LMP-06, BR-LMP-07, BR-LMP-12)

    > ⚠️ Not confirmed (product): whether a lit lamp can be shared (the website offers "Chia sẻ"; product Appendix A) — iOS offers no share until it is decided.

## Error → UI mapping

Operations are cited from the contract; schemas and the full error list stay in `openapi.yaml`. Copy is product §3.1.1.

| Operation | Failure case | What the user sees |
|---|---|---|
| none (no session) | guest opens Thắp đèn | introduction + "Đăng nhập để thắp đèn"; no call (criterion 4) |
| `POST /v1/lamps` | 400 `VALIDATION_ERROR` | invalid-input message, form kept (criterion 16) |
| `POST /v1/lamps` | 409 `LAMP_LIMIT_REACHED` | limit message, form kept (criterion 15) |
| `POST /v1/lamps` | 401 | session-ended behavior of Login (criterion 5) |
| `POST /v1/lamps` | offline / timeout / 5xx / other | "Chưa thắp được đèn. Vui lòng thử lại.", form kept (criterion 17) |
| `GET /v1/lamps` | 401 | session-ended behavior of Login (criterion 5) |
| `GET /v1/lamps` | offline / timeout / 5xx | "Chưa tải được vườn đèn. Vui lòng thử lại sau.", lighting stays available (criterion 28) |
| `GET /v1/lamps` | 400 `INVALID_FILTER` / `INVALID_LIMIT` / `INVALID_CURSOR` | same message as a failed load; only reachable through an app bug (criterion 28) |
| `GET /v1/lamps` (load more) | any failure | cards already shown stay; "Xem thêm đèn" stays available (criterion 28) |

## Out of scope (this feature boundary, not backend work)

- "Thỉnh đèn tại chùa", payment and donation — the `offering` feature; its own spec and ADR (product §1.2).
- A "my lamps" screen, expired-lamp history, "your lamp is about to go out" notifications (product §1.2).
- Putting out, extending, relighting or editing a lamp (BR-LMP-13).
- Moderating text, filtering the garden by intention, sharing a lamp (product §1.2, Appendix A).
- Lamp artwork and animation beyond what is built — the design prototype owns them.
- The sign-in screens, the session-ended message and the shared guest prompt component — `Docs/Specs/Login/`.
- Home's suggested-session row itself — `Docs/Specs/Home/`; the tab bar — `Docs/Specs/Main/`.

## Pending (not yet implemented — see `tasks.md`)

Criteria the shipped code does **not** meet yet (drift against product spec v1.0; the same list is in `design.md` "Known gaps"):

- Criteria 4, 5 — no sign-in gate: a guest can light lamps from both entries (BR-LMP-14, FR-LMP-013).
- Criteria 6, 9, 14 — no "Ẩn tên tôi" switch and no visibility notice (FR-LMP-002).
- Criteria 10–13, 16–17 — lamps are saved to Core Data; no server call; the confirmation is built from the local draft, with no end moment (FR-LMP-003, BR-LMP-03).
- Criteria 11, 16 — no length limit on the recipient or the prayer (BR-LMP-06, BR-LMP-07; `AS-LightLamp-006`).
- Criterion 15 — no limit of lit lamps (BR-LMP-05).
- Criteria 20–23, 26 — the garden lists the user's own local lamps only; counts are computed locally; the page size (12) is a local constant and paging is local; cards read "Của bạn · <intention>", showing the intention (BR-LMP-10, BR-LMP-11, FR-LMP-007, FR-LMP-008; `AS-LightLamp-002`, `AS-LightLamp-004`).
- Criterion 24 — a lamp expires at the end of a calendar day and reads "Sáng đến hết hôm nay" when one day or less is left (BR-LMP-03, BR-LMP-04, BR-LMP-12; `AS-LightLamp-003`).
- Criterion 27 — the empty garden has no button to light a lamp (the header action exists) (FR-LMP-012).
- Criteria 15, 17, 28 — messages differ from §3.1.1 ("Chưa lưu được ngọn đèn. Vui lòng thử lại." / "Chưa tải được Vườn đèn. Vui lòng thử lại.") and the failures are shown as alerts only.
- Criterion 30 — sign-out deletes the lamps stored on the device (`ILSessionDataCleanerImpl`).
- Criterion 33 — vectors are not run; the unit tests of the feature are written but have never been run (`TD-LightLamp-004`).
- Visual QA on device (`TD-LightLamp-003`).

Backend dependencies (hand-off items, not tracked as tasks here): optional recipient and the own-lamp flag in the contract (3.0.0).

## Open questions (resolved)

- ~~Scope of this iteration~~ → Thắp đèn + Vườn đèn only. Resolved 2026-10-10.
- ~~Where lit lamps are stored~~ → local Core Data behind a repository protocol (v1). **Superseded 2026-10-16**: on the server; nothing stored on the device (product Appendix A). Resolved 2026-10-16.
- ~~Relation to `Docs/Specs/Offering/`~~ → separate feature; Offering untouched. Resolved 2026-10-10.
- ~~Maximum length of the dedication target and the vow~~ → 100 and 300 characters (BR-LMP-06, BR-LMP-07; `AS-LightLamp-006`). Resolved 2026-10-16 by product spec v1.0.
- ~~Entry points beyond Home's row and the center button~~ → the center navigation button opens Thắp đèn; Home's row stays; meditation stays reachable from Home and the Meditation area (FR-LMP-001; `AS-LightLamp-005`). Resolved 2026-10-16.
- ~~Source of community lamps in the garden~~ → the server's `GET /v1/lamps`, all users' lit lamps (BR-LMP-11; `AS-LightLamp-002`). Resolved 2026-10-16.
- ~~Real-time expiry vs static duration label~~ → the server end moment (lit moment + N × 24 h); label "Còn N ngày" / "Còn dưới 1 ngày" (BR-LMP-03, BR-LMP-12; `AS-LightLamp-003`). Resolved 2026-10-16.
- ~~Owner name on the user's lamps~~ → the lighter's name is the dharma name else "Vô danh", never the full name; own lamps read "Của bạn" (BR-LMP-09, FR-LMP-008; `AS-LightLamp-004`). Resolved 2026-10-16.
- ~~Empty-garden copy and layout~~ → "Vườn đèn còn trống" / "Thắp một ngọn đèn để nó sáng ở đây." with a button (FR-LMP-012; `AS-LightLamp-007`). Resolved 2026-10-16.
- ~~Show "Thỉnh đèn tại chùa" on the completion state~~ → no, on no lamp screen (FR-LMP-014; `AS-LightLamp-008`). Resolved 2026-10-16.
- ~~Lamps already stored on this device~~ → dropped, not uploaded; sign-out stops deleting them (product Appendix A; supersedes FR-014 of v1.3). Resolved 2026-10-16.
- ~~Guests~~ → introduction and "Đăng nhập để thắp đèn"; no lamp, no count (FR-LMP-013). Resolved 2026-10-16.
- ~~Sample lamps and base counts~~ → none on any platform (FR-LMP-011). Resolved 2026-10-16.
