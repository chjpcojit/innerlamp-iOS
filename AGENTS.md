# AGENTS.md — AI Guidelines for InnerLamp Development

This document serves as the specification & guidelines for AI Agents reading, maintaining, and building new features in the **InnerLamp** project.

**Language rule**: All documentation and code comments must be written in **English**, regardless of the language used in the conversation with the user. **Sole exception**: `Docs/Tech-Debt/` and `Docs/Assumptions/` entries are bilingual English + Vietnamese (see Section 10).

---

## 1. Project Overview & Tech Stack

- **Platform**: iOS (Native Swift)
- **UI Framework**: UIKit — **100% Programmatic UI** (Auto Layout in code, no Storyboard/XIB for new UI).
- **Architecture**: **MVVM-C (Model - View - ViewModel - Coordinator) + Clean Architecture**.
- **Async & Concurrency**: Swift Concurrency (`async/await`, `actor`).
- **Dependency Management (DI)**: Manual Dependency Injection via [`DIContainer`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/App/DIContainer.swift).
- **Base & Transition**: Base ViewController/ViewModel/Coordinator + a transition system (crossfade by default, custom effects including hero animation) for Navigation/TabBar. Details & usage: [`Core/Base/README.md`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/README.md).
- **Design System**: Shared tokens (`ILColors`, `ILTypography`, `ILMetrics`, `ILIcons`) under [`Presentation/Common/DesignSystem/Tokens`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/) and 9 reusable components under [`Presentation/Common/DesignSystem/Components`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/). Full spec: [`Tokens/DESIGN_SYSTEM.md`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/DESIGN_SYSTEM.md).
- **Local Storage**:
  - [`KeychainService`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Storage/KeychainService.swift): Stores sensitive data (tokens, passwords).
  - [`UserDefaultsService`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Storage/UserDefaultsService.swift): Stores settings, app state flags.
  - Core Data: Manages local relational data (`InnerLamp.xcdatamodeld`).
- **Logging & Observability**: Sentry (crash, SPM `sentry-cocoa`) + 3 internal mock channels (security alert, metrics, flow tracking). Details & usage: [`Core/Logging/README.md`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Logging/README.md), original spec: [`Mobile Logging Architecture.md`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Docs/Specs/Mobile%20Logging%20Architecture.md).
- **Testing**: `XCTest` for Unit Tests & UI Tests.
- **Verification scope**: Do **not** boot or run the iOS Simulator to verify a change. Verification is limited to a successful build (`xcodebuild build`) and a passing test run (`xcodebuild test` / `XCTest`). The user runs the app on a physical device and checks the actual UI/behavior themselves.
  - **Build verification** must target `generic/platform=iOS` with code signing disabled, never a `platform=iOS Simulator,...` destination — resolving a simulator destination invokes CoreSimulatorService even without opening Simulator.app, which has caused it to crash on this machine:
    ```bash
    xcodebuild build \
      -project InnerLamp.xcodeproj \
      -scheme InnerLamp \
      -destination 'generic/platform=iOS' \
      CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
    ```
  - **Test verification** (`xcodebuild test`) has no simulator-free equivalent — XCTest must execute on a simulator or a connected physical device. Prefer a physical device destination (`-destination 'platform=iOS,id=<UDID>'`, UDID via `xcrun xctrace list devices`) when one is available; only fall back to a Simulator destination if the user confirms CoreSimulatorService is currently stable, since that is the step known to trigger the crash.

---

## 2. Core Principles

1. **Clean Code & Maintainability**: Write clear, explicit code as if another engineer will maintain it.
2. **Feature rule**: **Each feature = 1 feature folder + 1 spec/rule + 1 unit test suite**.
3. **Modular by Feature**: Group by feature rather than grouping everything by data type (avoid splitting controller/model/viewmodel into scattered global folders).
4. **No UIKit import in ViewModel/Domain**: [`BaseViewModel`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/BaseViewModel.swift) and the Domain Layer may only `import Foundation`, to stay independent and easily unit-testable.
5. **Declarative AI Comments**: Prefer AI-directive comments, e.g.: `// @ai: write unit test for this function`.
6. **English-only documentation & comments**: All Markdown docs and in-code comments must be written in English, even when the request or conversation is in another language (except the bilingual entries in Section 10).

---

## 3. Project Structure

