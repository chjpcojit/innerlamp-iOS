# Software Requirements Specification — ContactSupport

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | ContactSupport (Liên hệ hỗ trợ) |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-10-10 |
| Status | draft — channels and submit API are mocked; contract unconfirmed |
| Owner / author | Product / BA (prepared by ba-writer) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

Define the Contact Support screen: how a practitioner reaches the InnerLamp support team (ban hỗ trợ)
through direct channels or by submitting a request form.

### 1.2 Scope

**In scope:** list of contact channels (email, hotline, Zalo OA), a request form (topic + message),
a "request sent" confirmation, a link to Help.

**Out of scope:** the support backend / ticketing, delivery of replies to the Notifications screen,
the Settings row that opens this screen.

### 1.3 Product overview

Reached from Settings → "Hỗ trợ & pháp lý", from the footer of Help, and from the footer of the Legal
screen.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Ban hỗ trợ | The InnerLamp support team |
| Channel | A direct contact method: email, hotline, Zalo Official Account |
| Request code | Reference such as `#IL-2431` shown after a request is sent |
| Zalo OA | Zalo Official Account, a messaging channel in Vietnam |

### 1.5 References

- Prototype `InnerLamp Prototype.dc.html` — screen `contact` (`ctChannels`, `ctTopics`, `ctSend`)
- `Docs/innerlamp-project/project/docs/Mo-ta-tinh-nang.md`

### 1.6 Document organization

Standard IEEE 29148 order; open questions in Appendix A.

---

## 2. Overall description

### 2.1 Product perspective

New screen. The request submission needs a backend endpoint that does not exist yet; it is stubbed.

### 2.2 Product functions

- Show contact channels and open them in the system (`FR-001`)
- Choose a topic and write a message (`FR-002`)
- Validate and submit the request (`FR-003`, `FR-004`)
- Show confirmation and allow a new request (`FR-005`)
- Link to Help (`FR-006`)

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Practitioner | Signed-in app user | Can submit requests; reply goes to their phone number and Notifications |

### 2.4 Operating environment

- Platform: iOS; iPhone.
- Network: submitting needs network once the API exists; with the stub, none.
- System apps: Mail, Phone, and Zalo (or browser fallback) handle channel actions.

### 2.5 Design and implementation constraints

- MVVM-C + Clean Architecture; navigation via Coordinator.
- Design System tokens/components (e.g. chips, buttons, text field).
- Channel actions via system URL opening from the Coordinator, not from the ViewModel.

### 2.6 User documentation
**N/A** — screen is self-explanatory.

### 2.7 Assumptions and dependencies

- **Assumptions:** email `hotro@innerlamp.vn`, hotline `1900 6868` (8:00–21:00) and Zalo OA "InnerLamp" are placeholders; support replies "usually within a day" and 8:00–21:00 hours are mock copy.
- **Dependencies:** support-request API (not provided), Notifications (reply delivery), user profile (phone number shown in the note).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

Single scrollable screen: heading "Chúng tôi luôn lắng nghe" with response-hours text; channel card
with three rows; request form card (topic chips, message field, reply note, submit button) or the
"Đã gửi yêu cầu" card; "Câu hỏi thường gặp" shortcut. Visual spec: prototype screen `contact`.

#### 3.1.2 Hardware interfaces
**N/A**.

#### 3.1.3 Software interfaces

Submit support request: contract not yet confirmed. Stubbed in the UseCase; the stub returns a locally
generated request code.

> ⚠️ Not confirmed: support-request API (endpoint, payload, request-code format, auth) — blocks replacing the stub.

#### 3.1.4 Communication interfaces
HTTPS/JSON expected once the API exists.

### 3.2 Functional requirements

#### Channels

**FR-001 — Open a contact channel**
- **Priority:** Must
- **Description:** WHEN the user taps a channel row THE SYSTEM SHALL hand off to the matching system action (compose email, dial hotline, open Zalo OA).
- **Verification method:** manual QA on device; coordinator unit test
- **Source:** Prototype `ctChannels`
- **Acceptance criteria:**
  ```gherkin
  Scenario Outline: Open a channel
    Given the user is on Contact Support
    When the user taps the "<channel>" row
    Then the system action for "<channel>" is launched

    Examples:
      | channel |
      | Email   |
      | Hotline |
      | Zalo OA |

  Scenario: Channel cannot be opened
    Given the device cannot handle the channel action
    When the user taps the channel row
    Then the user sees a message that the channel is unavailable
  ```
  > ⚠️ Not confirmed: real email address, hotline number and Zalo OA link (prototype values are placeholders) — blocks release; mock values used.

#### Request form

