# Design — LunarDayDetail

Version: 2.0
Last updated: 2026-10-07
Status: lunar data implemented (pure client-side computation); hero image from
`GET /v1/calendar/image` specified, implementation pending

> See `changelog.md` in this folder for the version history of this spec.

## Overview

LunarDayDetail follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**leaf screen** owned by `ILHomeCoordinator` (not `AppCoordinator`), reached only
from within the Home section. The whole feature is a pure computation over
`ILLunarCalendar` from a passed-in solar `Date` and needs no network. The one
exception (v2.0) is the **hero background image**: a single public
`GET /v1/calendar/image?date=…` call, loaded in parallel and never blocking the
screen. That call alone adds a small Data layer (Endpoint, DTO, Mapper,
Repository) — the lunar computation itself still has none.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLunarDayDetailEntity.swift` | Pure business fields for one solar day: `date`, solar day/month/year, lunar day/month/year + leap flag, `isHoangDao`, day can/chi indices, six good-hour chi indices, clash chi index, joy/wealth directions, `craneStarDirection: String?` (Hạc thần, `nil` when in heaven), verse lines + source. No UI-only state. |
| Domain / UseCase | `Domain/UseCases/LunarDayDetail/ILLunarDayDetailUseCase.swift` | `getDetail(for:) -> ILLunarDayDetailEntity` — computes lunar conversion, can-chi, good hours, clash, directions, and the verse via `ILLunarCalendar`. Pure, synchronous. No stub needed (no network/disk). |
| Domain / Entity (new) | `Domain/Entities/ILCalendarImageEntity.swift` | One calendar image: `id`, `imageURL`, `author`, `license`, `licenseURL?`, `sourceURL?`. Raw server values, no formatting. |
| Domain / Repository (new) | `Domain/Repositories/ILCalendarImageRepository.swift` | `loadImage(for: Date) async throws -> ILCalendarImageEntity`; throws `ILCatalogError`. Network-only, no cache of its own. |
| Domain / UseCase (new) | `Domain/UseCases/LunarDayDetail/ILCalendarImageUseCase.swift` | `loadImage(for:) async throws -> ILCalendarImageEntity?` — returns `nil` without calling the repository when the solar year is outside 1900–2100. |
| Data / Endpoint (new) | `Data/DataSources/Remote/CalendarImageEndpoint.swift` | `GET /v1/calendar/image?date=yyyy-MM-dd`, `requiresAuth == false`. |
| Data / DTO (new) | `Data/DTOs/ILCalendarImageDTO.swift` | Wire format `{date, id, image_url, author, license, license_url, source_url}` (`.convertFromSnakeCase`, no `CodingKeys`). |
| Data / Mapper (new) | `Data/DTOs/Mappers/ILCalendarImageMapper.swift` | DTO → entity; trims strings, empty `image_url` → mapping fails (no image), empty `license_url`/`source_url` → `nil`. Also formats the `date` query value. |
| Data / Repository impl (new) | `Data/Repositories/ILCalendarImageRepositoryImpl.swift` | Calls the endpoint through `NetworkService`; every failure → `ILCatalogError.from(_:)` (`INVALID_DATE` falls into `.loadFailed`). |
| Presentation / State | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailStateModel.swift` | UI-only state: `.localized`/formatted display values (hero, day-type pill + tone, info rows, good hours, clash, directions), plus `heroImageURL: String?` and `heroImageCredit: String` (empty = hidden). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailViewModel.swift` | `Input` (`viewDidLoad`, `backTapped`) → `Output` (`ViewState<ILLunarDayDetailStateModel>`); owns the `ILLunarDayDetailNavEvent` publisher; maps Entity → StateModel in `makeStateModel`. v2.0: takes `ILCalendarImageUseCase`; on `viewDidLoad` loads the hero image once in a `Task`, stores it, re-publishes state with `heroImageURL` + formatted credit; a failure/`nil` is logged in DEBUG and leaves both empty (never `.failure`). |
| Presentation / Coordinator | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailCoordinator.swift` | Pushes `ILLunarDayDetailViewController`; `.back` → pop + `finish()`. No delegate (leaf). |
| Presentation / ViewController | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailViewController.swift` | Full-bleed hero + info table + verse + good hours + clash + directions; transparent → opaque header after >110 px scroll. UI split into `Views/` (hero, info, verse, good hours, clash, directions). |
| Presentation / Hero view (modified) | `Presentation/Scenes/LunarDayDetail/Views/ILLunarDayDetailHeroView.swift` | v2.0: adds an `ILRemoteImageView` behind the content (placeholder = the existing gradient), a scrim layer on top of it (clear at the top → `ILColors.canvas` at the bottom, trait-aware like the gradient), and a caption label for the credit. `configure(...)` gains `imageURL` / `creditText`; `setImage(urlString:)` is called **only when the URL changed**, because every state emission re-runs `configure`. |
| Localization (modified) | `Resources/Localization/vi.json` | New key `lunarDayDetail.hero.imageCreditFormat` = "Ảnh: %@ · %@". |
| Wiring (modified) | `App/DIContainer.swift` | `makeCalendarImageRepository()` / `makeCalendarImageUseCase()`; `makeLunarDayDetailViewModel` passes the use case. |
| Shared helper (modified) | `Core/Utils/ILLunarCalendar.swift` | Extended with `canChiDay/canChiMonth/canChiYear`, `isHoangDao`, `goodHourChiIndices`, `clashChiIndex`, `joyStarDirection`, `wealthStarDirection` used by this feature. |
| Design System tokens (modified) | `ILColors` (`ILSunk2`, `ILClashForeground`) | New tokens for the hero gradient and clash accents. |

## Navigation flow

```
ILHomeCoordinator
  └─ (tap large lunar card) → ILHomeNavEvent.openLunarDayDetail(date:)
       → showLunarDayDetail(date:) → ILLunarDayDetailCoordinator
            push ILLunarDayDetailViewController
            (tap ‹) → ILLunarDayDetailNavEvent.back → pop + finish()