```
innerlamp/
├── AGENTS.md                                # This guideline file
├── InnerLamp/
│   ├── App/                                 # App setup & lifecycle
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   ├── AppCoordinator.swift             # Root coordinator
│   │   └── DIContainer.swift                # Composition root / DI Container
│   ├── Core/                                # Shared core components
│   │   ├── Base/                            # See README.md in this folder
│   │   │   ├── README.md                    # Describes Base + transition system & usage
│   │   │   ├── BaseViewController.swift     # Base UIViewController (code-based UI)
│   │   │   ├── BaseViewModel.swift          # ViewModelType & ViewState protocol
│   │   │   ├── Coordinator.swift            # Coordinator protocols & life-cycle management
│   │   │   ├── BaseNavigationController.swift # Auto crossfade + custom swipe-back
│   │   │   ├── BaseTabBarController.swift   # Auto crossfade on tab switch
│   │   │   └── Transition/                  # Protocol + effects (CrossFade, Hero...)
│   │   ├── Networking/
│   │   │   ├── Endpoint.swift               # Endpoint protocol & URLRequest builder
│   │   │   ├── HTTPMethod.swift             # HTTPMethod & NetworkError definitions
│   │   │   └── NetworkService.swift         # Actor-based async/await network service
│   │   ├── Storage/
│   │   │   ├── KeychainService.swift        # Keychain wrapper (CRUD + Codable)
│   │   │   └── UserDefaultsService.swift    # UserDefaults wrapper (Codable)
│   │   └── Logging/                         # See README.md in this folder
│   │       ├── README.md                    # Describes the 4 log groups & usage
│   │       ├── LoggingService.swift         # Group 1 — Crash (Sentry)
│   │       ├── SecurityAlertReporting.swift # Group 2 — Security Alerts (mock)
│   │       ├── MetricsCollecting.swift      # Group 3 — Metrics (mock)
│   │       ├── FlowTracking.swift           # Group 4 — Flow Tracking (mock)
│   │       └── PIIMasker.swift              # Required — mask PII before logging
│   ├── Domain/                              # Pure business logic (no framework dependency)
│   │   ├── Entities/                        # Plain business models
│   │   ├── Repositories/                    # Repository interfaces / protocols
│   │   └── UseCases/                        # Interactors / business actions
│   ├── Data/                                # Data layer implementation
│   │   ├── Repositories/                    # Repository protocol implementations
│   │   ├── DataSources/                     # Remote / local data sources
│   │   └── DTOs/                            # Data Transfer Objects (Codable)
│   ├── Presentation/                        # UI layer
│   │   ├── Scenes/                          # Organized by feature flow
│   │   │   └── <FeatureName>/
│   │   │       ├── <Feature>Coordinator.swift
│   │   │       ├── <Feature>ViewController.swift
│   │   │       ├── <Feature>ViewModel.swift
│   │   │       └── Views/                   # Feature's custom UI components
│   │   └── Common/                          # Shared custom UI components & theme
│   └── Assets.xcassets / Info.plist
├── InnerLampTests/                          # Unit Tests
└── InnerLampUITests/                        # UI Automation Tests
```

---

## 4. Architecture & Code Conventions

### 4.1. Coordinator Pattern (`Navigation`)
- All navigation between screens must go through [`Coordinator`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/Coordinator.swift); a ViewController must **not** directly `pushViewController` or `present` another screen.
- Always use `addChild(_:)`, `removeChild(_:)`, and `finish()` to manage child coordinator lifecycle and avoid memory leaks or lost references.
- Inherit `FinishableCoordinator` when a callback to the parent coordinator is needed when the flow ends.
- Coordinators create `BaseNavigationController`/`BaseTabBarController` (not the plain `UINavigationController`/`UITabBarController`) to get the default crossfade effect — for custom effects (including hero animation) see [`Core/Base/README.md`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/README.md).

### 4.2. BaseViewController (`View Layer`)
- Inherit from [`BaseViewController`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/BaseViewController.swift).
- Organize using the 3 standard lifecycle functions:
  1. `setupViews()`: Add subviews to the view hierarchy, configure UI properties.
  2. `setupConstraints()`: Activate Auto Layout (`translatesAutoresizingMaskIntoConstraints = false`).
  3. `bindViewModel()`: Listen to output/state from the ViewModel (using closures or observation).

