# Software Requirements Specification — MeritBook

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | MeritBook ("Sổ công đức" — the merit book / dedicated-merit ledger) |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-10-11 |
| Status | draft — data contract unconfirmed; UI built against sample data |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document specifies, at business level, the **MeritBook** screen of InnerLamp: the personal ledger
of the offerings (cúng dường) a practitioner has dedicated as merit (công đức hồi hướng). It drives
`spec-writer` and `ui-builder`.

### 1.2 Scope

**In scope:** a read-only screen showing yearly statistics, offering history, the temple's thank-you
letter, the monthly-support status (with a way to stop it) and the temple's public financial
disclosure for its current fundraising project.

**Out of scope:** the donation flow itself (choose temple/purpose/amount, QR transfer, completion),
starting monthly support, any payment processing, editing or deleting history entries.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (iOS, UIKit, Clean Architecture + MVVM-C). The merit book is
reached from the "Công đức đã hồi hướng" card on the "Tôi" (Profile) tab and is the user's record of
what they have given and what the temple has acknowledged.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Offering (cúng dường) | A monetary gift to a temple for a purpose, recorded with date, temple and amount. |
| Purpose | One of: Cúng dường Tam Bảo, Trai Tăng, Thỉnh đèn tại chùa, Xây dựng – trùng tu, Bếp cơm từ thiện, Phóng sinh. |
| Temple confirmation | The temple acknowledging it received the offering ("Chùa đã xác nhận" vs "Chờ chùa xác nhận"). |
| Thư tùy hỷ | A thank-you letter from the temple's abbot ("rejoicing letter"). |
| Hộ trì hằng tháng | A recurring monthly offering the user opted into. |
| Công khai tài chính | The temple's public disclosure of funds raised and spent for a project. |

### 1.5 References

- `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html` — screen `merit` (label "Sổ công đức"), state `dnHist` / `dnMonthlyOn`, constants `DN_HIST`, `DN_BUILD`.
- `Docs/Specs/Profile/` — entry point (merit card). `Docs/Specs/Offering/` — the (separate, unbuilt) donation flow.

### 1.6 Document organization

Section 2 describes context, section 3 the requirements, section 4 verification and traceability,
section 5 open questions.

---

## 2. Overall description

### 2.1 Product perspective

A new child screen of the "Tôi" tab. It consumes donation data that does not exist in the app yet
(the donation flow is not built and no API contract is confirmed), so it is built against sample data
behind a repository boundary.

### 2.2 Product functions

- Show offering statistics (`FR-002`)
- Show offering history (`FR-003`)
- Show the temple's thank-you letter (`FR-004`)
- Show and stop monthly support (`FR-005`)
- Show the temple's financial disclosure (`FR-006`)
- Navigate back / to the donation flow (`FR-001`, `FR-007`)

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Practitioner | A signed-in InnerLamp user | Sees only their own offerings. Read-only except for stopping monthly support. |

### 2.4 Operating environment

- Platform: iOS, minimum version as the app target. Devices: iPhone.
- Network: online required once a real API exists. ⚠️ See open questions (offline behavior).

### 2.5 Design and implementation constraints

- Swift + UIKit programmatic UI, Clean Architecture + MVVM-C per `AGENTS.md`.
- Header uses the shared sticky header pattern; all colors, fonts, spacing, icons from Design System tokens.

### 2.6 User documentation

**N/A** — no separate user documentation.

### 2.7 Assumptions and dependencies

- **Assumptions:** see `Docs/Assumptions/MeritBook/`.
- **Dependencies:** a donation-history / disclosure API (not confirmed); the donation flow (`Offering`) for the header "Cúng dường" action and for creating the data this screen shows.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

One screen, "Sổ công đức", with a sticky header (back, title, subtitle "Công đức đã hồi hướng", pill
action "Cúng dường") over a vertical scroll of five blocks, following the prototype screen `merit`.

#### 3.1.2 Hardware interfaces
**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

Contract not yet confirmed: reading the user's offering history, the temple letter, the monthly
support and the temple's disclosure, and stopping monthly support.

