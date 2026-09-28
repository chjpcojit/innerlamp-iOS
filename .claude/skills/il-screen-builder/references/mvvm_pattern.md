# MVVM Input/Output Pattern

**Combine-based, not closure-based.** ViewModel ↔ ViewController communication uses Combine
`Publisher`/`Subject`, not custom closure properties or `onState:`-callback methods. This
supersedes the closure-callback shape still used by the legacy `OnboardingViewModel.swift` /
`OnboardingViewController.swift` (predates this rule, unprefixed, **not** migrated — don't copy
its closure style for new features, only its coordinator-wiring/state-model ideas). The templates
in `assets/templates/` are the ground truth for this shape.

(Trivial, unavoidable exceptions: Combine's own `.sink { ... }` consumption always takes a
trailing closure — that's the Combine API, not the thing being replaced. What's actually banned
is the old *architecture*: custom `((ViewState<T>) -> Void)?` properties/params and
`onState:`/`onNavigationEvent:` callback plumbing hand-rolled instead of `Publisher`s.)

## ViewModel shape

```swift
protocol IL<Feature>ViewModelProtocol: ViewModelType {
    /// Independent of transform(input:) — the Coordinator subscribes to this directly in
    /// start(), before any ViewController/Input exists.
    var navigationEventPublisher: AnyPublisher<IL<Feature>NavEvent, Never> { get }
}

final class IL<Feature>ViewModel: IL<Feature>ViewModelProtocol {

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        // one Publisher per user action/trigger, e.g.:
        // let someActionTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<IL<Feature>StateModel>, Never>
    }

    var navigationEventPublisher: AnyPublisher<IL<Feature>NavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<IL<Feature>NavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<IL<Feature>StateModel>, Never>
    private var currentState: IL<Feature>StateModel
    private let useCase: IL<Feature>UseCase
    private var cancellables = Set<AnyCancellable>()

    init(useCase: IL<Feature>UseCase) {
        self.useCase = useCase
        let initialState = useCase.getInitialState()
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // transform() subscribes each Input publisher to its matching private handle*() method —
    // this is the only place ViewModel logic gets wired to triggers.
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // private handle*() methods do the actual state work, sending onto stateSubject /
    // navigationEventSubject instead of calling a callback.
    private func handleViewDidLoad() {
        currentState = useCase.getInitialState()
        stateSubject.send(.success(currentState))
    }

    private func handleSomeAction() {
        // mutate currentState, then:
        stateSubject.send(.success(currentState))
        // or fire a nav event instead:
        // navigationEventSubject.send(.someEvent)
    }
}
```

Key rules:

- `Input` holds one `AnyPublisher<_, Never>` per user action/trigger; `Output` holds `state`
  (`AnyPublisher<ViewState<T>, Never>`). Navigation is **not** part of `Output` — it's a separate
  `navigationEventPublisher` on the ViewModel itself, since the Coordinator needs to subscribe in
  `start()` before the ViewController (and therefore `Input`) exists.
- `handle*()` methods are `private` — nothing outside the ViewModel calls them directly anymore.
  They're wired to their `Input` publisher exclusively inside `transform(input:)`.
- `Output.state` uses `ViewState<T>`, never a custom per-feature state enum.
- Navigation is expressed as an `IL<Feature>NavEvent` enum (`Equatable`) sent through
  `navigationEventSubject` → `navigationEventPublisher`, which the owning `IL<Feature>Coordinator`
  subscribes to in `start()` and translates into `delegate` calls + `finish()` (see
  `references/coordinator_navigation_rules.md`).
- ViewModel has **no `import UIKit`**, but does `import Combine`.
- Every `.sink` that outlives the function it's created in gets `.store(in: &cancellables)`.
- `IL{{Feature}}StateModel` (the `T` in `ViewState<T>`) lives in
  `Presentation/Scenes/{{Feature}}/`, not `Domain/Entities/` — it is UI-only state (input mirrors,
  `*Error` fields, loading flags, display formatting), never a business object. If a UseCase
  method returns/takes `IL{{Feature}}Entity` (the pure Domain type), the ViewModel converts
  between the two itself with a small private helper (e.g. `applyEntity(_:)` mutating
  `currentState`) — this conversion is presentation-specific and does not belong in a shared
  Mapper. See `references/data_layer_boundaries.md` for the full Entity/StateModel/DTO split.

## ViewController shape