### 4.3. BaseViewModel & Unidirectional Data Flow (`ViewModel Layer`)
- Apply the `Input -> Output` pattern via [`ViewModelType`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/BaseViewModel.swift):
```swift
final class SampleViewModel: ViewModelType {
    struct Input {
        let submitTrigger: () -> Void
    }
    
    struct Output {
        var state: (ViewState<SampleModel>) -> Void
    }
    
    func transform(input: Input) -> Output {
        // Handle logic and update state
    }
}
```
- Use the enum [`ViewState<T>`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/BaseViewModel.swift) (`.idle`, `.loading`, `.success(T)`, `.failure(Error)`) to represent screen state consistently.

### 4.4. Domain & Data Layer
- **Domain Layer**:
  - `Entity`: Pure business logic, no JSON parsing or UI code.
  - `UseCase`: Each UseCase handles a single business action (Single Responsibility).
  - `Repository Protocol`: Declares the interface the Data layer implements.
- **Data Layer**:
  - Converts DTOs (from Network/Storage) into Domain Entities before returning them to the UseCase.

### 4.5. Design System (`UI Tokens & Components`)
- No hardcoding in any screen/view: font size must come from [`ILTypography`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILTypography.swift) presets, color must come from [`ILColors`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILColors.swift) constants (itself only loads from `Assets.xcassets/Colors`), spacing/radius/shadow must come from [`ILMetrics`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILMetrics.swift), and icons/images must come from [`ILIcons`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILIcons.swift) constants (itself the only place that calls `UIImage(named:)`, loading from `Assets.xcassets/Icons`).
- Icons: never call `UIImage(named:)` in a screen/view, and never set the rendering mode at the call site — it is baked into the token (template icons are tinted with an `ILColors` constant via `tintColor`; full-color illustrations render as-is). Don't redraw an icon with `CAShapeLayer`/`UIBezierPath` when an asset exists.
- If no existing preset/constant fits, add a new one to the token file itself (a new color asset under `Assets.xcassets/Colors` for a new base color, or a new `.imageset` under `Assets.xcassets/Icons` + an `ILIcons` constant for a new icon) — never inline a one-off value in a screen.
- Prefer assembling new screens from the 9 existing components in [`Presentation/Common/DesignSystem/Components`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/) before building a new custom view.
- Full token reference, values, and component usage examples: [`Tokens/DESIGN_SYSTEM.md`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/DESIGN_SYSTEM.md) — read it when building or reviewing any UI.

### 4.6. Smooth UI & Main-Thread Performance
Keep the main thread free during scrolling, pagination and transitions (budget: 16ms/frame).
- **Remote images**: always use [`ILRemoteImageView`](InnerLamp/Presentation/Common/DesignSystem/Components/ILRemoteImageView.swift) — never `UIImage(data:)`/`UIImage(contentsOf:)`/`Data(contentsOf:)` in a view. It fetches, decodes and **downsamples** (ImageIO) off the main actor and only assigns the finished bitmap on main; the view's `backgroundColor` is the placeholder. Prefer the server `thumbnailURL` over the full `imageURL` for small slots.
- **Never do heavy work on main**: decoding, parsing, sorting/filtering large lists, file/Core Data fetches. Use `nonisolated` async functions / `Task.detached`, then hop back to main only to assign results. Remember a `Task {}` created in a `@MainActor` type inherits the main actor.
- **Incremental list updates**: when a list grows (load more), diff against the previous items and **append only the new rows** — never remove/re-create every row view on each state emission (it also resets every image). Skip the update entirely when the data is unchanged (ViewModels may emit the same items again, e.g. only the footer state changed). Every list/carousel view's `didSet` must guard with `if items != oldValue` (models are `Equatable`).
- **Pagination**: trigger load-more from scroll with a threshold and a guard against duplicate in-flight requests.
- **Cheap rendering**: avoid offscreen rendering (`cornerRadius` + shadow + mask stacks); give shadows an explicit `shadowPath`; don't animate or relayout the whole hierarchy for a small change.
- When touching any list/carousel/image code, check the above before finishing, and call out remaining main-thread risks in the final response.

---

## 5. Process for AI Creating a New Feature

When asked to create a new feature (e.g., `Auth`, `Dashboard`, `Settings`), the AI should follow these steps:

1. **Create the feature folder structure**:
   - `InnerLamp/Presentation/Scenes/<FeatureName>/`
   - `InnerLamp/Domain/UseCases/<FeatureName>/` (if there is new business logic)
   - `InnerLamp/Domain/Repositories/<FeatureName>/` & `InnerLamp/Data/Repositories/<FeatureName>/`
