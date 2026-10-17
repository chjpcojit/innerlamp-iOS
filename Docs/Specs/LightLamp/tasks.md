# Tasks — LightLamp

Version: 2.0
Last updated: 2026-10-17
Status: in-progress (drift) — Phase 1 (the built shell) was read in code on 2026-10-17 and still matches; Phase 2–6 (server-driven lamps, guest gate, hide-name switch, new label, vectors) not started. Phase 3 end-to-end items are blocked on contract 3.0.0 (optional recipient, own-lamp flag).

> See `changelog.md` in this folder for the version history of this spec.

Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flows. `[x]` means the item was verified in the code on 2026-10-17 by reading it; the unit tests of the feature have never been run (`TD-LightLamp-004`), so no item is ticked on the strength of a test.

## Phase 1 — Built shell (kept in v2.0)

- [x] Lighting screen and its phases `form → lighting → done`, option selection, ~2.1 s ignite delay injectable as `igniteDelay` (`ILLightLampViewController`, `ILLightLampViewModel`, `ILLightLampStateModel`) (criteria 8, 12)
- [x] Defaults oil lamp, Cầu an, 7 days (`ILLampDraft`) (criterion 7, the switch part is Phase 4)
- [x] Taps and selections ignored while lighting (`updateDraft` / `handleLight` guard on `phase == .form`) (criterion 12)
- [x] "Thắp thêm đèn" returns to the form with the previous type, intention and duration (`handleAgain`) (criterion 18, the switch state is ⚠️ product)
- [x] Garden screen shell: filter chips, two-column diffable grid with incremental updates, "Xem thêm đèn" footer, empty-state view (`ILLampGardenViewController`, `ILLampCardView`) (criteria 21, 26, 27 layout)
- [x] Lamp artwork, stage and kind picker views (`ILLampArtView`, `ILLampStageView`, `ILLampKindPickerView`); `ILColors.Lamp` / `ILMetrics.Lamp` tokens
- [x] `ILLightLampCoordinator`: `start()` push, `startModal()` full-screen, garden push, garden → fresh lighting form, `finish()` on back (criterion 29)
- [x] Center tab-bar lamp button presents Thắp đèn (`ILMainTabCoordinator.onLampTapped` → `showLightLamp()`) (criterion 1)
- [x] Home's "Thắp đèn — Vu Lan" row pushes Thắp đèn (`ILHomeViewModel` `.offering` → `.openLightLamp` → `ILHomeCoordinator.showLightLamp()`) (criterion 2)
- [x] Meditation reachable from Home's meditation row (`.openMeditationSetup`) and the Library tab's Meditation hub (`ILLibraryCoordinator.showMeditationHub()`), not from the center button (criterion 3)
- [x] No "Thỉnh đèn tại chùa" card, donation or payment control on the form, the confirmation or the garden (criterion 19, FR-LMP-014)
- [x] `lightLamp.*` copy exists in `vi.json`; Phase 4 updates and adds keys
- [x] `DIContainer.makeLightLamp*` / `makeLampGardenViewModel` / `makeLightLampCoordinator` wiring exists; Phase 3 changes the repository it builds

## Phase 2 — Domain (local rules replaced)

