# Almanac — Offline Personal Almanac Engine (Lịch Pháp & Trạch Cát)

Engine that computes the full daily almanac for a target date, entirely offline, optionally
personalized against a user's birth date. All computation lives in `ILLunarCalendar`; the use case is
a thin wrapper that turns a stored birth profile into the optional birth date.

## Overview

One unified entry point — `ILLunarCalendar.almanac(day:month:year:birthDay:birthMonth:birthYear:)`
(and the `Date` convenience `almanac(date:birthDate:)`):

- **No birth date** (`nil`) → the general (universal) day evaluation: lunar date, Can-Chi,
  Hoàng đạo/Hắc đạo, 12 Trực, 28 Tú, Tiết khí, Hỷ/Tài thần, giờ hoàng đạo, plus a general
  Hung/Cát score (Hoàng đạo `60` / Hắc đạo `40`) and Trực-based recommendations.
- **With birth date** → additionally personalizes the Hung/Cát fields via the personal matcher
  (Lục Xung / Tam Hợp / Nhị Hợp + Ngũ Hành Nạp Âm).

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Core — engine | `Core/Utils/ILLunarCalendar.swift` | Done | The whole engine: `almanac(...)` unified entry, `AlmanacResult`, `ILAuspiciousTier` + `ILFiveElements` (+ Wu Xing), Nạp Âm table, `personalEvaluation`, `evaluateActions`, `tier(for:)`, plus all calendar helpers (lunar conversion, Can-Chi, Hoàng đạo/Hắc đạo, Tiết khí, 12 Trực, 28 Tú, giờ hoàng đạo, Hỷ/Tài thần). |
| Domain — Entity | `Domain/Entities/ILAlmanacEntity.swift` | Done | `ILUserBirthProfileEntity` only (the stored birth profile). |
| Domain — UseCase | `Domain/UseCases/Almanac/ILAlmanacUseCase.swift` | Done | Thin wrapper: `makeBirthProfile` + `calculateDailyAlmanac(for:profile:)` → delegates to `ILLunarCalendar.almanac(date:birthDate:)`. |
| Domain — Repository | `Domain/Repositories/ILUserBirthProfileRepository.swift` | Done | load/save/delete the single birth profile. |
| Data — Local | `Data/DataSources/Local/ILUserBirthProfileMO.swift`, `ILUserBirthProfileLocalDataSource.swift` | Done | Core Data row + mapping; `element` stored as `ILFiveElements` raw string. |
| Data — Repository | `Data/Repositories/ILUserBirthProfileRepositoryImpl.swift` | Done | Error translation into `ILUserBirthProfileError`. |
| Core Data model | `InnerLamp.xcdatamodeld` | Done | New `UserBirthProfile` entity (`solarBirthDate`, `lunarYear`, `canIndex`, `chiIndex`, `element`). |
| Wiring | `DIContainer` | Done | `makeAlmanacUseCase()`, `makeUserBirthProfileRepository()`, `userBirthProfileLocalDataSource`. |
| Tests | `ILAlmanacUseCaseTests`, `ILUserBirthProfileRepositoryTests`, `ILLunarCalendarTests` (extended) | Done | Engine + storage + calendar-helper coverage. |

## Data sources & conventions

- **Nạp Âm table** — the 30-element Wu Xing list (`napAmElements`) maps each 60-Jiazi pair
  (`sexagenary / 2`) to its element; `sexagenaryDayIndex` is reused as the generic 60-cycle index.
- **Wu Xing cycle** — `generates` = +1, `overcomes` = +2 (Kim → Mộc, Mộc → Thổ, Thổ → Thủy,
  Thủy → Hỏa, Hỏa → Kim), via `ILFiveElements.cycleIndex`.
- **Scoring** — base 50; Lục Xung `-40`, Tam Hợp `+25`, Nhị Hợp `+20`, Sinh nhập `+20`, Khắc xuất
  `-5`, Khắc nhập `-25`, Đồng hành `+10`, Hoàng đạo `+10` / Hắc đạo `-10`; clamped to 0–100.
  "Sinh xuất" (mệnh sinh ngày) is **neutral** — not listed in the spec, kept as 0.
- **28 Tú anchor** — `(JD + 9) % 28` (index 0 = Giác), same anchoring family as day Can-Chi
  (`(JD + 9) % 10`).

## Known gaps / verification needed

- **28 Tú anchor** follows the common Vietnamese convention but has not been cross-checked against an
  authoritative lịch vạn niên. Verify before shipping any "kiêng kỵ theo sao" copy.
- **No UI screen yet** — this is the engine + storage only. A future "Trạch Cát" screen would own a
  `ILAlmanacViewModel`/`ILAlmanacCoordinator` that reads the profile via the repository and calls
  `calculateDailyAlmanac` directly in its state mapping.
- **Tiếng Việt only** — the `almanac.*` and new `lunarCalendar.solarTerm/truc/star28` keys exist only
  in `vi.json`; other languages fall back to the key.
- **"Sinh xuất" neutral** — see Data sources above.

## Changelog

- 2026-09-27 — unified engine into `ILLunarCalendar.almanac(...)` (optional birth date → general vs
  personalized), moved `ILAuspiciousTier`/`ILFiveElements`/Nạp Âm/matcher/dispatcher into
  `ILLunarCalendar.swift`; `ILAlmanacUseCase` reduced to a thin wrapper; `UserBirthProfile` Core Data
  + repository, localization, tests.
