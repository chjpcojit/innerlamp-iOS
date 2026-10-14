# Software Requirements Specification — Donate

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Donate ("Ủng hộ InnerLamp", prototype screen `paywall`) |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-10-11 |
| Status | draft — receiving account, QR payload and receipt behavior unconfirmed |
| Owner / author | InnerLamp BA (via Claude) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

Defines the business requirements of the "Ủng hộ InnerLamp" (Support InnerLamp) screen, a voluntary
one-off donation flow reached from the Profile tab. It drives `spec-writer` and the UI build.

### 1.2 Scope

**In scope:** a modal flow of three steps — choose an amount and optional message, show a bank-transfer
QR with transfer details, and a thank-you confirmation. Entry from the Profile "Ủng hộ InnerLamp" card.

**Out of scope:** any in-app payment (Apple IAP, card, e-wallet), subscriptions or recurring charges,
server-side verification of a transfer, donation history (the separate "Công đức · cúng dường" offering
flow and "Sổ công đức" are different features), any entry point other than the Profile card.

### 1.3 Product overview

InnerLamp is a free Buddhist practice app (sutras, talks, meditation, offerings). The product promise is
"free for life, no ads"; users may optionally support the team with a one-off bank transfer.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Ủng hộ | Voluntary donation to the InnerLamp team (not to a temple). |
| VietQR | Vietnamese interbank QR standard scanned by any banking app. |
| Tùy tâm | "As the heart wishes" — the free-amount option. |
| Transfer note | The "Nội dung" text the donor should enter in their banking app. |

### 1.5 References

- Prototype: `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html` (screen `paywall`; entry card in `profile`).
- `Docs/Specs/Profile/` (entry point, `openDonate` navigation event).
- `Docs/Specs/ContactSupport/` (precedent for mocked, unconfirmed contracts).

### 1.6 Document organization

Section 2 describes context, section 3 the requirements, section 4 traceability, appendix A open questions.

---

## 2. Overall description

### 2.1 Product perspective

New, self-contained modal screen. It touches no backend: the receiving account and QR payload are
supplied locally (mocked until confirmed). It is presented from the Profile coordinator.

### 2.2 Product functions