- [ ] `ILLampInputValidator` (pure, Foundation only): trim both ends, count NFC scalars (recipient ≤ 100, prayer ≤ 300), closed sets, durations 1/7/21/49, blank recipient / prayer → nil (criteria 10, 11; BR-LMP-01, 02, 06, 07)
- [ ] `ILLampRemaining.make(endAt:now:)` → `.days(n)` / `.underOneDay` / `.out` (criterion 24; BR-LMP-12)
- [ ] `ILLampEntity`: `target` → `recipient: String?`, `vow` → `prayer: String?`, add `endAt`; delete `daysLeft(now:)` / `isActive(now:)` (calendar-day expiry, `AS-LightLamp-003`)
- [ ] `ILGardenLampEntity` and `ILGardenPageEntity` (never an intention or a prayer) (criteria 21, 22)
- [ ] `ILLampDraft`: rename `target`/`vow`, add `hidesName`
- [ ] `ILLampRepository` protocol: `light(_:)` and `loadGarden(filter:cursor:)`; `ILLampError` cases `invalidInput` / `limitReached` / `unauthorized` / `offline` / `serverError` (replaces `loadAll()` / `save(_:)`)
- [ ] `ILLightLampUseCase`: `light(_ draft:)` validates then calls the repository; `loadGarden(filter:cursor:)`; drop `now:`, expiry filtering and sorting (the server's order is kept)

## Phase 3 — Data (server) and removal of the Core Data lamps

- [ ] Confirm the operations in innerlamp-be `docs/specs/api/openapi.yaml`: `POST /v1/lamps` and `GET /v1/lamps` exist at 2.1.1; the optional recipient and the own-lamp flag do **not** (⚠️ planned 3.0.0, be spec v2.0) — cite, never copy the schema; update the `Contract:` line of `requirements.md` when 3.0.0 is adopted
- [ ] `LampsLightEndpoint` (`POST /v1/lamps`) and `LampsGardenEndpoint` (`GET /v1/lamps?lamp_type=&cursor=`) in `Data/DataSources/Remote/` (Steps 3, G-2, G-4, G-5)
- [ ] `ILLampDTO` + `ILLampMapper`: type / intention codes, RFC 3339 UTC dates, nullable recipient / prayer, hide-name choice; an unknown code in a response fails decoding (only once the contract in the first item is confirmed — never created speculatively)
- [ ] `ILLampRepositoryImpl` rewritten over `NetworkService`, `NetworkError` → `ILLampError`; no local write (criterion 30)
- [ ] `DIContainer`: build the remote-only repository; remove `lampLocalDataSource`
- [ ] `ILSessionDataCleanerImpl`: remove `ILLampMO.entityName` from `userScopedEntityNames` and the lamp wording of its doc comment (criterion 30); land before or with the next item
- [ ] Delete `ILLampMO`, `ILLampLocalDataSource`; new current Core Data model version without the `Lamp` entity (lightweight migration; the stored lamps are discarded, not uploaded) — one new version shared with the Memorial plan if that has not landed yet
- [ ] Manual test against the staging backend once 3.0.0 is deployed: blank recipient, hide name, own-lamp mark on two devices, limit, double tap, paging with expiring lamps

## Phase 4 — Presentation

- [ ] Guest gate: `ILLightLampCoordinator` asks `ILAuthGate` (Login Phase 6) before building a screen; `.signIn` nav event → dismiss the modal if any → `AppCoordinator` → Login (criterion 4, Step 1)
- [ ] Guest view: introduction + "Đăng nhập để thắp đèn" (`ILLampGuestViewController` / `ILLampGuestStateModel`, or the shared prompt) — blocked by the two ⚠️ of criterion 4 (copy; reuse of the shared prompt)
- [ ] "Ẩn tên tôi" switch row (`ILSwitchRowView`, off by default) and the notice "Người khác sẽ thấy tên người nhận." under "Dành cho", text exactly as product §3.1.1 (criteria 6, 7, 9, 14)
- [ ] `ILLightLampStateModel` / `ILLightLampViewModel`: `hidesName`, `inputError` from `ILLampInputValidator` (criterion 11), `ILLampError` → §3.1.1 messages with the form kept (criteria 15–17), confirmation built from the returned lamp with the end line in the device time zone (criterion 13), recipient nil → "tất cả chúng sanh", remove `loadActiveCount()`
- [ ] Lighting-screen count line: keep, change or remove — blocked by the ⚠️ (product) of criterion 6
- [ ] "Ẩn tên tôi" after "Thắp thêm đèn" — blocked by the ⚠️ (product) of criterion 18
- [ ] `ILLampGardenViewModel` rewritten: first page, filter, load more with `nextCursor`, request token to drop stale answers, ignore load-more while loading, drop `.out` cards, remove the local `pageSize` (criteria 20, 21, 24–26; Steps G-2…G-5)
- [ ] `ILLampGardenStateModel` / `ILLampCardView`: lighter's name or "Của bạn" with the own-lamp highlight, "Cho <recipient>" or "Cho tất cả chúng sanh", no intention, label from `ILLampRemaining` (criteria 22–24) — the own-lamp mark is blocked by contract 3.0.0
- [ ] Card end date/time — blocked by the ⚠️ (product) of criterion 22
- [ ] Empty state with the "light a lamp" button; garden error state with lighting still reachable; failed load-more keeps the cards (criteria 27, 28)
- [ ] `vi.json`: add the §3.1.1 keys (limit, invalid input, lighting failed, garden failed, notice, switch label, guest copy, "Còn dưới 1 ngày", end line); change `lightLamp.error.saveFailed` / `loadFailed` to the product text; remove `lightLamp.garden.card.left.lastDay` and the unused count-line keys (criterion 32); the English copy waits for the product owner
- [ ] The recipient and the prayer never reach logs, Sentry or analytics (criterion 31)

## Phase 5 — Tests and vectors

- [ ] `Scripts/sync-product-vectors.sh` (shared with `Docs/Specs/Memorial/` Phase 6; add the lamp folder): copies `../innerlamp-be/docs/product/lamp/rules/{lamp-input-validation,lamp-remaining-label}.json` into `InnerLampTests/ProductVectors/lamp/`, records the commit sha and hashes in `SOURCE`; the copy is never hand-edited; add the JSON files to the test target's resources
- [ ] `ILLampProductVectorTests`: run **every case** of `lamp-input-validation.json` against `ILLampInputValidator` (BR-LMP-01, 02, 06, 07) and of `lamp-remaining-label.json` against `ILLampRemaining` (BR-LMP-12) (criterion 33); `lamp-lifetime.json` and `lamp-lighter-name.json` are backend-run (product §4.1) and are not run on iOS
- [ ] Rewrite `ILLightLampUseCaseTests`, `ILLightLampViewModelTests`, `ILLampGardenViewModelTests` with a mock `ILLampRepository`: local check, each `ILLampError`, double tap, hide name sent, confirmation from the returned lamp, filter, stale answer dropped, load more without repeats, failed load-more keeps cards, guest never calls the repository
- [ ] Run the unit tests on a device or a confirmed-stable simulator (`TD-LightLamp-004` — never run so far)
- [ ] Visual QA on device: artwork, own-lamp highlight, switch row, notice, empty state, Dynamic Type, dark mode (`TD-LightLamp-003`)

## Phase 6 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/LightLamp/README.md`: replace "local-only", status table and known gaps with the v2.0 state (it is a `membershipExceptions` entry already)
- [ ] Close the Assumption and Tech Debt entries of the feature as the code lands — set `status`, `updated` and the Outcome / Resolution; never delete them (`AGENTS.md` §10.3): `AS-LightLamp-001…004` and `006` become Invalidated, `AS-LightLamp-007` and `008` Validated (`005` already Invalidated); `TD-LightLamp-001` and `005` Resolved
- [ ] `Docs/Specs/Profile/` (v1.4 sign-out wording, `AS-Profile-003`) and `Docs/Specs/Donate/design.md` (mentions `ILLightLampCoordinator.startModal()`): update the lamp mentions in their own spec updates
- [ ] `Docs/Knowledge/features/lightlamp.md` (OKF concept) — hold off until Phase 3–4 are verified end to end against the backend. See `Docs/Specs/OKF.md`.

## Deferred (separate feature, not blocking LightLamp)

- "Thỉnh đèn tại chùa", payment and donation — the `offering` feature (`TD-LightLamp-002`).
- The shared sign-in prompt component and the session-ended message — `Docs/Specs/Login/` Phase 3 and 6.
- Sharing a lit lamp, an English locale, a "my lamps" screen — undecided or out of scope in the product spec.