```

## API contract

Source: backend team (`[BE]-InnerLamp`), 2026-10-07, `docs/specs/features/
calendar/api-contract.md` (backend repo), verified against a real server by the
backend (tests pass, curl OK). The dev server on `:8080` had to be restarted
(`make run`) to expose the route.

| Item | Value |
|---|---|
| Route | `GET /v1/calendar/image?date=YYYY-MM-DD` — public, GET only, no `Authorization` |
| `date` | optional **solar** date, 1900..2100; omitted = today in `Asia/Ho_Chi_Minh`. iOS always sends it (the server knows no lunar calendar) |
| Mapping | same date → same image; consecutive days → different images (100-day cycle, 100 images) |
| `data` | `{date, id, image_url, author, license, license_url, source_url}` inside `{"success":true,"data":...}`; snake_case |
| `image_url` | absolute URL built from the request host (dev, same Wi-Fi), JPEG ≤ 1200 px, ~340 KB; no `thumbnail_url` |
| Errors | `400 INVALID_DATE` (`details.field = "date"`) for a malformed date (`2026-1-5`, `2026-02-30`) or a year outside 1900..2100 |
| Cache | with `date`: `Cache-Control: public, max-age=86400`; without: `no-cache`; no `ETag`. Images under `/static/images/` also `max-age=86400` |
| Attribution | 100 Wikimedia images, mostly CC BY / CC BY-SA — author + license must be shown |
| Example | `{"success":true,"data":{"date":"2026-10-07","id":"buddha_034","image_url":"http://<host>:8080/static/images/home-calendar/buddha_034.jpg","author":"Judgefloro","license":"Public domain","license_url":"https://commons.wikimedia.org/…","source_url":"…"}}` |

> `image_url` is a dev-only static file served from the backend's disk, so the
> host is the backend machine's LAN IP and changes per network — it is used
> verbatim, never rebuilt (same rule as the gallery).

## Step-by-step Flow

One network call (the lunar data itself is local), so this is a single step.

```
Step 1 — Load hero image (this feature)
- Trigger: ILLunarDayDetailViewModel handles viewDidLoad (once per screen instance)
- Pre-condition: screen has its solar `Date`; solar year within 1900..2100
  (otherwise the use case returns nil and no request is made)
- API: GET /v1/calendar/image?date=yyyy-MM-dd  (Gregorian components of `Date`)
    - Success → store entity, publish state with heroImageURL + credit; hero view
      loads the image through ILRemoteImageView (off the main actor, downsampled)
    - Failure (offline / INVALID_DATE / 5xx / bad payload) → no state change, hero
      keeps the gradient, no attribution, no error UI
    - Image URL fails to load (404, DNS, wrong LAN IP) → ILRemoteImageView keeps the
      placeholder gradient; the credit line stays visible (see ⚠️ below)
```

> ⚠️ Not confirmed: whether the credit line should hide when the image bytes
> fail to load after a successful JSON response — `ILRemoteImageView` has no
> completion callback, so v2.0 shows the credit whenever the JSON succeeded.
> Blocks nothing; recorded as `TD-LunarDayDetail-003`.

## Data flow

Lunar data is a single synchronous computation; the hero image is the only
network call (Step 1 above):

1. `ILHomeCoordinator` passes the selected solar `Date` into
   `ILLunarDayDetailCoordinator` / `makeLunarDayDetailViewModel(date:)`.
2. `ILLunarDayDetailViewModel` calls `useCase.getDetail(for: date)` to build the
   initial `ILLunarDayDetailEntity`, then maps it to
   `ILLunarDayDetailStateModel` and emits `.success(state)`.
3. `viewDidLoad` re-runs the same computation and re-emits the state, then
   starts the hero-image `Task` (and the existing daily-verse load). Each result
   re-emits the state; the hero view ignores an unchanged `heroImageURL`, so the
   verse/image emissions do not reload the picture.

Main-thread note (`AGENTS.md` §4.6): the request is async off the UI path; the
image fetch/decode/downsample happens inside `ILRemoteImageView`, and only the
finished bitmap is assigned on main. The hero is a fixed 380 pt tall view, so the
downsample target is known at first layout.

## Deliberately stubbed for now

None — `ILLunarDayDetailUseCase.getDetail(for:)` is fully implemented as a pure
computation, and the calendar-image API contract is confirmed, so no stub is
needed. Remaining items (non-Vietnamese localization, tappable attribution link,
production image hosting) are recorded in `requirements.md` Pending and under
`Docs/Tech-Debt/LunarDayDetail/`, not code stubs.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
(lunar detail screen) and `Mo-ta-tinh-nang.md` §5 "Chi tiết ngày âm". See
`InnerLamp/Presentation/Scenes/LunarDayDetail/README.md` for the
design-vs-implementation comparison and known gaps.
