# Requirements — FestivalDetail

Version: 1.0
Last updated: 2026-10-11
Status: implemented (app builds); unit tests written, not runnable in this environment; device QA pending
Feature folder: `InnerLamp/Presentation/Scenes/FestivalDetail/`

> See `changelog.md` in this folder for the version history of this spec.

> Written alongside the first implementation (light-weight full lane: no separate SRS was produced).
> Design source: prototype screen `festDetail` ("Chi tiết ngày lễ") in `Docs/innerlamp-project/`.

## User Story

As a practitioner, I want to open one Buddhist festival day from Home or from the festival
calendar so that I can read what it is about, when it falls (solar + lunar), how far away it is,
and what Buddhists usually do on that day.

## Acceptance Criteria (EARS notation)

- WHEN the user taps an event in the Home "Sự kiện Phật giáo" carousel, THE SYSTEM SHALL open
  FestivalDetail for that event and that solar date.
- WHEN the user taps a named festival day (not a Rằm / Mùng Một observance) in "Lịch lễ Phật
  giáo", THE SYSTEM SHALL open FestivalDetail for that event and that solar date.
- WHEN the user taps a Rằm / Mùng Một observance day in "Lịch lễ Phật giáo", THE SYSTEM SHALL do
  nothing (observance days have no server event, hence no detail).
- WHEN FestivalDetail loads, THE SYSTEM SHALL request `GET /v1/calendar/events?year=<year of the
  date>`, show a loading state, and then render the event matching the code and the occurrence on
  the date.
- WHEN rendering, THE SYSTEM SHALL show: picture, group label(s), event name, lunar date
  ("Ngày D · Tháng M âm lịch", with "(nhuận)" for a leap month), the description paragraphs, a
  solar date card (day, weekday + month/year, "Dương lịch năm YYYY") with a countdown pill
  (Hôm nay / Ngày mai / Còn N ngày / Đã qua), "Phật tử thường làm gì" as numbered rows,
  "Kinh nên tụng" and "Chùa tổ chức".
- WHEN the server has no data for a section (no image, no group, no description, no guidance), THE
  SYSTEM SHALL still show that section with a "Chưa có …" text instead of hiding it.
- WHILE "Kinh nên tụng" and "Chùa tổ chức" have no data source, THE SYSTEM SHALL always show their
  "Chưa có thông tin" / "Chưa có chùa nào tổ chức" text.
- WHEN the event or the occurrence on that date is missing from the response, THE SYSTEM SHALL
  show the error state ("not found" message) with a retry button.
- IF the request fails, THEN THE SYSTEM SHALL show an error state (offline gets its own title)
  with a "Thử lại" button that loads again.
- WHEN the user taps back, THE SYSTEM SHALL pop the screen.

## Out of scope

- The "Nhắc tôi ngày này" reminder button (deferred by the product owner — TD-FestivalDetail-002).
- Real "Kinh nên tụng" and "Chùa tổ chức" content (no API — TD-FestivalDetail-001).
- An alternative (second) title line.

## Pending / ⚠️ Not confirmed

- ⚠️ Not confirmed: the format of `guidance` and `long_description` from the server — assumed one
  item/paragraph per line (AS-FestivalDetail-001).
- ⚠️ Not confirmed: the "kind" eyebrow (prototype: "Lễ lớn", "Vía Bồ Tát"…) — the server only has
  group names, which are shown instead (AS-FestivalDetail-002).