> ⚠️ Not confirmed: the API contract (endpoints, fields, errors) for the merit book — blocks replacing the sample data.

#### 3.1.4 Communication interfaces
**N/A** until the API contract is confirmed.

### 3.2 Functional requirements

#### Screen

**FR-001 — Header and navigation**
- **Priority:** Must
- **Description:** WHEN the screen is shown THE SYSTEM SHALL show a header with a back control, the title "Sổ công đức", the subtitle "Công đức đã hồi hướng" and a "Cúng dường" action; WHEN the user taps back THE SYSTEM SHALL return to the previous screen.
- **Verification method:** unit test (navigation event), manual QA
- **Source:** prototype screen `merit`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Back returns to Profile
    Given the user opened the merit book from the Profile tab
    When the user taps back
    Then the merit book closes and Profile is shown
  ```

**FR-002 — Offering statistics**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL show three figures: the total given in the current calendar year, the number of "Thỉnh đèn tại chùa" offerings, and the number of distinct temples given to.
- **Verification method:** unit test
- **Source:** prototype `mr.stats`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Figures reflect the history
    Given the user gave 100.000đ and 1.100.000đ in this year, one of them for a temple lamp, to one temple, and 200.000đ last year to another temple
    When the merit book opens
    Then the year total reads "1,2 tr", the lamp count reads 1 and the temple count reads 2

  Scenario: No offerings
    Given the user has no offerings
    When the merit book opens
    Then all three figures read 0
  ```

**FR-003 — Offering history**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL list the user's offerings newest first, each with purpose, temple, date, amount and a status ("Chùa đã xác nhận" or "Chờ chùa xác nhận").
- **Verification method:** unit test, manual QA
- **Source:** prototype `mr.hist`
- **Acceptance criteria:**
  ```gherkin
  Scenario: History is ordered and labelled
    Given the user has a confirmed offering from September and an unconfirmed one from August
    When the merit book opens
    Then September is listed first marked "Chùa đã xác nhận" and August second marked "Chờ chùa xác nhận"

  Scenario: Empty history
    Given the user has no offerings
    When the merit book opens
    Then a short note says there are no offerings yet
  ```
  > ⚠️ Not confirmed: the empty-history wording and layout (not in the prototype) — assumed, see `AS-MeritBook-003`.

**FR-004 — Temple letter**
- **Priority:** Should
- **Description:** WHEN the temple has sent a thank-you letter THE SYSTEM SHALL show its text and the signer's name and title; otherwise THE SYSTEM SHALL hide the block.
- **Verification method:** unit test, manual QA
- **Source:** prototype "Thư tùy hỷ"
- **Acceptance criteria:**
  ```gherkin
  Scenario: Letter present
    Given the temple sent a letter signed by the abbot
    When the merit book opens
    Then the letter text and the signature line are shown

  Scenario: No letter
    Given the temple has not sent a letter
    When the merit book opens
    Then the "Thư tùy hỷ" block is not shown
  ```
  > ⚠️ Not confirmed: whether a user can have several letters and which one is shown — blocks the data model.

**FR-005 — Monthly support**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL show the active monthly support (amount per month, temple, reminder day) with a "Dừng" action, or a note that it is not enabled; WHEN the user taps "Dừng" THE SYSTEM SHALL stop it and show the not-enabled note.
- **Verification method:** unit test, manual QA
- **Source:** prototype `mr.monthlyOn` / `mr.stop`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Stop monthly support
    Given monthly support of 100.000đ for a temple is active
    When the user taps "Dừng"
    Then the card is replaced by the note "Chưa bật hộ trì hằng tháng…"

  Scenario: Stop fails
    Given monthly support is active and stopping it fails
    When the user taps "Dừng"
    Then the user is told it could not be stopped and support remains shown as active
  ```
  > ⚠️ Not confirmed: whether stopping asks for confirmation and what happens to an already-scheduled payment — blocks FR-005 behavior and the failure scenario's final wording.

**FR-006 — Financial disclosure**
- **Priority:** Should
- **Description:** WHEN the temple publishes a fundraising project THE SYSTEM SHALL show its name, temple and round, amount raised vs goal with a percentage and progress bar, itemised spending, and the last update date; otherwise THE SYSTEM SHALL hide the block.
- **Verification method:** unit test, manual QA
- **Source:** prototype `mr.build`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Project shown with progress
    Given a project with 412 of 600 million raised
    When the merit book opens
    Then it shows "412 / 600 triệu đồng", 69% and a proportional progress bar

  Scenario: No project
    Given the temple has no published project
    When the merit book opens
    Then the "Công khai tài chính" block is not shown
  ```

