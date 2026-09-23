# Coordinator Navigation Rules

Business rule from the project owner (not purely inferred from code — apply literally):

## Which coordinator owns which transition

- **`AppCoordinator`** (`InnerLamp/App/AppCoordinator.swift`) handles only **major/cross-section
  flow transitions** — e.g. `Login -> Home`, `Onboarding -> Signup`. It sits at the top of the
  coordinator tree.
- **Section coordinators** (e.g. `HomeCoordinator`) handle navigation **within** their own
  section — e.g. `Home -> Settings`, `Home -> Profile`. A new screen reachable from Home but not
  a top-level app flow gets wired through `HomeCoordinator` (create it if it doesn't exist yet),
  never through `AppCoordinator` directly.

General rule: **a coordinator is scoped to the flow/section it belongs to.** Only cross-section or
major-flow transitions go through `AppCoordinator`. When generating a new feature, first identify
which existing coordinator already owns that section of the app; only fall back to creating a new
section coordinator or touching `AppCoordinator` when no owner exists yet.

## Parent/child wiring pattern

Canonical example already in the repo: `OnboardingCoordinator` → `AppCoordinator` (predates the
`IL` naming rule, hence unprefixed, and predates the Combine rule in
`references/mvvm_pattern.md` — it still subscribes via the legacy `viewModel.onNavigationEvent`
closure property; don't copy that part). New coordinators follow the same
addChild/delegate/finish() shape but named `IL<Feature>Coordinator` (see
`references/naming_conventions.md`) and subscribe to navigation via
`viewModel.navigationEventPublisher.sink { ... }.store(in: &cancellables)` instead — see
`assets/templates/Coordinator.swift.template`.

1. New coordinator declares a delegate protocol for the navigation events it can produce:

   ```swift
   protocol IL<Feature>CoordinatorDelegate: AnyObject {
       func <featureLower>DidRequestSomething(_ coordinator: IL<Feature>Coordinator)
   }
   ```

2. New coordinator exposes `weak var delegate: IL<Feature>CoordinatorDelegate?`.
3. Parent coordinator creates the child via a `DIContainer.make<Feature>Coordinator(...)` factory,
   sets itself as `delegate`, calls `addChild(_:)`, then `start()`:

   ```swift
   private func show<Feature>() {
       let coordinator = container.make<Feature>Coordinator(navigationController: navigationController)
       coordinator.delegate = self
       addChild(coordinator)
       coordinator.start()
   }
   ```

4. Parent conforms to the child's delegate protocol and reacts to navigation events; the child
   calls `finish()` itself once its flow is complete — its `IL<Feature>Coordinator.start()`
   subscribes `viewModel.navigationEventPublisher`, and on each `IL<Feature>NavEvent` calls
   `self.delegate?...(self)` and/or `self.finish()` as appropriate (see
   `assets/templates/Coordinator.swift.template`; the legacy closure-based equivalent is
   `OnboardingCoordinator`'s `viewModel.onNavigationEvent` assignment).

Use this same shape for any new coordinator, whether its parent is `AppCoordinator` or a section
coordinator like `HomeCoordinator`.

## `DIContainer` is the only wiring point

`InnerLamp/App/DIContainer.swift` is the single place that constructs the dependency chain
`UseCase -> ViewModel -> Coordinator` via factory methods. Factory **method** names stay
feature-name-only (no `IL` — the prefix rule applies to types/files, not method names); their
**return types** carry the `IL` prefix:

```swift
func make<Feature>UseCase() -> IL<Feature>UseCase { ... }
func make<Feature>ViewModel() -> IL<Feature>ViewModel { ... }
func make<Feature>Coordinator(navigationController: UINavigationController) -> IL<Feature>Coordinator { ... }
```

Every new feature adds its own `make*` factory methods to `DIContainer` instead of instantiating
`UseCase`/`ViewModel`/`Coordinator` inline anywhere else (coordinators, view controllers, etc.).
