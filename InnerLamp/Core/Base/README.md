# Core/Base

Base classes + foundational protocols for the whole app: ViewController, ViewModel, Coordinator, and the transition system for `UINavigationController`/`UITabBarController`.

## Structure

```
Base/
├── BaseViewController.swift        # Parent for every ViewController (code-based UI)
├── BaseViewModel.swift             # ViewModelType (Input -> Output) + ViewState<T>
├── Coordinator.swift               # Coordinator protocol & child coordinator management
├── BaseNavigationController.swift  # UINavigationController: auto slide (right->left) + custom swipe-back
├── BaseTabBarController.swift      # UITabBarController: auto crossfade on tab switch
└── Transition/                     # Pluggable transition system (used by the 2 Base*Controllers above)
    ├── NavigationTransitionAnimating.swift  # Root protocol for every effect (+ `reversed` for pop default)
    ├── CrossFadeTransition.swift            # Fade effect
    ├── SlideTransition.swift                # Directional slide effect (right/left/top/bottom) — app default
    ├── TransitionProviding.swift            # VC declares its own pushTransition/popTransition/tabTransition
    └── Hero/
        ├── HeroIdentifiable.swift  # UIView.heroID — tag marking source/destination views to morph
        └── HeroTransition.swift    # Animator morphing 1 shared element
```

## BaseViewController

Parent for every ViewController, building UI 100% in code (no Storyboard/XIB). Override 3 functions instead of `viewDidLoad()` directly:

```swift
final class SampleViewController: BaseViewController {
    override func setupViews() { /* add subview */ }
    override func setupConstraints() { /* Auto Layout */ }
    override func bindViewModel() { /* subscribe ViewModel output */ }
}
```

`showLoading()/hideLoading()/showError(_:)` are provided (the loading indicator is currently `TODO`, not yet implemented).

## BaseViewModel

`ViewModelType` requires `associatedtype Input/Output` + `transform(input:) -> Output` — does not import UIKit so it can be tested independently, without running UIKit. `ViewState<T>` (`idle/loading/success/failure`) is the shared state for every API call — reuse it instead of defining a custom state per feature.

## Coordinator

All navigation goes through a Coordinator; ViewControllers never `push`/`present` the next screen themselves.

- `addChild(_:)`: starts a child flow, auto-assigns `parentCoordinator` + keeps a reference (without this, the child coordinator is deinit'd immediately since nothing retains it).
- `finish()`: called when a child flow is done, auto-removes itself from the parent — concrete coordinators (Login, OTP...) should call this instead of manipulating the parent's `childCoordinators` directly.
- `FinishableCoordinator`: subclass when you need an `onFinish` callback reported back to the parent.

## Transition — screen transition effects

Each screen decides its own effect — `BaseNavigationController`/`BaseTabBarController` check the
concrete VC type at transition time (`decidingVC as? TransitionProviding`) and use whatever that VC
declares. **Screen A and screen B can use completely different effects** without touching the Base
controllers at all.

**Default** (VC does not conform to `TransitionProviding`): `SlideTransition(.rightToLeft)` for push
(same feel as UIKit's standard push), auto-reversed to `.leftToRight` for pop — for tab switches it's
`CrossFadeTransition`.

**Basic usage** — nothing extra needed, default slide effect applies automatically:

```swift
let nav = BaseNavigationController(rootViewController: HomeViewController())
navigationController.pushViewController(NextViewController(), animated: true)
```

**Custom effect for one screen** — conform to `TransitionProviding` directly on the destination VC
and return only `pushTransition`; `popTransition` defaults to `pushTransition?.reversed`, so you
rarely need to declare it yourself:

```swift
final class SettingsViewController: BaseViewController, TransitionProviding {
    var pushTransition: NavigationTransitionAnimating? {
        SlideTransition(direction: .bottomToTop) // pop auto-reverses to .topToBottom
    }
}

final class FilterViewController: BaseViewController, TransitionProviding {
    var pushTransition: NavigationTransitionAnimating? {
        CrossFadeTransition(duration: 0.25) // a different screen, a different effect — no conflict
    }
}
```

`SlideTransition` supports 4 directions (`rightToLeft`, `leftToRight`, `bottomToTop`, `topToBottom`)
and a `parallaxRatio` (how much the outgoing view shifts, 0 = stays still like a modal cover, default
0.3 = same feel as UIKit's standard push). It's built on `UIViewPropertyAnimator` (conforms to
`interruptibleAnimator(using:)`), so pausing/reversing mid-swipe during interactive pop is smooth
instead of just fast-forwarding to completion.

**Hero animation** — attach the same `heroID` to the source view (a cell in a list) and the destination view (the large image on the detail screen):

```swift
// Source
thumbnailImageView.heroID = "product-image-\(product.id)"

// Destination
final class ProductDetailViewController: BaseViewController, TransitionProviding {
    var pushTransition: NavigationTransitionAnimating? {
        HeroTransition(heroID: "product-image-\(product.id)")
    }
}
detailImageView.heroID = "product-image-\(product.id)"
```

**Custom effect for a tab** — conform to `TabTransitionProviding` on the VC attached to that tab:

```swift
final class ProfileViewController: BaseViewController, TabTransitionProviding {
    var tabTransition: NavigationTransitionAnimating? { CrossFadeTransition(duration: 0.2) }
}
```

To write a new effect (zoom, another hero...): create a class conforming to
`NavigationTransitionAnimating` — no need to touch `BaseNavigationController`/`BaseTabBarController`.
Override `reversed` too if the effect has a "direction" concept, so pop auto-picks the sensible
opposite when the VC only declares `pushTransition`.

### Current limitations (known, not bugs)

- `HeroTransition` supports only **1 shared element** per transition — multiple views morphing at once need a custom animator.
- Hero disables `supportsInteractiveDismissal` (no swipe-back while the hero effect is active) because morphing is hard to handle correctly if cancelled mid-way. `BaseNavigationController`'s edge-swipe gesture checks this flag before starting, so it won't trigger an abrupt non-interactive pop for Hero screens.
- `BaseNavigationController` implements its own `UIScreenEdgePanGestureRecognizer` for swipe-back (instead of the default `interactivePopGestureRecognizer`, which is disabled when a custom animator is set) — may conflict with views that scroll horizontally near the left edge (carousels...).
