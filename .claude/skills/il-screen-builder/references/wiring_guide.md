# Wiring a New Feature into DIContainer + Parent Coordinator

After generating the `IL{{Feature}}` files from `assets/templates/`, wire them in exactly two
places. Do not instantiate `UseCase`/`ViewModel`/`Coordinator` anywhere else.

## 1. `InnerLamp/App/DIContainer.swift`

Add a `// MARK: - {{Feature}}` section with factory methods, following the existing `Onboarding`
section as the pattern. Factory **method** names stay feature-name-only (no `IL`); their return
**types** carry the `IL` prefix:

```swift
// MARK: - {{Feature}}
func make{{Feature}}UseCase() -> IL{{Feature}}UseCase {
    IL{{Feature}}UseCaseImpl() // add real dependencies only alongside their real implementation
}

func make{{Feature}}ViewModel() -> IL{{Feature}}ViewModel {
    IL{{Feature}}ViewModel(useCase: make{{Feature}}UseCase())
}

func make{{Feature}}Coordinator(navigationController: UINavigationController) -> IL{{Feature}}Coordinator {
    IL{{Feature}}Coordinator(navigationController: navigationController, container: self)
}
```

If the screen is pure UI with no validation logic, it is acceptable to skip the `UseCase` layer
entirely — in that case `IL{{Feature}}ViewModel` takes no `useCase` dependency and
`make{{Feature}}UseCase()` is omitted. Only do this when explicitly confirmed the screen needs no
domain logic; default to including a `UseCase` since it costs little and keeps the pattern
consistent. Do **not** inject `NetworkService`/a Repository into `IL{{Feature}}UseCaseImpl` just
to "wire it up" — see `references/data_layer_boundaries.md`; add that dependency later, together
with the real implementation it serves.

## 2. Parent coordinator

Determine the parent per `references/coordinator_navigation_rules.md`:

- **Major/cross-section flow** → wire into `InnerLamp/App/AppCoordinator.swift`.
- **Within an existing section** (e.g. reachable from Home) → wire into that section's coordinator
  (e.g. `HomeCoordinator`). Create the section coordinator first if it doesn't exist yet, using the
  same `Coordinator` conformance shape as `IL{{Feature}}Coordinator`'s template.

Add a private `show{{Feature}}()` method to the parent, mirroring `AppCoordinator.showOnboarding()`:

```swift
private func show{{Feature}}() {
    let coordinator = container.make{{Feature}}Coordinator(navigationController: navigationController)
    coordinator.delegate = self
    addChild(coordinator)
    coordinator.start()
}
```

Then conform the parent to `IL{{Feature}}CoordinatorDelegate` in an extension and react to each
delegate call (navigate further, or nothing if `{{Feature}}` is a leaf screen with no outgoing
delegate events — in that case the delegate protocol can stay empty and this conformance can be
skipped).

## Sanity checklist before finishing

- [ ] `IL{{Feature}}Entity` in `Domain/Entities/` — pure business fields only, no `*Error`/
      `isSubmitting`/display-formatting fields (see `references/data_layer_boundaries.md`)
- [ ] `IL{{Feature}}StateModel` in `Presentation/Scenes/{{Feature}}/` (not `Domain/Entities/`) —
      owned by `IL{{Feature}}ViewModel`, is the `T` in `ViewState<T>`
- [ ] `IL{{Feature}}DTO` + `IL{{Feature}}Mapper` in `Data/DTOs/` + `Data/DTOs/Mappers/` — only if a
      confirmed API contract exists for this feature; otherwise correctly skipped (not generated
      speculatively)
- [ ] `IL{{Feature}}UseCase` / `IL{{Feature}}UseCaseImpl` in `Domain/UseCases/{{Feature}}/` (skip only if confirmed pure-UI)
- [ ] Every `IL{{Feature}}UseCase` method that would need a network/Repository call is a one-line
      TODO-print stub (not a guessed real implementation); only pure client-side validation and
      Entity/StateModel/DTO mapping are genuinely implemented (see
      `references/data_layer_boundaries.md`)
- [ ] `IL{{Feature}}Coordinator` + `IL{{Feature}}CoordinatorDelegate` in `Presentation/Scenes/{{Feature}}/`
- [ ] `IL{{Feature}}ViewController` in `Presentation/Scenes/{{Feature}}/`
- [ ] `IL{{Feature}}ViewModel` + `IL{{Feature}}ViewModelProtocol` + `IL{{Feature}}NavEvent` in `Presentation/Scenes/{{Feature}}/`
- [ ] `IL{{Feature}}ViewModelTests` in `InnerLampTests/`, one real (non-placeholder) test per
      action/trigger, driven through its `Input` publisher (never by calling a private `handle*()`
      method directly), mocking `IL{{Feature}}UseCase` directly (see
      `references/mvvm_pattern.md` §Testing)
- [ ] `README.md` in `Presentation/Scenes/{{Feature}}/`, Status table reflects what was actually
      built this run (rows legitimately say "Skeleton" where true), Navigation events section
      lists real `IL{{Feature}}NavEvent` cases, Changelog has an entry — if updating an existing
      feature, the existing README was edited in place, not overwritten
- [ ] New `README.md` added to the `membershipExceptions` list in
      `InnerLamp.xcodeproj/project.pbxproj` (`PBXFileSystemSynchronizedBuildFileExceptionSet` for
      the `InnerLamp` target) as `Presentation/Scenes/{{Feature}}/README.md` — every scene's
      `README.md` shares the same bundle output filename, so a second one not excluded collides
      with another scene's at build time ("Multiple commands produce '.../InnerLamp.app/README.md'")
- [ ] Every screen UI piece that can stand on its own was pulled into its own `View` file (not
      inlined in the ViewController) — not optional, do this as part of building the screen
- [ ] Each split-out view was judged for reuse: generic/no feature content → promoted to
      `Presentation/Common/DesignSystem/Components/` as `IL<Name><Kind>`; feature-specific → stays
      in `Presentation/Scenes/{{Feature}}/Views/` as `IL{{Feature}}<Name>View`
- [ ] `DIContainer` has `make{{Feature}}UseCase()` / `make{{Feature}}ViewModel()` / `make{{Feature}}Coordinator(navigationController:)`
- [ ] Correct parent coordinator (`AppCoordinator` vs. section coordinator) calls `addChild(_:)` + `start()`
- [ ] No edits to any file under `InnerLamp/Core/Base/`
- [ ] No transition code added unless the user explicitly asked for a non-default effect
- [ ] Every new type/file name starts with `IL` and otherwise follows `references/naming_conventions.md`
- [ ] No user-facing string literal — every one goes through `"key".localized` (the project's
      own JSON localization system, `InnerLamp/Core/Localization/`, not Apple's String Catalog),
      with the key added to `InnerLamp/Resources/Localization/vi.json`
      (see `references/design_tokens_rules.md` §1)
- [ ] No hardcoded font size — every text style comes from an `ILTypography` preset, adding a new
      one there if none fits (see `references/design_tokens_rules.md` §2)
- [ ] No hardcoded color — every color comes from `ILColors`, adding a new asset-backed constant
      or alpha-derived one there if none fits (see `references/design_tokens_rules.md` §3)
- [ ] Every existing `IL*` component/token that fits was reused (configured via its params), not
      re-implemented inline
- [ ] Any new generic UI primitive was added as a parameterized `IL<Name><Kind>` in
      `DesignSystem/Components/` (not duplicated as a one-off in `Scenes/{{Feature}}/Views/`)
