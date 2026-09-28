# AGENTS.md — AI Guidelines for InnerLamp Development

This document serves as the specification & guidelines for AI Agents reading, maintaining, and building new features in the **InnerLamp** project.

**Language rule**: All documentation and code comments must be written in **English**, regardless of the language used in the conversation with the user.

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

---

## 2. Core Principles

1. **Clean Code & Maintainability**: Write clear, explicit code as if another engineer will maintain it.
2. **Feature rule**: **Each feature = 1 feature folder + 1 spec/rule + 1 unit test suite**.
3. **Modular by Feature**: Group by feature rather than grouping everything by data type (avoid splitting controller/model/viewmodel into scattered global folders).
4. **No UIKit import in ViewModel/Domain**: [`BaseViewModel`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Core/Base/BaseViewModel.swift) and the Domain Layer may only `import Foundation`, to stay independent and easily unit-testable.
5. **Declarative AI Comments**: Prefer AI-directive comments, e.g.: `// @ai: write unit test for this function`.
6. **English-only documentation & comments**: All Markdown docs and in-code comments must be written in English, even when the request or conversation is in another language.

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