```swift
final class IL<Feature>ViewController: BaseViewController {
    private let viewModel: IL<Feature>ViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    // one *Subject per Input trigger, e.g.:
    // private let someActionTappedSubject = PassthroughSubject<Void, Never>()

    // Subviews: declared `private lazy var`, configured inline in the initializer closure.
    // They are only *added to the view hierarchy* in setupViews() — declaring them lazy defers
    // building each one until setupViews() first touches it.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.title
        label.textColor = ILColors.ilInk
        return label
    }()

    init(viewModel: IL<Feature>ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupViews() {
        super.setupViews()
        view.addSubview(titleLabel) // and so on for each lazy subview
        // UI action targets send onto their *Subject instead of calling viewModel.handle*():
        // someButton.onTap = { [weak self] in self?.someActionTappedSubject.send(()) }
    }
    override func setupConstraints() { /* Auto Layout */ }

    override func bindViewModel() {
        super.bindViewModel()

        let input = IL<Feature>ViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher()
            // pass each *Subject above as its matching Input publisher
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)` — see §Main-thread delivery below.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Send after subscribing above, in the same synchronous call — PassthroughSubject
        // doesn't replay values sent before a subscriber attaches.
        viewDidLoadSubject.send(())
    }

    private func render(state: ViewState<IL<Feature>StateModel>) {
        switch state {
        case .idle, .loading: break
        case .success(let model): updateUI(with: model)
        case .failure(let error): showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: IL<Feature>StateModel) { /* apply model to UI */ }
}
```

UI action targets (`@objc` handlers, `onTap` closures on `IL*` components — those closures are the
component's own API, unrelated to this rule) call `.send(())` on the matching `*Subject`, which
`transform(input:)` already subscribed on the ViewModel side. The ViewController never calls a
`viewModel.handle*()` method directly anymore.

## Main-thread delivery (no `.receive(on:)`)

The `InnerLamp` app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so every
`IL<Feature>ViewModel` is implicitly `@MainActor`, and each `Task { }` it starts inherits the main
actor (an `await` on a nonisolated UseCase hops back to main before the next line). State is
therefore always sent on the main thread already — the ViewController subscribes to
`output.state` **without** `.receive(on: DispatchQueue.main)` (or `RunLoop.main`).

This is a correctness rule, not a style preference. `.receive(on: DispatchQueue.main)` always
defers delivery to the next run-loop turn, even when already on main. Because `stateSubject` is a
`CurrentValueSubject` seeded in `init` and `viewDidLoad` sends synchronously, the initial state
must be rendered inside `viewDidLoad`; deferred, it lands *after* the push/tab transition has
already laid the view out empty, and any self-sized block (multi-line label, card) visibly grows
while the transition runs — only on the first appearance, which makes it easy to miss.

- Don't add explicit `@MainActor` to the ViewModel — it's redundant with the target default.
- Don't mark a ViewModel (or its `handle*()` methods) `nonisolated`, and don't use
  `Task.detached` / `DispatchQueue.global` to send state — either would break the guarantee
  above. Heavy work belongs in the UseCase/Repository, which the ViewModel `await`s.

## Async actions (network / persistence calls in a UseCase)

New `IL<Feature>UseCase` methods beyond `getInitialState()` default to `async throws`, even when
the first implementation is local-only (see `assets/templates/UseCase.swift.template`). This is
intentional: adding a real network/persistence call later never forces a signature change up
through `ViewModel` → `ViewController`.

The matching private `handle*()` wraps the call in a `Task` and sends state onto `stateSubject`:

```swift
private func handleSomeAction() {
    stateSubject.send(.loading)
    Task { [weak self] in
        guard let self else { return }
        do {
            try await self.useCase.someAction()
            self.stateSubject.send(.success(self.currentState))
        } catch {
            self.stateSubject.send(.failure(error))
        }
    }
}
```

Because `stateSubject` is a `CurrentValueSubject` held by the ViewModel (not a per-call parameter),
there's no `@escaping` concern here — unlike the closure-callback shape this replaced.

**Never invent an `Endpoint` case, path, or response field that wasn't given by the user or
doesn't already exist in the codebase.** More broadly: this skill never writes a real
implementation for a network or local-Repository call at all — see
`references/data_layer_boundaries.md` for the exact scope boundary (pure client-side validation
and Entity/StateModel/DTO mapping are in scope and must be real; anything needing I/O is a
one-line-TODO stub). If a UseCase method needs to call the network
(`Core/Networking/NetworkService.swift`) or a Repository, leave the method as the one-line-TODO
stub shown in `assets/templates/UseCase.swift.template` and ask the user for the contract instead
of guessing — a wrong guessed contract is worse than an unfinished method.

## Testing

Every generated `IL<Feature>ViewModel` gets a matching `IL<Feature>ViewModelTests` (from
`assets/templates/ViewModelTests.swift.template`) — this is mandatory, not optional, because the
Combine `Output.state`/`navigationEventPublisher` shape above makes ViewModel logic cheap and
high-value to unit test directly:

- Instantiate the real `sut` (`IL<Feature>ViewModel`) against a hand-written mock conforming to
  `IL<Feature>UseCase` (no mocking framework — plain `*Called` bool flags and captured args).
- Drive each action through its `Input` publisher (a `PassthroughSubject` created in the test,
  `.send(())`'d after subscribing), never by calling a private `handle*()` method directly.
- One test per action: subscribe `output.state` (or `sut.navigationEventPublisher` for a
  navigating action) into a local `var`/array via `.sink`, store the cancellable in the test's
  `cancellables: Set<AnyCancellable>`, send the trigger, then assert.
- ViewModel tests never touch `UIKit`/`XCUIApplication` — that's the point of keeping the
  ViewController thin.

UI tests (`XCUIApplication`, `InnerLampUITests`) are **not** auto-generated by this skill — a
template can't know a screen's real layout, and a hollow generated UI test is worse than none.
Only write one if the user explicitly asks for it, scoped to: the screen appears without crashing,
its key elements expose `accessibilityIdentifier`s, tapping the primary CTA produces the expected
navigation, and each `ViewState` case (loading/success/failure) renders the right visible state.

## Subview declaration rule

Every subview is a `private lazy var` property (not a plain `var` built in `setupViews()`, and
not force-unwrapped `var x: UIView!`), configured entirely inside its own initializer closure.
`setupViews()` only *adds* the already-declared subviews to the hierarchy (`view.addSubview(...)`)
and wires up action targets — it never constructs a subview inline.