**FR-007 — Open donation from the header**
- **Priority:** Could
- **Description:** WHEN the user taps "Cúng dường" in the header THE SYSTEM SHALL open the donation flow.
- **Verification method:** unit test (navigation event)
- **Source:** prototype `on-action="goDonate"`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Donate from the merit book
    Given the merit book is shown
    When the user taps "Cúng dường"
    Then the donation flow opens
  ```
  > ⚠️ Not confirmed: the donation flow does not exist yet — the tap currently has no destination.

**FR-008 — Loading and failure**
- **Priority:** Must
- **Description:** WHEN the data cannot be loaded THE SYSTEM SHALL show an error state instead of the blocks.
- **Verification method:** unit test, manual QA
- **Source:** gap found during analysis (not in the prototype)
- **Acceptance criteria:**
  ```gherkin
  Scenario: Load fails
    Given the merit book data cannot be loaded
    When the merit book opens
    Then an error message is shown and no figures are shown
  ```

### 3.3 Performance requirements

- **NFR-001 — Responsiveness:** scrolling stays at 60 fps; mapping and formatting never block the main thread noticeably for lists of up to 200 offerings.

### 3.4 Logical database requirements

- No local persistence in this version; data is held in memory for the session.

### 3.5 Design constraints

- Design System tokens only (no hard-coded colors/fonts/spacing/icons); shared sticky header pattern.

### 3.6 Software system attributes

- **Reliability:** failures surface as an error state, never a crash.
- **Availability:** depends on the future API.
- **Security:** amounts and temple names are personal financial data — not logged raw (`PIIMasker` rules).
- **Maintainability:** data source is behind a repository protocol so sample data can be swapped for the API without UI change.
- **Portability:** N/A.

---

## 4. Verification & traceability

### 4.1 Verification approach

Unit tests on the ViewModel (mapping, ordering, formatting, navigation events) and UseCase; manual QA on
a physical device for layout, dark mode and scrolling.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | prototype `merit` header | → spec-writer | 1 Gherkin scenario |
| FR-002 | prototype `mr.stats` | → spec-writer | 2 Gherkin scenarios |
| FR-003 | prototype `mr.hist` | → spec-writer | 2 Gherkin scenarios |
| FR-004 | prototype letter block | → spec-writer | 2 Gherkin scenarios |
| FR-005 | prototype monthly block | → spec-writer | 2 Gherkin scenarios |
| FR-006 | prototype disclosure block | → spec-writer | 2 Gherkin scenarios |
| FR-007 | prototype `goDonate` | → spec-writer | 1 Gherkin scenario |
| FR-008 | analysis gap | → spec-writer | 1 Gherkin scenario |
| NFR-001 | analysis | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: the merit book API contract — blocks replacing sample data (`TD-MeritBook-001`).

> ⚠️ Not confirmed: the destination of the header "Cúng dường" action — blocks `FR-007` (`TD-MeritBook-002`).

> ⚠️ Not confirmed: how "year total" and "lamp count" are defined when offerings have different statuses (pending counted?) — assumed all offerings count, see `AS-MeritBook-002`.

> ⚠️ Not confirmed: offline behavior and caching of the merit book — blocks the failure/offline design.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Which screen is "công đức hồi hướng"? | The "Sổ công đức" screen (prototype `merit`), not the donation flow | 2026-10-11 |
| Where does the data come from for now? | Sample data behind a repository protocol | 2026-10-11 |
| Scope of blocks? | All five blocks as in the prototype | 2026-10-11 |
