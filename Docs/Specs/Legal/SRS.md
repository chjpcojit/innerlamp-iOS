# Software Requirements Specification — Legal

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Legal (Điều khoản sử dụng & Chính sách quyền riêng tư) |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-10-10 |
| Status | draft — document text and effective date are mocked; API unconfirmed |
| Owner / author | Product / BA (prepared by ba-writer) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

Define a full-page screen where the user reads the Terms of Use and the Privacy Policy from Settings.

### 1.2 Scope

**In scope:** one screen with two documents (Terms, Privacy) switched by a segmented control, each a
list of titled sections, plus a shortcut to Contact Support.

**Out of scope:** the bottom sheet shown during sign-up (`ILSignUpLegalSheetViewController`, owned by
SignUp), acceptance/consent recording, account deletion.

### 1.3 Product overview

Reached from Settings → "Hỗ trợ & pháp lý" via two rows ("Điều khoản sử dụng", "Chính sách quyền riêng
tư"); the row decides which document opens first.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Terms | "Điều khoản sử dụng", six numbered sections |
| Privacy | "Chính sách quyền riêng tư", five sections |
| Effective line | Text "Hiệu lực từ 01/09/2026 · InnerLamp 1.4" under the title |

### 1.5 References

- Prototype screen `legal`, data `Component.LEGAL`
- Existing localized content `legal.*` used by `ILSignUpLegalSheetViewController`

### 1.6 Document organization
Standard IEEE 29148; open questions in Appendix A.

---

## 2. Overall description

### 2.1 Product perspective

New screen. Content currently exists as localized strings for the sign-up sheet; the same text should
be a single source of truth for both surfaces. A future API may serve versioned documents.

### 2.2 Product functions

- Open the chosen document from Settings (`FR-001`)
- Switch between Terms and Privacy (`FR-002`)
- Show document title, effective line and sections (`FR-003`)
- Shortcut to Contact Support (`FR-004`)

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Practitioner | Signed-in app user | Read-only |

### 2.4 Operating environment

iOS, iPhone; works offline with bundled text.

### 2.5 Design and implementation constraints

MVVM-C + Clean Architecture; Design System tokens; scrollable long text must stay smooth (AGENTS.md 4.6).

### 2.6 User documentation
**N/A** — this screen is the user documentation.

### 2.7 Assumptions and dependencies

- **Assumptions:** the text in the prototype is accepted legal copy for now; "Hiệu lực từ 01/09/2026 · InnerLamp 1.4" is mock text; the Terms statement "xóa tài khoản trong Cài đặt" may not match an implemented feature.
- **Dependencies:** Settings rows, Contact Support, localization files.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

Navigation bar titled with the current document, segmented control (Điều khoản | Quyền riêng tư),
document title, effective line, a card of sections (heading + body), and a "Có câu hỏi về …?" shortcut.
Visual spec: prototype screen `legal`.

#### 3.1.2 Hardware interfaces
**N/A**.

#### 3.1.3 Software interfaces
Document retrieval API: contract not yet confirmed; bundled mock content used.

> ⚠️ Not confirmed: legal-document API (endpoint, versioning, effective date, language) — blocks replacing bundled content.

#### 3.1.4 Communication interfaces
**N/A** while bundled.

### 3.2 Functional requirements

**FR-001 — Open the selected document**
- **Priority:** Must
- **Description:** WHEN the user taps "Điều khoản sử dụng" or "Chính sách quyền riêng tư" in Settings THE SYSTEM SHALL open the Legal screen showing that document.
- **Verification method:** coordinator unit test; manual QA
- **Source:** Prototype `goTermsPage`, `goPrivacyPage`
- **Acceptance criteria:**
  ```gherkin
  Scenario Outline: Open from Settings
    Given the user is on Settings
    When the user taps "<row>"
    Then the Legal screen opens on the "<document>" document

    Examples:
      | row                        | document      |
      | Điều khoản sử dụng         | Terms         |
      | Chính sách quyền riêng tư  | Privacy       |
  ```

**FR-002 — Switch document**
- **Priority:** Must
- **Description:** WHEN the user taps the other segment THE SYSTEM SHALL show that document and update the title and navigation bar title.
- **Verification method:** unit test
- **Source:** Prototype `lgpTabs`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Switch to Privacy
    Given the Terms document is shown
    When the user taps "Quyền riêng tư"
    Then the Privacy policy is shown
    And the screen title is "Chính sách quyền riêng tư"

  Scenario: Switch resets scroll
    Given the user has scrolled down Terms
    When the user switches to Privacy
    Then the document starts from the top
  ```
  > ⚠️ Not confirmed: whether switching should reset scroll position (prototype is silent) — blocks scroll behavior; reset assumed.

**FR-003 — Show document content**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL show the document title, the effective line and every section in order, each with heading and body.
- **Verification method:** unit test; manual QA
- **Source:** Prototype `lgpSecs`
- **Acceptance criteria:**
  ```gherkin
  Scenario Outline: Section counts
    Given the "<document>" document is shown
    Then "<count>" sections are listed in order

    Examples:
      | document | count |
      | Terms    | 6     |
      | Privacy  | 5     |

  Scenario: Content cannot be loaded
    Given the document content is unavailable
    When the user opens Legal
    Then an error state with a retry action is shown
  ```
  > ⚠️ Not confirmed: the effective date and version string — prototype shows "01/09/2026 · InnerLamp 1.4"; source (API vs app version) undecided; mock text used.

> ⚠️ Not confirmed: whether the Terms claim "account can be deleted in Settings" matches an existing feature — blocks legal-copy sign-off; text kept verbatim.

**FR-004 — Shortcut to Contact Support**
- **Priority:** Should
- **Description:** WHEN the user taps the "Có câu hỏi về {điều khoản | quyền riêng tư}?" card THE SYSTEM SHALL open Contact Support.
- **Verification method:** manual QA
- **Source:** Prototype `goContact`
- **Acceptance criteria:**
  ```gherkin
  Scenario: Open Contact Support
    Given the Privacy document is shown
    When the user taps the question card
    Then the Contact Support screen opens
    And the card text mentions "quyền riêng tư"
  ```

### 3.3 Performance requirements

- **NFR-001 — Smooth scrolling:** long documents scroll without dropped frames; text is laid out once per document switch.

### 3.4 Logical database requirements
**N/A** — no persisted user data.

### 3.5 Design constraints
Content strings localized (`legal.*`), reused from the sign-up sheet where identical; Design System tokens.

### 3.6 Software system attributes

- **Reliability:** works offline.
- **Availability:** N/A.
- **Security:** no PII; content is read-only.
- **Maintainability:** one source of document text shared with the sign-up sheet.
- **Portability:** N/A.

---

## 4. Verification & traceability

### 4.1 Verification approach
XCTest for ViewModel/UseCase; manual device QA for layout.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Prototype `goTermsPage`/`goPrivacyPage` | → spec-writer | 1 outline (2 examples) |
| FR-002 | Prototype `lgpTabs` | → spec-writer | 2 scenarios |
| FR-003 | Prototype `lgpSecs` | → spec-writer | 2 scenarios |
| FR-004 | Prototype `goContact` | → spec-writer | 1 scenario |
| NFR-001 | AGENTS.md 4.6 | → spec-writer | Manual |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: legal-document API (endpoint, versioning, effective date, language) — blocks replacing bundled content.

> ⚠️ Not confirmed: source of the effective date and version line — mock text used.

> ⚠️ Not confirmed: whether "delete account in Settings" exists — blocks legal-copy sign-off.

> ⚠️ Not confirmed: scroll reset on document switch — reset assumed.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Legal text and effective date handling | Mock verbatim, record Assumption | 2026-10-10 |
| Content source | Bundled mock; API provided later by user | 2026-10-10 |
