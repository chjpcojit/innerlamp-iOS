# Software Requirements Specification — LightLamp

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | LightLamp |
| Product | InnerLamp |
| Version | 0.3 (draft) |
| Last updated | 2026-10-11 |
| Status | draft — awaiting confirmation of open questions |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document specifies, at business level, the **LightLamp** feature of InnerLamp: a virtual
"light a lamp" (Thắp đèn) flow and a "Lamp Garden" (Vườn đèn) screen that lists lit lamps. It is the
input for `spec-writer`, which will derive the engineering spec.

### 1.2 Scope

**In scope:**

- The *Thắp đèn* screen: choose lamp kind, intention, dedication target, optional vow and lighting
  duration, then light the lamp with an animated sequence and a completion state.
- The *Vườn đèn* screen: grid of lit lamps, filter by lamp kind, incremental "see more".
- Local persistence of the lamps the user has lit.

**Out of scope:**

- Paid temple offering ("Cúng dường đèn"), the donation form, and the receipt screens.
- "Thỉnh đèn tại chùa" (temple lights a real lamp) — it depends on the donation flow.
- Any server-side lamp or community-garden API (no contract exists).

### 1.3 Product overview

InnerLamp is a Buddhist companion app (iOS, UIKit, Clean Architecture + MVVM-C). LightLamp lets a
practitioner light a symbolic lamp with an intention and dedicate its merit to someone, then see the
lamps in a shared garden view. It sits beside Home, Memorial and Meditation as a practice feature.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Lamp (đèn) | A symbolic lamp the user lights; has a kind, an intention, a dedication target, an optional vow and a lighting duration. |
| Lamp kind | One of: Đèn dầu (oil lamp), Nến sen (lotus candle), Hoa đăng (floating lotus lantern). |
| Intention (tâm nguyện) | One of: Cầu an (peace), Hồi hướng (dedication), Cầu siêu (for the departed), Tri ân (gratitude). |
| Dedication target (Dành cho) | Free-text name of who the lamp is for; defaults to "Tất cả chúng sanh" (all beings). |
| Vow (lời nguyện) | Optional free-text wish written for the lamp. |
| Lighting duration | How long the lamp stays lit: 1, 7, 21 or 49 days. |
| Lamp Garden (Vườn đèn) | The screen listing lit lamps. |
| My lamp | A lamp lit by the current user on this device. |

### 1.5 References

- `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html` — screens `offer` and `garden`, logic `lpOpen` / `lpLight` / `lpAgainFn` / `lampDonateVals`.
- `Docs/innerlamp-project/project/IL-LampArt.dc.html` — lamp artwork component.
- `Docs/innerlamp-project/project/docs/Mo-ta-tinh-nang.md`.
- `Docs/Specs/Offering/` — separate, paid offering flow; unchanged by this feature.
- `Docs/Specs/Home/SRS.md`, `Docs/Specs/Main/` — candidate entry points.

### 1.6 Document organization

§2 describes the feature at product level; §3 lists functional and non-functional requirements; §4
gives verification and traceability; Appendix A lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

A **new feature**. It has no backend: lit lamps are stored on the device. The paid Offering feature is a
separate, future flow and shares only the visual language.

### 2.2 Product functions

