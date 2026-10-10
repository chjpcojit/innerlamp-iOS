# Software Requirements Specification — Help

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Help (Frequently asked questions) |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-10-10 |
| Status | draft — FAQ content source is mocked; backend contract unconfirmed |
| Owner / author | Product / BA (prepared by ba-writer) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

Define what the Help screen ("Trợ giúp") must do so a practitioner can resolve common questions
without contacting support. Drives `spec-writer` and `ui-builder`.

### 1.2 Scope

**In scope:** a Help screen with an intro/search entry, an accordion list of FAQ items, and a
footer that leads to the Contact Support screen.

**Out of scope:** the Search screen itself, the Contact Support screen (see `Docs/Specs/ContactSupport/`),
the Settings row that opens Help (owned by Settings), and any backend/CMS for FAQ content.

### 1.3 Product overview

InnerLamp is a Vietnamese Buddhist practice app (sutra reading, talks, meditation, lamp lighting,
offerings). Help is a leaf screen reached from Settings → "Nội dung & trợ giúp".

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| FAQ | Frequently asked question and its answer |
| Accordion | List where tapping an item expands its answer; only one item is open at a time |
| Ban hỗ trợ | The InnerLamp support team (the single term used across the app; "ban hộ trì" is retired) |

### 1.5 References

- `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html` — screen `faq`
- `Docs/innerlamp-project/project/docs/Mo-ta-tinh-nang.md` — section "Trợ giúp"
- `Docs/Specs/Help/requirements.md` (previous prospective spec, superseded in content by this SRS)

### 1.6 Document organization

Section 2 gives context, section 3 the requirements, section 4 traceability, appendix A open questions.

---

## 2. Overall description

### 2.1 Product perspective

New leaf screen in the Settings flow. Static bundled content for now; a future API will supply FAQ
items (contract not yet provided).

### 2.2 Product functions

- Show FAQ as a single-open accordion (`FR-001`, `FR-002`)
- Open the Search screen from the search field (`FR-003`)
- Offer a path to contact support (`FR-004`)
- Loading / empty / failure presentation of FAQ content (`FR-005`)

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Practitioner | Signed-in app user | Read-only access; no write actions |

### 2.4 Operating environment

- Platform: iOS, minimum version as per the project deployment target.
- Devices: iPhone.
- Network: bundled mock content works offline; a future API-backed version may need network.

### 2.5 Design and implementation constraints

- Swift, UIKit programmatic UI, MVVM-C + Clean Architecture per `AGENTS.md`.
- All colors/typography/metrics/icons come from the Design System tokens.
- User-facing strings are localized.

### 2.6 User documentation

**N/A** — this screen is itself user documentation.

### 2.7 Assumptions and dependencies

- **Assumptions:** FAQ content is the 5-item set in the latest prototype (see AS-Help entry to be created). Content is mocked behind a Repository/UseCase so the real API can replace it.
- **Dependencies:** Settings (entry row), Search screen (not yet built in iOS), Contact Support screen.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

One screen: navigation bar "Trợ giúp", search entry "Bạn đang cần giúp điều gì?", accordion of FAQ
cards, and a highlighted footer card "Vẫn chưa rõ?" with a button to contact support. Visual spec:
prototype screen `faq`.

#### 3.1.2 Hardware interfaces
**N/A** — no hardware interface.

#### 3.1.3 Software interfaces
FAQ list retrieval: contract not yet confirmed. Mocked locally for now.

> ⚠️ Not confirmed: FAQ API contract (endpoint, fields, language handling) — blocks replacing the mock data source.

#### 3.1.4 Communication interfaces
**N/A** while content is mocked; HTTPS/JSON expected once an API exists.

### 3.2 Functional requirements

#### FAQ list

**FR-001 — Show FAQ accordion**
- **Priority:** Must
- **Description:** WHEN the Help screen opens THE SYSTEM SHALL show the FAQ questions as collapsed cards.
- **Verification method:** unit test (ViewModel state) + manual QA against prototype
- **Source:** Prototype screen `faq`; Mo-ta-tinh-nang "Trợ giúp"
- **Acceptance criteria:**
  ```gherkin
  Scenario: Questions are listed collapsed
    Given the user opens Help
    Then five questions are shown
    And no answer is visible

  Scenario: Question order matches the content source
    Given the FAQ content contains questions in a defined order
    When the user opens Help
    Then the questions appear in that same order
  ```