2. **Declare Protocol & Dependency Injection**:
   - Register dependencies in [`DIContainer`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/App/DIContainer.swift).
3. **Implement Coordinator, ViewModel, ViewController**:
   - Inherit [`Coordinator`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/Coordinator.swift), [`BaseViewController`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/BaseViewController.swift), and [`ViewModelType`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/BaseViewModel.swift).
4. **Write the corresponding unit tests**:
   - Create test files at `InnerLampTests/<FeatureName>ViewModelTests.swift` or `InnerLampTests/<FeatureName>UseCaseTests.swift`.
   - Mock the Repository/Service to verify the ViewModel's output state.

---

## 6. Networking & Storage Guidelines

- **Creating an API endpoint**:
  Create an enum/struct conforming to [`Endpoint`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Networking/Endpoint.swift) and call it through [`NetworkService`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Networking/NetworkService.swift).
- **Storing data**:
  - Token, Passcode, Credentials -> [`KeychainService`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Storage/KeychainService.swift).
  - Settings, First Launch, Theme Mode -> [`UserDefaultsService`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Storage/UserDefaultsService.swift).

---

## 7. Logging Guidelines

- Do not import `Sentry` or call `MockLogTransport`/`SecurityAlertReporter`/`MetricsCollector`/`FlowTracker` directly in feature code — obtain them via `DIContainer` through their protocols (`LoggingService`, `SecurityAlertReporting`, `MetricsCollecting`, `FlowTracking`).
- The 4 groups are not interchangeable (crash / security alert / metrics / flow tracking) — pick the right one for the purpose; see the table in [`Core/Logging/README.md`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Logging/README.md).
- Never log raw PII (account numbers, real amounts, tokens...) — use `PIIMasker.categorizeAmount`/categorical values. Adding a new PII format must come with a test in `InnerLampTests/PIIMaskerTests.swift` first.
- A new feature needing Flow Tracking: declare its own `FlowType`/`FlowStep` within the feature (do not modify Core), following the pattern in the README.
- Risk/Metrics/Analytics servers are currently **mocked** (`MockLogTransport`, prints to console). When a real backend exists, just add a new implementation for `LogTransport`.

---

## 8. Code Style & Memory Safety Rules

- **Avoid retain cycles**: Always use `[weak self]` in closures/callbacks, and `weak var parentCoordinator` in Coordinator.
- **Access control**: Default to `private` / `fileprivate` for internal properties/functions; mark classes `final` when there's no inheritance.
- **No force unwrapping**: Avoid `!` (force unwrap), prefer `guard let` or `if let`.
- **README.md must not be a target member**: `InnerLamp/` is a file-system-synchronized group, so every new file is auto-added to the `InnerLamp` target. Multiple `README.md` files would all be copied to `InnerLamp.app/README.md` and break the build ("Multiple commands produce ... README.md"). Whenever you create a `README.md` under `InnerLamp/`, add its path (relative to `InnerLamp/`, e.g. `Presentation/Scenes/<Feature>/README.md`) to `membershipExceptions` of the `Exceptions for "InnerLamp" folder in "InnerLamp" target` set in `InnerLamp.xcodeproj/project.pbxproj` (keep the list alphabetical). Never delete the README itself.

---

## 9. Behavioral Guidelines for AI Agents

Four principles to reduce common LLM coding mistakes: wrong assumptions, overengineering, unrelated edits, and weak success criteria.

### 9.1. Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.
- **State assumptions explicitly** — if uncertain, ask rather than guess.
- **Present multiple interpretations** — don't pick one silently when ambiguity exists.
- **Push back when warranted** — if a simpler approach exists, say so.
- **Stop when confused** — name what is unclear and ask for clarification.

### 9.2. Simplicity First
Write the minimum code that solves the problem. Nothing speculative.
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.
- **The test**: would a senior engineer say this is overcomplicated? If yes, simplify.

### 9.3. Surgical Changes
Touch only what you must. Clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match the existing style, even if you would do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- When your changes create orphans, remove the imports/variables/functions that **your** changes made unused; leave pre-existing dead code unless asked.
- **The test**: every changed line should trace directly to the user's request.

### 9.4. Goal-Driven Execution
Define success criteria. Loop until verified.

| Instead of...   | Transform to...                                  |
|-----------------|--------------------------------------------------|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug"    | "Write a test that reproduces it, then make it pass"  |
| "Refactor X"     | "Ensure tests pass before and after"                  |