- Present the lamp-lighting form with sensible defaults (`FR-001`, `FR-002`, `FR-003`).
- Light a lamp with animation and persist it (`FR-004`, `FR-012`).
- Show the completion state and offer next actions (`FR-005`, `FR-006`).
- Show the Lamp Garden with filter and incremental loading (`FR-008`, `FR-009`, `FR-013`).
- Move between the two screens (`FR-007`, `FR-010`).
- Keep lamps lit only for their chosen duration (`FR-011`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Signed-in user or guest | Any user who reaches the entry point. | May light lamps and view the garden; no special permission. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone.
- Network: not required (local-only data).

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; Domain and ViewModels import only `Foundation`.
- No hardcoded text, color, font, spacing or icon: use the localization system, `ILColors`,
  `ILTypography`, `ILMetrics`, `ILIcons`.
- Lists must update incrementally and keep the main thread free (AGENTS.md §4.6).

### 2.6 User documentation

**N/A** — consumer app feature; no separate manual.

### 2.7 Assumptions and dependencies

- **Assumptions:** lamps are private to the device until a backend exists (see Appendix A).
- **Dependencies:** `DIContainer`, Core Data stack, a navigation entry point (Home row and/or tab
  button), the display-name source used by Home.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

Two screens, each with a header (back button; right-hand action linking to the other screen):

1. **Thắp đèn** — a hero stage with the lamp artwork, then option groups, then a fixed bottom button.
2. **Vườn đèn** — pinned header with filter chips, then a two-column grid of lamp cards.

Visual details follow the prototype and the Design System tokens.

#### 3.1.2 Hardware interfaces

**N/A** — no custom hardware interface.

#### 3.1.3 Software interfaces

No network contract. Local persistence only (see §3.4).

#### 3.1.4 Communication interfaces

**N/A** — no network communication in this feature.

### 3.2 Functional requirements

#### Light a lamp

**FR-001 — Show the lighting form**
- **Priority:** Must
- **Description:** WHEN the user opens the Thắp đèn screen THE SYSTEM SHALL show the hero stage with an
  unlit lamp, the headline "Thắp một ngọn đèn, hồi hướng cho người thương", a line stating how many lamps
  the user already has in the garden (or that the lamp will shine in the garden), the option groups,
  and the "Thắp đèn" button.
- **Verification method:** UI test + manual QA
- **Source:** Prototype screen `offer`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Open with no lamps lit yet
    Given the user has not lit any lamp
    When the user opens the lighting screen
    Then the headline "Thắp một ngọn đèn, hồi hướng cho người thương" is shown
    And the line "Ngọn đèn sẽ sáng trong Vườn đèn" (the lamp will shine in the garden) is shown
    And the lamp on the stage is unlit

  Scenario: Open with existing lamps
    Given the user has 3 active lamps
    When the user opens the lighting screen
    Then the line "Bạn có 3 ngọn đèn trong vườn" (you have 3 lamps in the garden) is shown
  ```

**FR-002 — Choose kind, intention and duration**
- **Priority:** Must
- **Description:** WHEN the lighting form is shown THE SYSTEM SHALL preselect "Đèn dầu", "Cầu an" and
  "7 ngày", and WHEN the user taps another option in a group THE SYSTEM SHALL select it exclusively and
  update the stage kicker "ĐÈN · <KIND>" and lamp artwork for kind changes.
- **Verification method:** unit test (ViewModel) + UI test
- **Source:** Prototype `lpKind`, `lpIntent`, `lpDays`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Defaults on a fresh form
    Given the lighting form has just opened
    Then "Đèn dầu", "Cầu an" and "7 ngày" are selected

  Scenario: Change lamp kind
    Given the lighting form is shown
    When the user selects "Hoa đăng"
    Then only "Hoa đăng" is highlighted in the kind group
    And the stage kicker reads "ĐÈN · HOA ĐĂNG"
    And the stage shows the floating-lotus lamp

  Scenario Outline: Change duration
    Given the lighting form is shown
    When the user selects "<days> ngày"
    Then only that duration is highlighted

    Examples:
      | days |
      | 1    |
      | 21   |
      | 49   |
  ```

**FR-003 — Dedication target and vow**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL let the user type a dedication target ("Dành cho") and an optional
  vow; WHEN the target is empty or whitespace only THE SYSTEM SHALL use "Tất cả chúng sanh".
- **Verification method:** unit test (ViewModel)
- **Source:** Prototype `lpFor`, `lpVow`, `lpLight`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Empty target defaults to all beings
    Given the target field is empty
    When the user lights the lamp
    Then the lamp is dedicated to "Tất cả chúng sanh"

  Scenario: Whitespace-only target defaults to all beings
    Given the target field contains only spaces
    When the user lights the lamp
    Then the lamp is dedicated to "Tất cả chúng sanh"

  Scenario: Vow is optional
    Given the vow field is empty
    When the user lights the lamp
    Then the lamp is lit without a vow
  ```

> ⚠️ Not confirmed: maximum length of the dedication target and the vow — decides input limits and card truncation rules.

**FR-004 — Light the lamp**
- **Priority:** Must
- **Description:** WHEN the user taps "Thắp đèn" THE SYSTEM SHALL disable the button and show
  "Đang thắp…" (lighting) while the lamp artwork ignites over about 2 seconds, save the lamp, and then
  move the stage to the completion state; WHILE lighting THE SYSTEM SHALL ignore further taps.
- **Verification method:** unit test (ViewModel) + manual QA (animation)
- **Source:** Prototype `lpLight`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Light a lamp
    Given the lighting form is shown with default choices
    When the user taps "Thắp đèn"
    Then the button reads "Đang thắp…" and cannot be tapped again
    And the lamp artwork ignites
    And afterwards the completion state is shown

  Scenario: Repeated tap does not create duplicates
    Given the lamp is being lit
    When the user taps the button again
    Then only one lamp is saved
  ```

**FR-005 — Completion state**
- **Priority:** Must
- **Description:** WHEN a lamp has been lit THE SYSTEM SHALL show "Đèn đã được thắp", a caption with kind,
  intention and remaining days, the dedication line "Nguyện đem công đức này hồi hướng cho <target>" (or
  "…cho tất cả chúng sanh"), the vow in quotation marks when present, and the actions "Thắp thêm đèn"
  and "Vào vườn đèn".
- **Verification method:** unit test (ViewModel) + manual QA
- **Source:** Prototype `lp.isDone`, `lp.ded`, `lp.vowQ`, `lp.caption`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Completion with target and vow
    Given the user lit a lamp for "Mẹ" with the vow "Mẹ luôn khỏe"
    Then "Đèn đã được thắp" is shown
    And the dedication line names "Mẹ"
    And the vow "Mẹ luôn khỏe" is shown in quotation marks

  Scenario: Completion for all beings without vow
    Given the user lit a lamp with no target and no vow
    Then the dedication line says it is for all beings
    And no vow line is shown
  ```

**FR-006 — Light another lamp**
- **Priority:** Must
- **Description:** WHEN the user taps "Thắp thêm đèn" THE SYSTEM SHALL return to the form with an unlit
  lamp, cleared target and vow, and keep the previously chosen kind, intention and duration.
- **Verification method:** unit test (ViewModel)
- **Source:** Prototype `lpAgainFn` (clears `lpFor`, `lpVow` only).
- **Acceptance criteria:**
  ```gherkin
  Scenario: Light another
    Given the completion state is shown
    When the user taps "Thắp thêm đèn"
    Then the form is shown with an unlit lamp
    And the target and vow fields are empty
    And the previous kind, intention and duration are still selected
  ```

#### Navigation

**FR-007 — Go to the garden from the lighting screen**
- **Priority:** Must
- **Description:** WHEN the user taps "Vườn đèn" in the header, or "Vào vườn đèn" in the completion
  state, THE SYSTEM SHALL open the Lamp Garden.
- **Verification method:** unit test (coordinator event) + manual QA
- **Source:** Prototype `goGarden`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Garden from header
    Given the lighting form is shown
    When the user taps "Vườn đèn" in the header
    Then the Lamp Garden is shown

  Scenario: Garden from completion
    Given the completion state is shown
    When the user taps "Vào vườn đèn"
    Then the Lamp Garden is shown
  ```

**FR-010 — Go to lighting from the garden**
- **Priority:** Must
- **Description:** WHEN the user taps "Thắp đèn" in the garden header THE SYSTEM SHALL open a fresh
  lighting form.
- **Verification method:** unit test (coordinator event)
- **Source:** Prototype garden `NavBar` action `goOffer`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Light from garden
    Given the Lamp Garden is shown
    When the user taps "Thắp đèn" in the header
    Then a fresh lighting form is shown with default choices
  ```

> Resolved 2026-10-11: the center tab-bar lamp button opens Thắp đèn (product owner instruction). ⚠️ Not confirmed: which other entry points (Memorial, Temple) are in scope — decides Main/Home coordinator changes.

#### Lamp Garden

**FR-008 — Show the garden**
- **Priority:** Must
- **Description:** WHEN the Lamp Garden opens THE SYSTEM SHALL show the subtitle "<N> ngọn đèn đang sáng",
  the filter chips, and a card per lamp with artwork, kind chip, title "<owner label> · <intention>", "Cho
  <target>", and remaining time; the user's own lamps SHALL be visually highlighted.
- **Verification method:** unit test (ViewModel) + manual QA
- **Source:** Prototype `lg.*`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Garden with lamps
    Given the user has 2 active lamps
    When the Lamp Garden opens
    Then the subtitle says 2 lamps are lit
    And both lamps appear as cards with a highlighted border

  Scenario: Remaining-time label
    Given a lamp has 5 days left
    Then its card reads "Còn 5 ngày"

  Scenario: Last day label
    Given a lamp has 1 day left
    Then its card reads "Sáng đến hết hôm nay"
  ```

**FR-009 — Filter and see more**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL offer chips "Tất cả" and one per lamp kind, each with its count;
  WHEN a chip is tapped THE SYSTEM SHALL show only that kind and reset paging; THE SYSTEM SHALL show
  12 lamps first and WHEN more exist show "Xem thêm đèn", which appends the next 12.
- **Verification method:** unit test (ViewModel)
- **Source:** Prototype `gdF`, `gdN`.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Filter by kind
    Given the garden holds 3 oil lamps and 2 lotus candles
    When the user taps "Nến sen · 2"
    Then only the 2 lotus candles are shown

  Scenario: Paging
    Given the garden holds 30 lamps
    When the garden opens
    Then 12 lamps and "Xem thêm đèn" are shown
    When the user taps "Xem thêm đèn"
    Then 24 lamps are shown

  Scenario: Filter resets paging
    Given 24 lamps are shown
    When the user taps another chip
    Then at most 12 lamps are shown
  ```

**FR-013 — Empty garden**
- **Priority:** Should
- **Description:** WHEN no active lamp matches the current filter THE SYSTEM SHALL show an empty state
  with a way to light a lamp.
- **Verification method:** unit test (ViewModel) + manual QA
- **Source:** Silent gap — not designed in the prototype.
- **Acceptance criteria:**
  ```gherkin
  @not-confirmed
  Scenario: Garden has no lamps
    Given the user has no active lamps
    When the Lamp Garden opens
    Then an empty state is shown
  ```

> ⚠️ Not confirmed: copy and layout of the empty garden state (not in the prototype) — decides the empty-state design.

#### Data

**FR-011 — Lamp expiry**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL compute a lamp's remaining days from its lighting date and chosen
  duration, and SHALL NOT list lamps whose duration has elapsed.
- **Verification method:** unit test (UseCase)
- **Source:** Prototype `left` field; behavior beyond display is not specified.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Lamp still lit
    Given a lamp was lit 3 days ago for 7 days
    Then it is listed with 4 days left

  Scenario: Lamp elapsed
    Given a lamp was lit 8 days ago for 7 days
    Then it is not listed
  ```

> ⚠️ Not confirmed: whether a lamp expires in real time (recommended) or its chosen duration is only a static label — decides whether elapsed lamps disappear and how "days left" is computed.

**FR-012 — Persist lamps locally**
- **Priority:** Must
- **Description:** WHEN a lamp is lit THE SYSTEM SHALL store it on the device so it is still listed after
  the app restarts; IF storing fails THE SYSTEM SHALL show an error and keep the form with its values.
- **Verification method:** unit test (Repository with mock store)
- **Source:** Decision on persistence (local Core Data, behind a repository protocol).
- **Acceptance criteria:**
  ```gherkin
  Scenario: Survives restart
    Given the user lit a lamp
    When the app is relaunched and the garden is opened
    Then the lamp is still listed

  Scenario: Save fails
    Given storing the lamp fails
    When the user taps "Thắp đèn"
    Then an error is shown
    And the form keeps the chosen values
    And no lamp is added to the garden
  ```

**FR-014 — Clear lamps on sign-out**
- **Priority:** Must
- **Description:** WHEN the user signs out (Profile → "Đăng xuất"), THE SYSTEM SHALL delete every
  lamp stored on the device, so a different account signing in on the same device does not see them.
- **Verification method:** unit test (session data cleaner)
- **Source:** Product owner decision 2026-10-11 (lamps are mock data until a lamp API exists, then
  they are loaded from the server); backend advice to clear user-scoped data on sign-out.
- **Acceptance criteria:**
  ```gherkin
  Scenario: Sign-out removes lamps
    Given the user has lit two lamps
    When the user confirms "Đăng xuất" on the Profile screen
    Then the garden of the next session holds no lamp

  Scenario: Cancelled sign-out keeps lamps
    Given the user has lit two lamps
    When the user taps "Đăng xuất" and then "Hủy"
    Then both lamps are still listed
  ```

### 3.3 Performance requirements

- **NFR-001 — Smooth animation:** the ignite and fly-up animations and the garden grid scroll hold the
  frame budget (16 ms/frame); no decoding, sorting or Core Data fetch on the main thread.
- **NFR-002 — Incremental list updates:** appending a page of lamps adds only the new cards; an unchanged
  list triggers no re-render.
- **NFR-003 — Lighting latency:** the 2-second ignite duration comes from the design; saving the lamp
  must complete within that window.

### 3.4 Logical database requirements

- **Lamp** (local Core Data): id, kind, intention, dedication target, vow, lighting duration (days),
  lit-at date, owner display name, source (`mine`).
- No server-side data. Deletion of lamps with account deletion is not defined.

> ⚠️ Not confirmed: display name stored on a lamp (user's saved name vs hidden) — prototype hardcodes "Tâm Minh"; decides whether the owner name is persisted and its fallback.

### 3.5 Design constraints

- Reuse Design System components and tokens; add new tokens/assets (lamp artwork icons) in the token
  files, never inline.
- User-facing text from localization keys.

### 3.6 Software system attributes

- **Reliability:** a failed save never produces a visible lamp; no partial state.
- **Availability:** fully offline.
- **Security / privacy:** target names and vows are personal text; they SHALL NOT be written to logs
  (mask or omit per `PIIMasker`); stored locally only.
- **Maintainability:** one feature folder, one spec, one unit-test suite (`AGENTS.md` §2).
- **Portability:** N/A (iOS only).

---

## 4. Verification & traceability

### 4.1 Verification approach

Unit tests for ViewModel/UseCase/Repository logic with mocks; build verification only per `AGENTS.md`;
animation and visual fidelity verified manually by the user on a physical device.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Prototype `offer` | → spec-writer | 2 scenarios |
| FR-002 | Prototype `lpKind/lpIntent/lpDays` | → spec-writer | 3 scenarios |
| FR-003 | Prototype `lpFor/lpVow` | → spec-writer | 3 scenarios |
| FR-004 | Prototype `lpLight` | → spec-writer | 2 scenarios |
| FR-005 | Prototype `lp.isDone` | → spec-writer | 2 scenarios |
| FR-006 | Prototype `lpAgainFn` | → spec-writer | 1 scenario |
| FR-007 | Prototype `goGarden` | → spec-writer | 2 scenarios |
| FR-008 | Prototype `lg.*` | → spec-writer | 3 scenarios |
| FR-009 | Prototype `gdF/gdN` | → spec-writer | 3 scenarios |
| FR-010 | Prototype garden NavBar | → spec-writer | 1 scenario |
| FR-011 | Prototype `left` | → spec-writer | 2 scenarios |
| FR-012 | Persistence decision | → spec-writer | 2 scenarios |
| FR-013 | Silent gap | → spec-writer | 1 scenario |
| FR-014 | Product owner decision 2026-10-11 (sign-out) | `Docs/Specs/Profile/design.md` § Logout flow | 2 scenarios |
| NFR-001 | AGENTS.md §4.6 | → spec-writer | TBD |
| NFR-002 | AGENTS.md §4.6 | → spec-writer | TBD |
| NFR-003 | Prototype timing | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: maximum length of the dedication target and the vow — decides input limits and card truncation rules.

> Resolved 2026-10-11: the center tab-bar lamp button opens Thắp đèn (product owner instruction); the app and `Mo-ta-tinh-nang.md` previously said Chuẩn bị thiền. ⚠️ Not confirmed: which other entry points (Memorial, Temple) are in scope.

> ⚠️ Not confirmed: source of "community" lamps in the garden (prototype seeds 18 fake lamps) — decides whether the garden shows only the user's lamps or mock data. Interim default: only the user's own lamps; community lamps wait for an API.

> ⚠️ Not confirmed: whether a lamp expires in real time or its duration is a static label — decides expiry and "days left" computation. Interim default: real-time expiry (FR-011).

> ⚠️ Not confirmed: display name shown on the user's lamps (prototype hardcodes "Tâm Minh") — decides the persisted owner name. Interim default (implemented): no name is stored; cards show "Của bạn" because the app has no display-name source yet.

> ⚠️ Not confirmed: empty-garden copy and layout — decides FR-013 design.

> ⚠️ Not confirmed: whether the "Thỉnh đèn tại chùa" card appears on the completion state — it needs the donation flow. Interim default: hidden until that flow exists.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Scope of this iteration | Thắp đèn + Vườn đèn only; no donation/receipt | 2026-10-10 |
| Where lit lamps are stored | Local Core Data behind a repository protocol | 2026-10-10 |
| Relation to `Docs/Specs/Offering/` | New feature `LightLamp`; Offering left untouched | 2026-10-10 |