**FR-002 — Choose a topic**
- **Priority:** Must
- **Description:** WHEN the form is shown THE SYSTEM SHALL offer topics "Tài khoản", "Cúng dường", "Thông tin chùa", "Lỗi ứng dụng", "Góp ý", with exactly one selected (default "Tài khoản").
- **Verification method:** unit test
- **Source:** Prototype `ctTopics`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Default topic
    Given the user opens Contact Support
    Then the first topic is selected

  Scenario: Change topic
    Given a topic is selected
    When the user taps another topic
    Then only the tapped topic is selected
  ```

**FR-003 — Validate the message**
- **Priority:** Must
- **Description:** WHEN the user submits with a message shorter than 10 characters (after trimming) THE SYSTEM SHALL show the error "Vui lòng mô tả ít nhất 10 ký tự." and not submit; the error SHALL clear when the user edits the message.
- **Verification method:** unit test
- **Source:** Prototype `ctSend`, `ctErr`
- **Acceptance criteria:**
  ```gherkin
  Scenario Outline: Reject a too-short message
    Given the user is on the request form
    When the user enters "<text>" and taps "Gửi yêu cầu"
    Then the error "Vui lòng mô tả ít nhất 10 ký tự." is shown
    And nothing is submitted

    Examples:
      | text      |
      |           |
      | hello     |
      |    hi     |
      | 123456789 |

  Scenario: Error clears on edit
    Given the length error is shown
    When the user edits the message
    Then the error is hidden
  ```
  > ⚠️ Not confirmed: maximum message length — blocks upper-bound validation; none enforced for now.

**FR-004 — Submit the request**
- **Priority:** Must
- **Description:** WHEN the user submits a valid request THE SYSTEM SHALL send it to the support service and, on success, show a request code and the chosen topic.
- **Verification method:** unit test (UseCase stub / mocked repository)
- **Source:** Prototype `ctSend`, `ctCode`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Successful submission
    Given the user entered a message of at least 10 characters
    When the user taps "Gửi yêu cầu"
    Then the confirmation shows a request code and the chosen topic

  @not-confirmed
  Scenario: Submission fails
    Given the user entered a valid message
    And the request cannot be sent
    When the user taps "Gửi yêu cầu"
    Then an error is shown and the message text is kept
  ```
  > ⚠️ Not confirmed: failure behavior (offline, server error, rate limit / duplicate submissions) — blocks error copy and retry design.

**FR-005 — Confirmation and new request**
- **Priority:** Should
- **Description:** WHEN a request has been sent THE SYSTEM SHALL replace the form with a confirmation card; WHEN the user taps "Gửi yêu cầu khác" THE SYSTEM SHALL show an empty form with the default topic.
- **Verification method:** unit test
- **Source:** Prototype `ctSentOn`, `ctNew`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Start another request
    Given the confirmation card is shown
    When the user taps "Gửi yêu cầu khác"
    Then the form is shown with an empty message and the default topic
  ```
  > ⚠️ Not confirmed: whether the reply is really delivered to the Notifications screen and to the user's phone number as the copy states — blocks the confirmation wording.

**FR-005a — Reply note shows the user's phone**
- **Priority:** Could
- **Description:** THE SYSTEM SHALL show the reply note with the signed-in user's own phone number, not a fixed number.
- **Verification method:** unit test
- **Source:** BA finding (prototype hardcodes "+84 912 345 678")
- **Acceptance criteria:**
  ```gherkin
  Scenario: Note uses the user's phone
    Given the signed-in user has a phone number
    When the user opens Contact Support
    Then the reply note shows that phone number
  ```

#### Navigation

**FR-006 — Shortcut to Help**
- **Priority:** Should
- **Description:** WHEN the user taps "Câu hỏi thường gặp" THE SYSTEM SHALL open Help.
- **Verification method:** manual QA
- **Source:** Prototype `goFaq`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Open Help
    Given the user is on Contact Support
    When the user taps "Câu hỏi thường gặp"
    Then the Help screen opens
  ```

### 3.3 Performance requirements

- **NFR-001 — Input responsiveness:** typing in the message field stays smooth; no work on the main thread beyond validation.

### 3.4 Logical database requirements

- Draft message is kept only in memory for the life of the screen. Whether a draft survives leaving the screen is unconfirmed.

> ⚠️ Not confirmed: should an unsent draft persist across app launches — blocks persistence design (none assumed).

### 3.5 Design constraints
Design System tokens; localized strings; keyboard avoidance handled by the base view controller.

### 3.6 Software system attributes

- **Reliability:** failed submit must not lose the user's text.
- **Availability:** screen usable offline except submit.
- **Security:** the message may contain personal data; it must not be logged raw (AGENTS.md §7); transport over HTTPS; the reply phone number is masked in logs.
- **Maintainability:** channel list and topics are data-driven.
- **Portability:** N/A.

---

## 4. Verification & traceability

### 4.1 Verification approach
XCTest for ViewModel/UseCase; manual device QA for system hand-offs.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Prototype `ctChannels` | → spec-writer | 2 scenarios |
| FR-002 | Prototype `ctTopics` | → spec-writer | 2 scenarios |
| FR-003 | Prototype `ctSend` | → spec-writer | 2 scenarios |
| FR-004 | Prototype `ctSend` | → spec-writer | 2 scenarios |
| FR-005 | Prototype `ctSentOn` | → spec-writer | 1 scenario |
| FR-005a | BA finding | → spec-writer | 1 scenario |
| FR-006 | Prototype `goFaq` | → spec-writer | 1 scenario |
| NFR-001 | AGENTS.md 4.6 | → spec-writer | Manual |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: support-request API (endpoint, payload, request-code format, auth) — blocks replacing the stub.

> ⚠️ Not confirmed: real email, hotline and Zalo OA values — blocks release; placeholders used.

> ⚠️ Not confirmed: maximum message length — blocks upper-bound validation.

> ⚠️ Not confirmed: failure behavior of submit (offline, server error, rate limit/duplicates) — blocks error copy.

> ⚠️ Not confirmed: reply delivery to Notifications and phone number — blocks confirmation wording.

> ⚠️ Not confirmed: persistence of unsent draft — blocks persistence design.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| How is submit handled without an API? | Stub in UseCase + Assumption entry | 2026-10-10 |
| Are channel values real? | Placeholders, kept as mock | 2026-10-10 |
| Team name | "Ban hỗ trợ" | 2026-10-10 |