**FR-002 — Expand one answer at a time**
- **Priority:** Must
- **Description:** WHEN the user taps a question THE SYSTEM SHALL expand its answer and collapse any other open answer; tapping the open question SHALL collapse it.
- **Verification method:** unit test
- **Source:** Prototype `faqOpen`; Mo-ta-tinh-nang "Trợ giúp"
- **Acceptance criteria:**
  ```gherkin
  Scenario: Expand a question
    Given all questions are collapsed
    When the user taps the first question
    Then its answer is visible
    And the question shows the open state

  Scenario: Open a second question
    Given the first question is open
    When the user taps the second question
    Then the second answer is visible
    And the first answer is hidden

  Scenario: Collapse the open question
    Given the first question is open
    When the user taps the first question
    Then all answers are hidden
  ```

#### Navigation

**FR-003 — Open Search from the search field**
- **Priority:** Should
- **Description:** WHEN the user taps the search field THE SYSTEM SHALL open the Search screen.
- **Verification method:** manual QA
- **Source:** Prototype `goSearch`
- **Acceptance criteria:**
  ```gherkin
  @not-confirmed
  Scenario: Tap the search field
    Given the user is on Help
    When the user taps the search field
    Then the Search screen opens
  ```
  > ⚠️ Not confirmed: whether the Search screen exists in the iOS app by this release and whether it should be pre-scoped to help content — blocks FR-003 wiring (until then the field is inert).

**FR-004 — Go to Contact Support from the footer**
- **Priority:** Must
- **Description:** WHEN the user taps "Gửi thư cho ban hỗ trợ" in the footer THE SYSTEM SHALL open Contact Support.
- **Verification method:** manual QA / coordinator unit test
- **Source:** Prototype `goContact`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Footer button opens Contact Support
    Given the user is on Help
    When the user taps the footer button
    Then the Contact Support screen opens
    And back returns to Help
  ```

#### Content states

**FR-005 — Loading, empty and failure states**
- **Priority:** Should
- **Description:** WHEN FAQ content is loading, empty, or fails to load THE SYSTEM SHALL show the corresponding state instead of a blank list.
- **Verification method:** unit test
- **Source:** Silent gap found by BA (not in prototype for this screen)
- **Acceptance criteria:**
  ```gherkin
  @not-confirmed
  Scenario: Content fails to load
    Given FAQ content cannot be loaded
    When the user opens Help
    Then an error state with a retry action is shown
  ```
  > ⚠️ Not confirmed: wording and design of the empty/failure state — blocks final UI copy; design system `IL-State` assumed.

### 3.3 Performance requirements

- **NFR-001 — Responsive accordion:** expanding/collapsing completes without dropped frames on a supported device (16 ms/frame budget per AGENTS.md 4.6).

### 3.4 Logical database requirements
**N/A** — no persisted data; FAQ content is read-only.

### 3.5 Design constraints

- Design System tokens only; no hard-coded values (AGENTS.md 4.5).
- ViewModel/Domain import only Foundation.

### 3.6 Software system attributes

- **Reliability:** screen remains usable offline with bundled content.
- **Availability:** N/A.
- **Security:** no PII handled.
- **Maintainability:** content isolated behind a repository so the source can change without UI changes.
- **Portability:** N/A.

---

## 4. Verification & traceability

### 4.1 Verification approach

ViewModel/UseCase behavior by XCTest; layout and copy by manual QA on device against the prototype.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Prototype `faq` | → spec-writer | 2 scenarios |
| FR-002 | Prototype `faqOpen` | → spec-writer | 3 scenarios |
| FR-003 | Prototype `goSearch` | → spec-writer | 1 scenario (@not-confirmed) |
| FR-004 | Prototype `goContact` | → spec-writer | 1 scenario |
| FR-005 | BA gap | → spec-writer | 1 scenario (@not-confirmed) |
| NFR-001 | AGENTS.md 4.6 | → spec-writer | Manual (device) |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: FAQ API contract (endpoint, fields, language handling) — blocks replacing the mock data source.

> ⚠️ Not confirmed: whether the Search screen exists in the iOS app by this release and whether it should be pre-scoped to help content — blocks FR-003 wiring.

> ⚠️ Not confirmed: wording and design of the empty/failure state — blocks FR-005 UI copy.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Which FAQ set: prototype (free, no plans) or old spec (with "gia hạn Sen Vàng")? | Prototype's latest 5-item set; old spec superseded | 2026-10-10 |
| Name of the support team: "ban hỗ trợ" or "ban hộ trì"? | "Ban hỗ trợ" everywhere | 2026-10-10 |
| FAQ content source? | Bundled mock for now; API supplied later by user | 2026-10-10 |
