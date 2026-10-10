# Base Architecture (read-only infrastructure)

Everything below already exists in `InnerLamp/Core/Base/`. **Never edit these files** when
generating a new screen — only read them, inherit from them, or conform to their protocols.
If anything here looks stale, re-read the live files at the paths given (do not trust this
summary over the actual source).

`BaseViewController` is a class — subclass it. `ViewModelType` and `Coordinator` are
protocols with no base class — conform to them (a feature's `IL<Feature>ViewModelProtocol`
extends `ViewModelType`; `IL<Feature>Coordinator` conforms `Coordinator` directly). Don't add a
`BaseViewModel`/`BaseCoordinator` class to make ViewModel/Coordinator "inherit" like the
ViewController does — that's a different architecture than what's here, only do it if the user
explicitly asks for it.

Full narrative doc (Vietnamese): `InnerLamp/Core/Base/README.md`.

## `BaseViewController` (`InnerLamp/Core/Base/BaseViewController.swift`)

Cha cho mọi ViewController, build UI 100% bằng code. Override 3 hàm thay vì `viewDidLoad()`:

```swift
class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupConstraints()
        bindViewModel()
        setupDismissKeyboardOnTap()   // tap anywhere outside a field/control dismisses keyboard
        setupKeyboardAvoidance()      // auto-scrolls the focused field above the keyboard
    }
    func setupViews() {}
    func setupConstraints() {}
    func bindViewModel() {}
    func showLoading() { /* TODO in base, not yet implemented */ }
    func hideLoading() { /* TODO in base, not yet implemented */ }
    func showError(_ message: String) { /* presents a UIAlertController */ }
}
```

Every new `IL<Feature>ViewController` subclasses this and overrides `setupViews()` /
`setupConstraints()` / `bindViewModel()` — never overrides `viewDidLoad()` directly.

### Keyboard handling — already automatic, never reimplement per-screen

`BaseViewController` wires two behaviors for every subclass, with zero opt-in:

1. **Tap-outside-to-dismiss**: a `UITapGestureRecognizer` on `view` (`cancelsTouchesInView =
   false`, so it doesn't eat taps on buttons/cells underneath) calls `view.endEditing(true)`.
2. **Scroll the focused field above the keyboard**: listens for
   `UITextField.textDidBeginEditingNotification` /
   `UIResponder.keyboardWillChangeFrameNotification`, finds the nearest enclosing `UIScrollView`
   of the focused field, and `scrollRectToVisible`s it in lockstep with the keyboard's own
   animation duration/curve.

Never add a second tap-to-dismiss gesture, `endEditing` call, or keyboard-notification observer in
a generated `IL<Feature>ViewController` — it's redundant and can fight the base implementation
(e.g. double-handling during `scrollView.keyboardDismissMode = .interactive`).

This scroll behavior depends on the **existing SignUp/Login/Otp layout pattern**: the scroll
view's bottom is *not* pinned straight to `view.bottomAnchor` — it's pinned to a footer view's
`topAnchor`, and that footer view is pinned to `view.keyboardLayoutGuide.topAnchor`. That's what
makes the scroll view's own frame (and therefore its scrollable content area) shrink correctly as
the keyboard rises, on top of `BaseViewController`'s explicit `scrollRectToVisible`. Reuse this
same chain for any new scrollable form screen — don't invent a `contentInset`-adjustment keyboard
handler instead, and don't pin the scroll view's bottom directly to `view.bottomAnchor` if the
screen has a footer.

## `ViewModelType` + `ViewState<T>` (`InnerLamp/Core/Base/BaseViewModel.swift`)

```swift
protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case failure(Error)
}
```

ViewModels do **not** `import UIKit` (must stay testable without running UIKit). Reuse
`ViewState<T>` for every screen's state — do not invent a per-feature state enum.

`Input`/`Output` are unconstrained associated types — nothing here dictates closures or Combine.
This skill's convention (see `references/mvvm_pattern.md`) fills them with Combine `Publisher`s:
`Input` = one `AnyPublisher<_, Never>` per trigger, `Output` = `{ state: AnyPublisher<ViewState<T>,
Never> }`. Don't add `import Combine` here to `BaseViewModel.swift` itself — it's per-feature
ViewModels that import it, this file stays untouched.

## `Coordinator` (`InnerLamp/Core/Base/Coordinator.swift`)

```swift
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    var parentCoordinator: Coordinator? { get set }
    func start()
}

extension Coordinator {
    func addChild(_ coordinator: Coordinator)     // sets parentCoordinator, appends, retains
    func removeChild(_ coordinator: Coordinator)   // removes from childCoordinators
    func finish()                                  // parentCoordinator?.removeChild(self)
}

protocol FinishableCoordinator: Coordinator {
    var onFinish: (() -> Void?) { get set }
}
```

Every new `IL<Feature>Coordinator` conforms to `Coordinator` (or `FinishableCoordinator` if the
parent needs a completion callback instead of/in addition to a delegate). It must be added to its
parent via `addChild(_:)` and must call `finish()` when its flow is done. See
`references/coordinator_navigation_rules.md` for which parent to attach to.

## `BaseNavigationController` / `BaseTabBarController`

`InnerLamp/Core/Base/BaseNavigationController.swift` and
`InnerLamp/Core/Base/BaseTabBarController.swift` — already wired as the app's nav/tab controller
instances. They:

- Default every push/pop/tab-switch to `CrossFadeTransition` automatically.
- Look for `TransitionProviding` (nav) / `TabTransitionProviding` (tab) conformance on the
  destination view controller to override the default — **do not modify these Base*Controller
  files** to add a new effect; conform on the destination VC instead.
- `BaseNavigationController` implements its own edge-swipe-back gesture (not UIKit's default
  `interactivePopGestureRecognizer`, which custom animators disable).

## Transition system (`InnerLamp/Core/Base/Transition/`)

```swift
protocol NavigationTransitionAnimating: UIViewControllerAnimatedTransitioning {
    var supportsInteractiveDismissal: Bool { get } // default true
}

protocol TransitionProviding {
    var pushTransition: NavigationTransitionAnimating? { get }
    var popTransition: NavigationTransitionAnimating? { get } // defaults to pushTransition
}

protocol TabTransitionProviding {
    var tabTransition: NavigationTransitionAnimating? { get }
}
```

`CrossFadeTransition` (`Transition/CrossFadeTransition.swift`) is the default and needs **no
opt-in** — if a new screen doesn't need a special transition, generate nothing transition-related
at all.

Only add `TransitionProviding` conformance + a transition class when the user explicitly asks for
a specific effect. Before writing a new animator, check `InnerLamp/Core/Base/Transition/` (and its
`Hero/` subfolder) for an existing one to reuse — e.g. `HeroTransition` already exists for
shared-element morphs (see the "Hero animation" example in `Core/Base/README.md`).

Example opt-in on the destination VC (do not touch Base*Controller files to do this):

```swift
final class ILSettingsViewController: BaseViewController, TransitionProviding {
    var pushTransition: NavigationTransitionAnimating? {
        SlideTransition() // only if user explicitly asked for a slide effect
    }
}
```
