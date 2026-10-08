# Changelog — LunarCalendar Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.1 (2026-09-30)

- `requirements.md`: resolved the ⚠️ day-30 / 29-day-month question. Added
  short-month and leap-month rules. Last day of a 29-day month is a fast day;
  Buddhist event templates on day 30 fire on day 29 of a short month.
- Code: `ILLunarCalendar.isLastDayOfShortMonth` / `matchesLunarDay` shared by
  `ILLunarCalendarUseCase`, `ILBuddhistEventUseCase` and `ILDeityUseCase`.
- Added `assumptions.md` (A1-A3).

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented LunarCalendar
  feature (6-month lunar calendar carousel with pure local computation, no API).
- `requirements.md`: user story and 6 EARS acceptance criteria (load 6-month
  carousel, change month + header, select day + update card + upcoming, upcoming
  rows, close, today highlight). "Pending" records the provisional day-card
  copy (with a ⚠️ on the content source) and the fast-day-only upcoming rows,
  plus a ⚠️ on the 29-day-month fast-day convention. One resolved open question
  (lunar conversion is real via `ILLunarCalendar`, not hardcoded).
- `design.md`: Layers & components table (Entity + day/month/category, UseCase,
  StateModel, ViewModel, leaf Coordinator, ViewController, 4 feature views,
  shared `ILChevronCircleButton`, core `ILLunarCalendar`), navigation flow, data
  flow, and a "Deliberately provisional" section. No Step-by-step Flow — no
  network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 10
  + 9 tests; Phase 3 "not applicable"; Phase 4 leaves the content/reminder
  extras as `[ ]`.
- Reason: LunarCalendar was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