For multi-step tasks, state a brief plan:
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]

Strong success criteria let the agent loop independently; weak criteria ("make it work") require constant clarification.


---

## 10. Golden Rules — Record Tech Debt & Assumptions

These rules apply to **every** task, however small. Never leave tech debt or assumptions only in chat or in your head.

**Language exception**: Files under `Docs/Tech-Debt/` and `Docs/Assumptions/` are **bilingual (English + Vietnamese)** — this is the only exception to the English-only rule. Frontmatter keys/values stay English (except `title_vi`); every body section carries an `EN:` block followed by a `VI:` block. Code comments stay English.

### 10.1. Tech Debt → `Docs/Tech-Debt/<Feature>/`
Whenever you knowingly take a shortcut, leave a workaround, skip a test, hardcode a value, stub an API, or notice debt you are not fixing now, record it in `Docs/Tech-Debt/<Feature>/`.

### 10.2. Assumptions → `Docs/Assumptions/<Feature>/`
Whenever you make an assumption instead of receiving a confirmed answer (business rule, API contract, behavior, design detail), record it in `Docs/Assumptions/<Feature>/`. For major assumptions, also leave an inline `// @ai: assumption — see Docs/Assumptions/<Feature>/<file>.md` comment at the code site.

### 10.3. File Rules (both folders)
- **One entry = one file**, named `TD-<Feature>-<NNN>-<slug>.md` / `AS-<Feature>-<NNN>-<slug>.md` (`NNN` = zero-padded sequence per feature, never reused).
- `<Feature>` matches the name in `Docs/Specs/<Feature>/` and `Presentation/Scenes/<Feature>/`. Debt that belongs to no single feature goes in `Docs/Tech-Debt/Core/` (same for `Docs/Assumptions/Core/`).
- Create the folder if it does not exist. No index/README is required.
- Never delete an entry: when it is resolved or invalidated, update `status`, `updated`, and the Resolution/Outcome section.
- Keep `files:` accurate (path, optionally `:line`); update it when code moves.
- Mention every new or changed entry in your final response to the user.
- If code was written on top of a `⚠️ Not confirmed` item in a spec, it **must** also have an entry in `Docs/Assumptions/`; the spec marker stays inline.

**Level scale** (same for both, 4 tiers):

| Level | Tech Debt — risk/cost if left | Assumption — impact if wrong |
|-------|-------------------------------|------------------------------|
| Low | Cosmetic / negligible cost | Minor, trivially fixable |
| Medium | Slows work or causes localized bugs | Rework in one feature |
| High | Likely user-facing bugs or costly refactor | Rework across features / wrong behavior shipped |
| Critical | Security, data loss, crash, or blocks release | Security/data/compliance impact or blocks release |

**Status values**:
- Tech Debt: `Open` · `In Progress` · `Resolved` · `Won't Fix`
- Assumption: `Unvalidated` · `Validated` · `Invalidated`

### 10.4. Template — Tech Debt
```markdown
---
id: TD-<Feature>-<NNN>
title: <English title>
title_vi: <Tiêu đề tiếng Việt>
feature: <Feature>
level: Medium          # Low | Medium | High | Critical
status: Open           # Open | In Progress | Resolved | Won't Fix
created: YYYY-MM-DD
updated: YYYY-MM-DD
files:
  - InnerLamp/path/to/File.swift:42
---

## Description / Mô tả
EN: ...
VI: ...

## Why it was taken on / Lý do chấp nhận nợ
EN: ...
VI: ...

## Impact / Ảnh hưởng
EN: ...
VI: ...

## Proposed fix / Hướng xử lý
EN: ...
VI: ...

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
```

### 10.5. Template — Assumption
```markdown
---
id: AS-<Feature>-<NNN>
title: <English title>
title_vi: <Tiêu đề tiếng Việt>
feature: <Feature>
level: Medium          # Low | Medium | High | Critical (impact if wrong)
status: Unvalidated    # Unvalidated | Validated | Invalidated
created: YYYY-MM-DD
updated: YYYY-MM-DD
files:
  - InnerLamp/path/to/File.swift:88
source: Docs/Specs/<Feature>/requirements.md (<REQ-ID>, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: ...
VI: ...

## Rationale / Cơ sở giả định
EN: ...
VI: ...

## Implications if wrong / Hệ quả nếu sai
EN: ...
VI: ...

## Validation / Cách xác nhận
EN: ...
VI: ...

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
```
