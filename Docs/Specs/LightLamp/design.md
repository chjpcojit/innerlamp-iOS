# Design — LightLamp

Version: 2.0
Last updated: 2026-10-17
Status: in-progress (drift) — two screens, artwork, coordinator and entry points built on local Core Data; planned: server-driven lamps (`POST /v1/lamps`, `GET /v1/lamps`), sign-in gate, hide-name switch and notice, input check, new remaining-time label, own-lamp mark, drop the Core Data lamps, product vectors. Two contract changes (optional recipient, own-lamp flag) are not in `openapi.yaml` yet.

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. One feature folder, two screens (lighting, garden) owned by one `ILLightLampCoordinator`. It has two entry points that are both built: the center tab-bar lamp button (`ILMainTabCoordinator.showLightLamp()` → `startModal()`, full-screen over the tab bar) and Home's "Thắp đèn — Vu Lan" row (`ILHomeCoordinator.showLightLamp()` → `start()`, pushed), so it is a cross-section flow, not owned by one section. Shape reference: `Memorial` (server CRUD behind a repository protocol, two screens under one coordinator), without an offline copy.

How iOS meets the product constraints (product spec v1.0 §2.4, §2.7, §3.6, §3.7; see `requirements.md`):

- **The server is the only source of lamps** (BR-LMP-03…05, BR-LMP-08, BR-LMP-11, NFR-LMP-03): `ILLampRepositoryImpl` calls `POST /v1/lamps` and `GET /v1/lamps`. The Core Data `Lamp` entity, `ILLampMO` and `ILLampLocalDataSource` are removed; nothing is cached or kept across sign-out. The lamps stored by the pre-v2.0 app are dropped with the entity (the app is unreleased; product Appendix A).
- **The app displays, never decides**: no lighting moment, end moment or "is lit" rule is computed from the device. The only device-clock use is `ILLampRemaining.make(endAt:now:)` for the card label and the end-date formatting of the confirmation. The expiry rule of `ILLampEntity.daysLeft(now:)` (calendar days) is deleted.
- **One pure Domain rule per client-run vector** (product §4.1): `ILLampInputValidator` (BR-LMP-01/02/06/07) and `ILLampRemaining` (BR-LMP-12). Correctness is proven by the vector files, not restated here (see "Product vectors").
- **Guest gate** (BR-LMP-14, FR-LMP-013): the coordinator asks `ILAuthGate` (planned by `Docs/Specs/Login/`, Phase 6: reads the stored access token) before building either screen; a guest gets the introduction view and the lamp operations are never called.
- **The screens keep their layout**; changes to them are the switch, the notice, the confirmation's end line, the server-driven cards and the empty-state button.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity | `Domain/Entities/ILLampEntity.swift` | `ILLampKind` (oil / lotus / float), `ILLampIntention` (peace / dedication / departed / gratitude), `ILLampEntity` — a lamp the user has just lit, as the server returned it: id, kind, intention, `recipient: String?`, `prayer: String?`, durationDays, litAt, endAt. Foundation only. | built (local shape); **change**: `target` → `recipient: String?` (nil = all beings, the UI supplies the words), `vow` → `prayer: String?`; **add** `endAt`, id becomes the server's; **delete** `daysLeft(now:)` / `isActive(now:)` / `litAt`-based expiry |
| Domain / Entity | `Domain/Entities/ILGardenLampEntity.swift`, `ILGardenPageEntity.swift` | `ILGardenLampEntity` (id, kind, `recipient: String?`, `lighterName`, `endAt`, `isMine`); `ILGardenPageEntity` (items, `total`, `counts: [ILLampKind: Int]`, `hasMore`, `nextCursor`). Never carries an intention or a prayer. | planned — `isMine` and nullable recipient are ⚠️ contract (3.0.0) |
| Domain / Draft + rule | `Domain/UseCases/LightLamp/ILLampInputValidator.swift` | Pure: trims both ends, counts characters as Unicode scalars of the NFC form, accepts only the closed sets and durations, blank recipient / prayer → nil, returns the kept values or the first invalid field. Draft: `ILLampDraft` (kind, intention, recipient, prayer, durationDays, `hidesName`). | planned; `ILLampDraft` built (rename `target`/`vow`, add `hidesName`) |
| Domain / Rule | `Domain/UseCases/LightLamp/ILLampRemaining.swift` | Pure: `make(endAt:now:)` → `.days(n)`, `.underOneDay` or `.out`, exactly as BR-LMP-12 defines them. The label copy is built by the ViewModel. | planned |
| Domain / Repository protocol | `Domain/Repositories/ILLampRepository.swift` | `light(_ draft:) async throws -> ILLampEntity`, `loadGarden(filter: ILLampKind?, cursor: String?) async throws -> ILGardenPageEntity`; `ILLampError` (`invalidInput`, `limitReached`, `unauthorized`, `offline`, `serverError`). Replaces `loadAll()` / `save(_:)`. | built (local); **replace** |
| Domain / UseCase | `Domain/UseCases/LightLamp/ILLightLampUseCase.swift` | `light(_ draft:)` (validates with `ILLampInputValidator`, then the repository; the validated values are what is sent), `loadGarden(filter:cursor:)`. No `now:` parameter, no expiry filtering, no sorting (the server's order is kept). | built (local); **change** |
| Presentation / Common (dependency) | `Presentation/Common/Auth/ILAuthGate.swift` — `Docs/Specs/Login/` Phase 6 | `isSignedIn` from the stored access token; the sign-in action routes through `AppCoordinator`. | planned in Login — not built |
| Data / Remote | `Data/DataSources/Remote/LampsLightEndpoint.swift`, `LampsGardenEndpoint.swift` | One operation per file: `POST /v1/lamps`, `GET /v1/lamps?lamp_type=&cursor=` (Bearer). The app sends no `limit` (page size is the server's). | planned |
| Data / DTO + Mapper | `Data/DTOs/ILLampDTO.swift`, `Data/DTOs/Mappers/ILLampMapper.swift` | Wire ↔ entity: the type / intention codes ↔ `ILLampKind` / `ILLampIntention`, RFC 3339 UTC ↔ `Date`, nullable recipient / prayer, hide-name choice. Unknown codes in a response are a decode error, not a silent default. | planned — nullable recipient and `is_mine` ⚠️ contract (3.0.0) |
| Data / Repository impl | `Data/Repositories/ILLampRepositoryImpl.swift` | Wraps `NetworkService`; maps `NetworkError` to `ILLampError` (400 `VALIDATION_ERROR` → `invalidInput`, 409 `LAMP_LIMIT_REACHED` → `limitReached`, 401 → `unauthorized`, offline / timeout → `offline`, 5xx / other → `serverError`). Writes nothing locally. | built (Core Data wrapper); **rewrite** |
| Data / Local (remove) | `Data/DataSources/Local/ILLampLocalDataSource.swift`, `ILLampMO.swift`, entity `Lamp` in `InnerLamp 5.xcdatamodel` | Deleted. The model gets a new current version without `Lamp` (lightweight migration; the rows are discarded). | built; **delete** — coordinate with the Memorial plan, which also adds a model version (one new version for both if neither has landed) |
| Core / Session cleanup | `Data/Repositories/ILSessionDataCleanerImpl.swift` | Remove `ILLampMO.entityName` from `userScopedEntityNames` and the lamp wording of its doc comment (criterion 30). Must land **before or with** the entity removal, or the cleaner fails at runtime. | built (deletes lamps); **change** |
| Presentation / State | `Presentation/Scenes/LightLamp/ILLightLampStateModel.swift` | Phase (`form` / `lighting` / `done`), selected type / intention / duration, recipient and prayer text, `hidesName`, `inputError`, kicker, button label, `Completion` (caption, dedication line, prayer quote, **end line**). | built; **add** `hidesName`, `inputError`, `Completion.untilLine`; **remove or replace** the own-lamp `countLine` (⚠️ product, criterion 6) |
| Presentation / State | `ILLampGardenStateModel.swift` | Subtitle, chips (title, server count, selected), cards (**`isMine`**, lighter line, recipient line, remaining label), `hasMore`, `isLoadingMore`, `isEmpty`, `loadError`. | built; **change** — card `title` becomes the lighter's name or "Của bạn"; `remaining` from `ILLampRemaining`; counts from the server |
| Presentation / State | `ILLampGuestStateModel.swift` (or the Login shared prompt, ⚠️) | Introduction text and the button title "Đăng nhập để thắp đèn". | planned |
| Presentation / ViewModel | `ILLightLampViewModel.swift` | `Input -> Output`; builds the draft; local check → `inputError`; `phase` guard ignores taps and changes while `lighting` (BR-LMP-08, client side); calls `useCase.light`, then the 2.1 s ignite delay (`igniteDelay`, injectable); maps `ILLampError` to the §3.1.1 messages; builds the confirmation from the returned entity. Nav events `.back`, `.openGarden`, **`.signIn`**. | built (local); **change**: `hidesName` input, `Completion` from the server entity, error mapping, no `loadActiveCount()` |
| Presentation / ViewModel | `ILLampGardenViewModel.swift` | `Input -> Output`; first page, filter (`nil` = all), load more; keeps `filter` and `nextCursor`; a monotonically increasing request token so the answer of an older request is dropped (criterion 25); ignores load-more while loading; drops cards whose `ILLampRemaining` is `.out`. Nav events `.back`, `.openLighting`. | built (local, client paging, `pageSize = 12`); **rewrite**: server paging, remove `pageSize` |
| Presentation / Coordinator | `ILLightLampCoordinator.swift` | Lighting root pushed (`start()`) or presented full-screen in its own `BaseNavigationController` (`startModal()`); garden pushed on that stack; garden → lighting replaces the stack with a fresh form; `finish()` on back. | built; **add**: ask `ILAuthGate` first and build the guest view for a guest; `.signIn` dismisses the modal (when modal) and hands off to `AppCoordinator` |
| Presentation / ViewController | `ILLightLampViewController.swift`, `ILLampGardenViewController.swift` | `setupViews` / `setupConstraints` / `bindViewModel`. | built; **add**: the "Ẩn tên tôi" switch row and the visibility notice under "Dành cho", `inputError` message, end line in the confirmation, empty-state button, garden error state (with lighting still reachable) |
| Presentation / ViewController | `ILLampGuestViewController.swift` | Introduction and "Đăng nhập để thắp đèn". | planned — copy ⚠️ product; reuse of the shared prompt ⚠️ |
| Presentation / Views | `Scenes/LightLamp/Views/` | `ILLampArtView`, `ILLampStageView`, `ILLampKindPickerView`, `ILLampCardView` (garden cell + footer); reuses `ILNavBar`, `ILChip` / `ILChipFlowView` / `ILChipScrollView`, `ILInputCardView`, `ILSegmentedToggleView`, `ILButton`, `ILStateView`, `ILSwitchRowView`. | built; **change**: `ILLampCardView` highlights an own lamp, shows the lighter's name, no intention; `ILStateView` has no action, so the empty state gets a button below it (own small view or a button added in the controller) |
| Design system | `Tokens/ILColors`, `ILIcons`, `ILTypography`, `ILMetrics` | `ILColors.Lamp` (18 `ILLamp*` color sets) and `ILMetrics.Lamp`; an own-lamp highlight reuses existing tokens, a new one is added to the token file, not inlined. | built; own-lamp highlight planned |
| Home / Main (entry points) | `ILHomeViewModel.swift` (`.openLightLamp`), `ILHomeCoordinator.swift` (`showLightLamp()`), `ILMainTabCoordinator.swift` (`onLampTapped` → `showLightLamp()`), `ILMainTabBarController.swift` | Both entries open the same coordinator. Meditation: Home's `.meditation` row → `.openMeditationSetup`, and the Library tab's Meditation hub. | built; unchanged. `AS-LightLamp-005` already records the center button |
| DI | `App/DIContainer.swift` | `makeLampRepository` (remote only), `makeLightLampUseCase/ViewModel`, `makeLampGardenViewModel`, `makeLightLampCoordinator`; **remove** `lampLocalDataSource`. | built (local); **change** |
| Localization | `Resources/Localization/vi.json` | All copy under `lightLamp.*`. | built; **add** the §3.1.1 keys (limit, invalid input, lighting failed, garden failed, visibility notice, switch label, guest button / introduction, "Còn dưới 1 ngày", the end line, "Vô danh" is the server's); **update** `lightLamp.error.saveFailed` / `loadFailed` to the §3.1.1 text; **remove** `lightLamp.garden.card.left.lastDay` ("Sáng đến hết hôm nay"), `lightLamp.stage.count.*` if the count line is dropped (⚠️ product) |
| Tests | `InnerLampTests/ILLightLampUseCaseTests.swift`, `ILLightLampViewModelTests.swift`, `ILLampGardenViewModelTests.swift` | Use case, both ViewModels. Written, type-checked, never run (`TD-LightLamp-004`). | built; **rewrite** for the server-driven flow with a mock repository |
| Product vectors | `InnerLampTests/ILLampProductVectorTests.swift` + `InnerLampTests/ProductVectors/lamp/*.json` + `Scripts/sync-product-vectors.sh` | Runs every case of the two client product files (criterion 33). See "Product vectors". | planned |

## Navigation flow

```
ILMainTabCoordinator (center lamp button)  ─┐
ILHomeCoordinator (Home row → .openLightLamp)┘→ ILLightLampCoordinator (child)
       no session (ILAuthGate)             → guest view (introduction + "Đăng nhập để thắp đèn")
                                              (sign-in) → .signIn → dismiss modal if any → AppCoordinator → Login   (planned)
       session:
       start() push / startModal() present   ILLightLampViewController                      (lighting)
       (header "Vườn đèn" / "Vào vườn đèn")  → .openGarden  → push ILLampGardenViewController
       (garden header "Thắp đèn" / empty-state button) → .openLighting → fresh lighting form (stack replaced)
       (Back on lighting)                    → .back → finish()  (dismiss when modal, pop when pushed)
       (Back on garden)                      → .back → pop to lighting
```

## Step-by-step Flow

### Light a lamp (lighting screen "Thắp đèn")

```
Step 1 — Gate (this feature)
- Trigger: either entry point opens the coordinator
- Pre-condition: none
- Action: ILAuthGate.isSignedIn — false → guest view, stop (criterion 4). No lamp operation is called.

Step 2 — Local check (this feature)
- Trigger: "Thắp đèn" tapped while phase == form (taps in any other phase are ignored — criterion 12)
- Pre-condition: signed in
- Action: ILLampInputValidator over the draft: trim both ends, count NFC scalars (recipient ≤ 100,
  prayer ≤ 300), closed sets, durations 1/7/21/49; blank recipient / prayer → nil
    - Failure → inputError "Thông tin chưa hợp lệ. Vui lòng kiểm tra lại người nhận và lời nguyện.",
      phase stays form, nothing sent, stop (criterion 11)
    - Success → phase = lighting (button "Đang thắp…", lamp ignites), go to Step 3

Step 3 — Light the lamp (this feature)
- Trigger: Step 2 success
- API: POST /v1/lamps (lamp_type, intention, duration_days, recipient only when not blank,
  prayer only when not blank, is_anonymous from the switch)
  The app sends no id, no time and no name; the server decides the lighting and end moments.
  ⚠️ Not confirmed: not in openapi.yaml yet (planned 3.0.0, be spec v2.0) — omitting the recipient;
  the 2.1.1 contract requires it, so a blank recipient is rejected until the backend ships.
    - Success (201 new lamp, or 200 the identical lamp lit a moment ago) → Step 4
    - Failure (400 VALIDATION_ERROR) → phase = form, values kept, invalid-input message, stop
      (criterion 16)
    - Failure (409 LAMP_LIMIT_REACHED) → phase = form, values kept, limit message, stop (criterion 15)
    - Failure (401) → session-ended behavior of Docs/Specs/Login/; no lamp data (criterion 5), stop
    - Failure (offline / timeout / 5xx / other) → phase = form, values kept, "Chưa thắp được đèn.
      Vui lòng thử lại.", stop (criterion 17)

Step 4 — Ignite and confirm (this feature)
- Trigger: Step 3 success
- Action: wait the ~2.1 s ignite delay after the answer, as today (injectable `igniteDelay`, `.zero` in
  tests), then phase = done with the confirmation built from the returned lamp: caption, dedication line
  (recipient or "tất cả chúng sanh"), prayer quote, end line (endAt in the device time zone), actions
  "Thắp thêm đèn" and "Vào vườn đèn" (criterion 13). Nothing is saved on the device.

Step 5 — Next action (this feature)
- "Thắp thêm đèn" → phase = form, recipient and prayer emptied, type / intention / duration kept
  (criterion 18; the switch state is ⚠️ product)
- "Vào vườn đèn" → .openGarden → Garden flow below
```

### Garden ("Vườn đèn"): open, filter, load more

```
Step G-1 — Gate (this feature)
- Same as Step 1. A guest never reaches the garden.

Step G-2 — Load the first page
- Trigger: garden appears (viewDidLoad), or retry after a failed load
- Pre-condition: signed in
- API: GET /v1/lamps (no filter, no cursor)
  ⚠️ Not confirmed: not in openapi.yaml yet (planned 3.0.0, be spec v2.0) — each garden item says
  whether it is the caller's lamp (`is_mine`); the 2.1.1 items have no such flag, so own lamps cannot
  be marked yet (criterion 23).
    - Success → Step G-3
    - Failure (401) → session-ended behavior of Login (criterion 5)
    - Failure (offline / timeout / 5xx) → "Chưa tải được vườn đèn. Vui lòng thử lại sau.", lighting
      stays available via the header action (criterion 28), stop

Step G-3 — Render
- Action: subtitle from the response total; chips "Tất cả" + one per type with the response counts;
  cards in the response order; each card's label from ILLampRemaining at the device's current moment,
  a card whose label is `.out` is dropped; empty list → empty state with the button (criteria 21–24, 27).
  The list is applied as a diff (AGENTS §4.6): only new ids are inserted.

Step G-4 — Filter
- Trigger: a chip is tapped (a different one from the selected)
- API: GET /v1/lamps?lamp_type=<type> — or no lamp_type for "Tất cả"; no cursor
    - Success → replace the list, total and counts from this answer (Step G-3); an answer that
      belongs to an older request is dropped (criterion 25)
    - Failure → as Step G-2

Step G-5 — Load more
- Trigger: "Xem thêm đèn" tapped, `hasMore` true, no page is loading
- API: GET /v1/lamps?lamp_type=<current filter, if any>&cursor=<nextCursor of the last answer>
    - Success → append the new cards (no id is shown twice), update `hasMore` / `nextCursor`, total and
      counts from this answer (criterion 26)
    - Failure → keep the cards already shown, keep the button available (criterion 28)
```

Only the lighting flow has a write; the garden flow is reads. No flow here uses a second call of another feature except sign-in, which is `Docs/Specs/Login/`.

## Product vectors

Product §4.1 assigns two of the four vector files to the clients; the backend runs the other two (`lamp-lifetime` — end moment and "is lit"; `lamp-lighter-name` — the displayed name; both are decided by the server, and iOS only displays what it receives). On iOS:

- `Scripts/sync-product-vectors.sh` copies `../innerlamp-be/docs/product/lamp/rules/{lamp-input-validation,lamp-remaining-label}.json` into `InnerLampTests/ProductVectors/lamp/` and writes the source commit sha and file hashes to `InnerLampTests/ProductVectors/lamp/SOURCE`. The copy is a pinned, script-refreshed mirror — never edited by hand; a mismatch is fixed in the backend repo (via `ba-writer`) and re-synced. A bundled copy is needed because XCTest runs on a device that cannot read the sibling checkout. The script is shared with `Docs/Specs/Memorial/` (its Phase 6 plans the same script): whichever feature lands first creates it, the other adds its folder.
- `ILLampProductVectorTests` loads every case from the test bundle:
  - `lamp-input-validation.json` → `ILLampInputValidator` (valid / invalid field; kept recipient and prayer; `dedicated_to: all_beings` ⇔ recipient nil). The vector's `{"repeat": s, "times": n}` and `{"concat": [...]}` values are expanded by the test.
  - `lamp-remaining-label.json` → `ILLampRemaining.make(endAt: now + remaining_seconds, now:)` mapped to `kind` / `days`.
- Expected failures today: none can be run — neither rule exists yet. The Core Data rule they replace (`daysLeft`, calendar days) is the drift, not a test bug.

## Known gaps

Current iOS behavior (read in code on 2026-10-17) against product spec v1.0. Each has a `[ ]` task in `tasks.md` Phase 2–6 and a numbered criterion in `requirements.md` "Pending".

| Product ID | Today in the code | Where |
|---|---|---|
| BR-LMP-03 / BR-LMP-04 | Lamps are local; the end is the end of a calendar day (`ILLampEntity.daysLeft`: duration minus calendar days elapsed, active while ≥ 1) | `ILLampEntity.swift`, `ILLightLampUseCase.swift` |
| BR-LMP-05 | No limit of lit lamps | `ILLightLampUseCase.light` |
| BR-LMP-06 / BR-LMP-07 | No length limit on the recipient and the prayer (`AS-LightLamp-006`); trimming is done, a blank recipient is stored as "" | `ILLightLampUseCase.light`, `ILLightLampViewController` |
| BR-LMP-08 | Only the client half: taps are ignored while `phase != .form` (matches the product); no server de-duplication because there is no server | `ILLightLampViewModel.updateDraft`, `handleLight` |
| BR-LMP-09 / BR-LMP-10 | No hide-name switch; no visibility notice; own cards read "Của bạn · <intention>", showing the intention (`AS-LightLamp-004`) | `ILLampGardenViewModel.render`, `ILLightLampViewController` |
| BR-LMP-11 / FR-LMP-007 / FR-LMP-011 | Garden lists the user's own local lamps only (`AS-LightLamp-002`); total and per-type counts are computed from them; page size 12 is a local constant with client paging | `ILLampGardenViewModel` |
| BR-LMP-12 | Label "Còn N ngày" for more than one day, "Sáng đến hết hôm nay" for one day or less, from calendar days | `ILLampGardenViewModel.remainingText` |
| BR-LMP-14 / FR-LMP-013 | No sign-in gate; a guest can light lamps from Home's row and the center button (both open the coordinator without a check) | `ILMainTabCoordinator`, `ILHomeCoordinator` |
| FR-LMP-002 | Defaults correct (oil, peace, 7 days — `ILLampDraft`); no switch, no notice | `ILLightLampViewModel` |
| FR-LMP-003 | Saves to Core Data; the confirmation has no "until when" line; save error text "Chưa lưu được ngọn đèn. Vui lòng thử lại." differs from the product copy | `ILLightLampViewController`, `vi.json` |
| FR-LMP-006 | Elapsed lamps stay in Core Data forever (`TD-LightLamp-005`) and are filtered by the local rule | `ILLampLocalDataSource` |
| FR-LMP-008 | Own-lamp mark is implicit (everything is own) | `ILLampGardenViewModel` |
| FR-LMP-012 | Empty state has no button (`ILStateView` takes none; the header action "Thắp đèn" exists); load error is an alert with text "Chưa tải được Vườn đèn. Vui lòng thử lại." differing from the product copy | `ILLampGardenViewController`, `vi.json` |
| Sign-out | Deletes the lamps (`ILSessionDataCleanerImpl`, `Docs/Specs/Profile/` v1.4, `AS-Profile-003`) — product says stop | `ILSessionDataCleanerImpl.swift` |
| FR-LMP-001 | Both entries built and meet the product (center button → modal, Home row → push; meditation reachable from Home and the Library hub) | `ILMainTabCoordinator`, `ILHomeCoordinator`, `ILLibraryCoordinator` |
| FR-LMP-014 | Meets the product: no temple-lamp card or payment control on any lamp screen (`AS-LightLamp-008`) | `ILLightLampViewController` |
| BR-LMP-13 | Meets the product: no put-out, edit, extend or relight action | — |
| BR-LMP-01 / BR-LMP-02 | Meets the product: closed sets by enum (`ILLampKind`, `ILLampIntention`), durations `[1, 7, 21, 49]` (the check itself arrives with `ILLampInputValidator`) | `ILLampEntity.swift` |
| Tests | Written, type-checked, never run (`TD-LightLamp-004`); no vector tests | `InnerLampTests/` |
| English copy | The app has only `vi.json`; the English copy is ⚠️ product | `Resources/Localization/` |

Correction for the product matrix (§4.2) from reading the code: FR-LMP-012 is `done` there; on iOS the empty state has no button and the error copy differs, so it is `drift` until Phase 4.

## Deliberately stubbed for now

- Nothing is stubbed in the sense of a fake network call: v1.x had no network at all (local Core Data, `AS-LightLamp-001`). v2.0 starts the network integration; until the backend ships contract 3.0.0 the blank-recipient lighting and the own-lamp mark cannot work end to end (⚠️ in Step 3 and Step G-2). The guest-view copy, the lighting-screen count line and the "Ẩn tên tôi" state after "Thắp thêm đèn" wait for the product owner (⚠️ in `requirements.md`).
- "Thỉnh đèn tại chùa" and the donation flow: not built, not offered (FR-LMP-014; `TD-LightLamp-002`).

## Design reference

Prototype `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html` screens `offer` and `garden`; artwork `IL-LampArt.dc.html` (the prototype's temple-lamp card and meditation center button are superseded by the product spec). The "Ẩn tên tôi" row and the visibility notice are not in the prototype; they take their wording from product §3.1.1 and the look of the existing switch row.