- Present the donation screen from Profile (`FR-001`).
- Choose an amount from presets or a custom amount (`FR-002`, `FR-003`).
- Add an optional message (`FR-004`).
- Show transfer QR and details (`FR-005`).
- Acknowledge the transfer and thank the user (`FR-006`).
- Dismiss or go back at any step (`FR-007`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Practitioner | Signed-in app user | Any user may open the screen; no entitlement is granted by donating |

### 2.4 Operating environment

- Platform: iOS, project minimum version.
- Devices: iPhone.
- Network: not required by this feature (no network call).

### 2.5 Design and implementation constraints

- Swift, UIKit programmatic, MVVM-C + Clean Architecture per `AGENTS.md`; Design System tokens only.
- Header must use `ILStickyHeaderBand` + `ILNavBar` (close variant) per `AGENTS.md` 4.5.
- App Store: no in-app purchase UI and no wording that implies a purchase, plan or unlock; the donation
  is an external bank transfer.

  > ⚠️ Not confirmed: App Store review acceptance of an in-app external bank-transfer donation for a
  > non-profit-like cause — may require a different presentation before release.

### 2.6 User documentation

N/A — the screen is self-explanatory; the FAQ item "InnerLamp có thu phí không?" already describes it.

### 2.7 Assumptions and dependencies

- **Assumptions:** the receiving account is a company account; donations are not tied to a user
  account or entitlement; the amount is never persisted.
- **Dependencies:** Profile screen entry card; real receiving account details and QR payload (not yet
  provided).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

One modal screen with three states (form, transfer, thanks) sharing a header with a close button and a
dark/"meditation" light-or-dark surface per the prototype. Built from Design System tokens and
components (`ILButton`, `ILField`/`ILInputCardView`, `ILStickyHeaderBand`, `ILNavBar`, `ILLogoView`).

#### 3.1.2 Hardware interfaces

**N/A** — no custom hardware interface.

#### 3.1.3 Software interfaces

**None.** No backend call is made. The receiving account and QR payload come from a local provider.

> ⚠️ Not confirmed: real bank, account number, account holder name and VietQR payload — blocks release;
> the app must not ship a QR that resolves to an invented account.

#### 3.1.4 Communication interfaces

N/A — no network communication.

### 3.2 Functional requirements

#### Entry and navigation

**FR-001 — Open from Profile**
- **Priority:** Must
- **Description:** WHEN the user taps the "Ủng hộ InnerLamp" card on Profile THE SYSTEM SHALL present the
  donation screen as a modal in the form state.
- **Verification method:** unit test (coordinator event) + manual QA
- **Source:** prototype `profile` card; user answer "only the Profile card".
- **Acceptance criteria:**
  ```gherkin
  Scenario: Open the donation screen
    Given the user is on the Profile tab
    When the user taps the "Ủng hộ InnerLamp" card
    Then the donation screen appears with the amount form

  Scenario: Reopen after a previous donation flow
    Given the user finished or dismissed the donation screen earlier
    When the user taps the card again
    Then the form is shown with the default amount and an empty message
  ```

#### Amount and message

**FR-002 — Preset amounts**
- **Priority:** Must
- **Description:** WHEN the form is shown THE SYSTEM SHALL offer the amounts 20.000₫, 50.000₫, 100.000₫,
  200.000₫, 500.000₫ and "Tùy tâm", with 50.000₫ selected, and WHEN the user taps one THE SYSTEM SHALL
  select only that option and show it in the action button as "Ủng hộ <amount>".
- **Verification method:** unit test (ViewModel)
- **Source:** prototype `spAmts`, `spCta`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Default selection
    Given the form is shown
    Then "50.000₫" is selected
    And the action button reads "Ủng hộ 50.000₫"

  Scenario: Choose another preset
    Given the form is shown
    When the user taps "200.000₫"
    Then only "200.000₫" is selected
    And the action button reads "Ủng hộ 200.000₫"
  ```

**FR-003 — Custom amount**
- **Priority:** Must
- **Description:** WHEN the user selects "Tùy tâm" THE SYSTEM SHALL show a numeric amount field that
  accepts digits only (up to 9 digits) and groups them with "." separators; the action button SHALL be
  disabled and read "Nhập từ 10.000₫" while the amount is below 10.000₫.
- **Verification method:** unit test (ViewModel)
- **Source:** prototype `spCustomOn`, `spSetCustom`, `ok = amt >= 10000`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Enter a valid custom amount
    Given the user selected "Tùy tâm"
    When the user types "150000"
    Then the field shows "150.000"
    And the action button reads "Ủng hộ 150.000₫" and is enabled

  Scenario Outline: Amount below the minimum
    Given the user selected "Tùy tâm"
    When the user types "<digits>"
    Then the action button reads "Nhập từ 10.000₫" and is disabled

    Examples:
      | digits |
      |        |
      | 9999   |

  Scenario: Non-digit and overlong input
    Given the user selected "Tùy tâm"
    When the user types "12a34 5678901234"
    Then only digits are kept
    And at most 9 digits are accepted

  Scenario: Minimum boundary
    Given the user selected "Tùy tâm"
    When the user types "10000"
    Then the action button is enabled
  ```

**FR-004 — Optional message**
- **Priority:** Should
- **Description:** THE SYSTEM SHALL let the user type an optional message of at most 120 characters
  under the placeholder "Lời nhắn đến đội ngũ (không bắt buộc)"; the message SHALL NOT be required.
- **Verification method:** unit test (ViewModel)
- **Source:** prototype `spMsg`, `maxLength=120`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Continue without a message
    Given a valid amount is selected and the message is empty
    When the user taps the action button
    Then the transfer step is shown

  Scenario: Message length limit
    Given the user is typing a message
    When the message reaches 120 characters
    Then further characters are not accepted
  ```

  > ⚠️ Not confirmed: where the message goes — with no backend call it is not delivered to anyone;
  > blocks whether the field should exist at all and its helper copy.

#### Transfer and confirmation

**FR-005 — Transfer QR and details**
- **Priority:** Must
- **Description:** WHEN the user taps the enabled action button THE SYSTEM SHALL show the title
  "Quét mã để chuyển khoản", a QR code, and a details table with recipient, bank, amount and transfer
  note, with the amount equal to the selected amount.
- **Verification method:** unit test (ViewModel/provider) + manual QA
- **Source:** prototype `spQr`, `spInfo`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Show transfer details
    Given the user selected "100.000₫"
    When the user taps "Ủng hộ 100.000₫"
    Then a QR code is shown
    And the details list the recipient, the bank, "100.000₫" and a transfer note

  Scenario: Change the amount
    Given the transfer step is shown
    When the user taps "Đổi số tiền"
    Then the form is shown again with the previous amount and message kept
  ```

  > ⚠️ Not confirmed: recipient name, bank, account number and QR payload — placeholders only until
  > provided; blocks release.

  > ⚠️ Not confirmed: transfer note rule — the prototype builds it as "UNGHO IL" + the first three digits
  > of the amount, which collides (20.000 and 200.000 both give "200"); blocks reconciliation of donations.

**FR-006 — Acknowledge transfer and thank**
- **Priority:** Must
- **Description:** WHEN the user taps "Tôi đã chuyển khoản" THE SYSTEM SHALL show the thank-you state
  ("Cảm ơn bạn") with the amount, and a "Quay lại" button. THE SYSTEM SHALL NOT claim the transfer was
  verified.
- **Verification method:** unit test (ViewModel) + manual QA
- **Source:** prototype `spThanks`; user answer "only show the thank-you, no API".
- **Acceptance criteria:**
  ```gherkin
  Scenario: Thank the user
    Given the transfer step is shown for "50.000₫"
    When the user taps "Tôi đã chuyển khoản"
    Then the thank-you state mentions "50.000₫"
    And a "Quay lại" button is shown
  ```

  > ⚠️ Not confirmed: the prototype line "Biên nhận đã được gửi vào Thông báo" (receipt sent to
  > Notifications) — with no backend nothing is sent, so the line must be removed or backed by a real
  > receipt; blocks the thank-you copy.

**FR-007 — Dismiss**
- **Priority:** Must
- **Description:** WHEN the user taps the close button, "Để sau" (form) or "Quay lại" (thanks) THE SYSTEM
  SHALL dismiss the screen and return to Profile; no state is retained.
- **Verification method:** unit test (coordinator) + manual QA
- **Source:** prototype `back`, `show-close`.
- **Acceptance criteria:**
  ```gherkin
  Scenario Outline: Dismiss from any step
    Given the "<step>" step is shown
    When the user taps the close button
    Then the user is back on Profile

    Examples:
      | step     |
      | form     |
      | transfer |
      | thanks   |

  Scenario: Nothing is kept
    Given the user dismissed the screen midway
    When the user opens it again
    Then the default amount and an empty message are shown
  ```

### 3.3 Performance requirements

- **NFR-001 — Responsiveness:** step changes and amount edits complete within one frame budget (16 ms);
  QR generation does not block the main thread.

### 3.4 Logical database requirements

None. No amount, message or donation record is persisted.

### 3.5 Design constraints

- Colors, fonts, spacing, icons only from `ILColors`, `ILTypography`, `ILMetrics`, `ILIcons`; new
  tokens are added to the token files if a prototype value has no match (e.g. the gold CTA gradient).
- ViewModel and Domain import only `Foundation`.
- User-facing strings are localized (`.localized`), Vietnamese primary.

### 3.6 Software system attributes

- **Reliability:** works fully offline.
- **Availability:** always available while the user is signed in.
- **Security:** no card or credential data handled; the receiving account details are public information
  but MUST NOT be a fabricated real-looking account. Message text is not logged (PII).
- **Maintainability:** account details and QR payload come from one replaceable provider.
- **Portability:** N/A.

---

## 4. Verification & traceability

### 4.1 Verification approach

Unit tests on the ViewModel (amount rules, state transitions), coordinator event test for entry and
dismissal, and manual QA on a physical device for visuals.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | prototype `profile` card | → spec-writer | 2 scenarios |
| FR-002 | prototype `spAmts` | → spec-writer | 2 scenarios |
| FR-003 | prototype `spCustom*` | → spec-writer | 4 scenarios |
| FR-004 | prototype `spMsg` | → spec-writer | 2 scenarios |
| FR-005 | prototype `spQr` | → spec-writer | 2 scenarios |
| FR-006 | prototype `spThanks` | → spec-writer | 1 scenario |
| FR-007 | prototype `back` | → spec-writer | 2 scenarios |
| NFR-001 | AGENTS.md 4.6 | → spec-writer | manual |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: real bank, account number, account holder and VietQR payload — blocks release.

> ⚠️ Not confirmed: transfer note rule (prototype collides on amounts such as 20.000 / 200.000) — blocks reconciliation.

> ⚠️ Not confirmed: "Biên nhận đã được gửi vào Thông báo" receipt claim with no backend — blocks thank-you copy.

> ⚠️ Not confirmed: destination of the optional message when no API is called — blocks the field's purpose.

> ⚠️ Not confirmed: App Store acceptance of an in-app external bank-transfer donation — may change presentation before release.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Real account / QR available? | No — mock behind a provider, block release | 2026-10-11 |
| What does "Tôi đã chuyển khoản" do? | Only show the thank-you state, no API call | 2026-10-11 |
| Amount and message rules | As prototype: presets 20k–500k, default 50k, custom ≥10.000₫ up to 9 digits, message ≤120 | 2026-10-11 |
| Entry points | Only the Profile card | 2026-10-11 |
