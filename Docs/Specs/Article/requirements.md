# Requirements — Article

Version: 2.0
Last updated: 2026-10-15
Status: in-progress — Home block, "All articles" list and article page read the articles API (built 2026-09-30…10-07, build-verified, tests type-checked but not run); product spec v1.0 alignment pending: Save removed, summary notice, page image order (cover → thumbnail), missing values left out, article language declared, empty block instead of an error toast, not-found state, "Đọc tiếp" (read next) from the related-articles API (planned backend contract, not yet in `openapi.yaml`), Share with the website link and opening shared links by Universal Links (both blocked on the website domain, ADR-0004) — `tasks.md` Phase 2–8
Feature folders: `InnerLamp/Presentation/Scenes/Article/` (article page), `InnerLamp/Presentation/Scenes/Articles/` (all articles), the article block of `InnerLamp/Presentation/Scenes/Home/`
Product spec: innerlamp-be `docs/product/article/product.md` @ v1.0
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ a8a016b (info.version 1.0.0) — tag Articles: `GET /v1/articles/top` (`articlesTop`), `GET /v1/articles` (`articlesList`), `GET /v1/articles/{id}` (`articlesGet`). Planned: `GET /v1/articles/{id}/related` (`articlesRelated`, `{items: [ArticleSummary]}`, 0–2 items, `404 ARTICLE_NOT_FOUND`) per innerlamp-be backend article `docs/specs/features/article/requirements.md` + `design.md` v3.0 (AC 20–25) — designed, not built, not yet in `openapi.yaml` (backend `tasks.md` Phase 7).
Architecture: ADR-0004 (shared links are website URLs opened by the apps) — Accepted
Implements: BR-ART-01, BR-ART-02, BR-ART-03, BR-ART-04, BR-ART-05, BR-ART-06, BR-ART-07, BR-ART-08, BR-ART-09, FR-ART-001, FR-ART-002, FR-ART-003, FR-ART-004, FR-ART-005, FR-ART-006, FR-ART-007, FR-ART-008, NFR-ART-01, NFR-ART-02
Not on iOS: FR-ART-009 (Backend only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the Dharma articles ("Bài viết Phật pháp hay" — good Dharma articles).
As product §1.5 asks, this one folder merges the former `Docs/Specs/Article/` v1.3 (article page) and
`Docs/Specs/Articles/` v1.1 (all articles); the code folders keep their names. `Docs/Specs/Articles/`
is kept until a separate clean-up change removes it (`tasks.md` Phase 8). Product behavior — editorial
order, featured list, page size, related-article choice, image order, source and summary notice,
missing values, language, no Save — lives in the product spec and is **not** restated here; this file
only says how the iOS app implements those `BR-ART-*` / `FR-ART-*`. Written retroactively from the
built screens and prospectively for the product v1.0 changes.

> Layout source: the design prototype (product §1.5), home §11 "Bài viết Phật pháp hay", screens
> "Tất cả bài viết" (All articles) and "Bài viết Phật pháp" (Dharma article). Copy source: product
> §3.1.1 and the criteria of §3.2 / §3.3; the prototype's copy where those are silent. Where the
> prototype and the product spec differ (page size 20, Save button, "2 bài kế" (next 2 articles)),
> the product spec wins.

## User Story

As a visitor (signed in or not), I want to read curated Dharma articles on my iPhone — the featured
ones on Home, all of them page by page, each with suggestions of what to read next — and share one
with a link that opens InnerLamp, so that I can learn and pass good teachings on.

## Constraints from the product spec

- **The server orders, pages and picks** (BR-ART-01, BR-ART-02, BR-ART-03, BR-ART-04): the app shows
  articles in the order received and never sorts, filters or picks related articles itself. The
  vectors `rules/article-order.json` and `rules/article-related.json` are backend-only (product §4.1;
  both rules "Applies to: Backend").
- **Apps load the next page at the end of the list**, with the header "{loaded} / {total} bài"
  ({loaded} / {total} articles) and the end line (§3.6 row FR-ART-002).
- **Featured cards** (§3.6 row FR-ART-001 / BR-ART-02): the iOS Home block shows every featured
  article received (5 today).
- **Vietnamese interface only** (§3.6 row BR-ART-08): no English interface strings in this version;
  the article text itself is shown in its own language.
- **Online only** (product §2.4, §3.7): no offline or cached copy of any article — unlike Deity /
  Temple, nothing is stored on the device.
- **Shared links** follow ADR-0004: `https://<web-domain>/articles/<id>`, opened by Universal Links
  with a per-app path allow-list and the website page as fallback.

## Acceptance Criteria (EARS notation)

### Home block "Bài viết Phật pháp hay"

1. WHEN Home loads, THE SYSTEM SHALL request `GET /v1/articles/top` without signing in and show every returned article as a card in the order received. (FR-ART-001, BR-ART-01, BR-ART-02)
2. WHEN the user taps "Xem tất cả" (See all) on the block, THE SYSTEM SHALL open all articles; WHEN the user taps a card, THE SYSTEM SHALL open that article's page. (FR-ART-001, FR-ART-003)
3. WHEN `top` returns no article or fails, THE SYSTEM SHALL show the block's empty block and no article card, SHALL NOT show sample or previously loaded articles, and SHALL NOT fail the Home screen. (FR-ART-008, BR-ART-02)
   > ⚠️ Not confirmed (product): whether the empty block offers "Thử lại" (Retry) and which text it shows (product Appendix A item 3) — blocks the empty-block copy and action in `tasks.md` Phase 5 (Home keeps today's "Đang cập nhật" (Updating) text until answered); hand back to ba-writer in innerlamp-be.

### Article card (Home block and all articles)

4. WHEN an article card is shown, THE SYSTEM SHALL show the image (the summary's thumbnail, else its cover, else the placeholder), the category, the title on at most 2 lines, and "{author} · {n} phút đọc" ({author} · {n} min read); a missing category or author is left out (no empty label, no leading " · "). (BR-ART-05, BR-ART-07, NFR-ART-02)
5. WHEN a card image fails to load, THE SYSTEM SHALL keep the placeholder and show no error. (BR-ART-05)

### All articles ("Bài viết Phật pháp hay")

6. WHEN all articles opens, THE SYSTEM SHALL request `GET /v1/articles?page=1`, show its articles in the order received and show the header "{loaded} / {total} bài" with `total` from the response. (FR-ART-002, BR-ART-03)
7. WHEN the user scrolls near the end of the loaded cards and the last response says more pages exist, THE SYSTEM SHALL request the next page, show "Đang tải thêm bài viết…" (Loading more articles…) while it loads and append only cards not shown yet (by `id`); THE SYSTEM SHALL never have two page requests in flight. (FR-ART-002, NFR-ART-01, platform)
8. WHEN the last page has been loaded (`page >= total_pages`) or a page comes back empty, THE SYSTEM SHALL request no further page and end the list with "Bạn đã xem hết bài viết" (You have seen every article); the end line SHALL NOT appear before the first page has loaded or after a failed first page. (FR-ART-002, BR-ART-03)
9. WHEN a later page fails, THE SYSTEM SHALL keep the cards already shown, remove the loading line, and request that page again the next time the user reaches the end of the list. (FR-ART-002)
10. WHEN the first page cannot be loaded, or `total` is 0, THE SYSTEM SHALL show the empty block in place of the list, with no article card, no count and no end line, and SHALL NOT show sample articles. (FR-ART-008, BR-ART-03)
    > ⚠️ Not confirmed (product): retry action and text of the empty block (product Appendix A item 3) — same question as criterion 3; blocks the copy and action in `tasks.md` Phase 4; hand back to ba-writer in innerlamp-be.
11. WHEN the user taps a card, THE SYSTEM SHALL open that article's page; WHEN the user taps back, THE SYSTEM SHALL close all articles. (FR-ART-003, platform)

### Article page ("Bài viết Phật pháp")

12. WHEN the article page opens for an id (from Home, all articles, "Đọc tiếp" or a shared link), THE SYSTEM SHALL request `GET /v1/articles/{id}` without signing in and show the loading skeleton until it answers, never the content of another article. (FR-ART-003)
13. WHEN the response is `404 ARTICLE_NOT_FOUND`, THE SYSTEM SHALL show a not-found state with the back control and no article content. (FR-ART-003, FR-ART-007)
    > ⚠️ Not confirmed (product): the text of the article not-found state (FR-ART-003 says only "says it was not found and offers a way back"; product §3.1.1 gives no copy) — blocks the not-found copy in `tasks.md` Phase 3; hand back to ba-writer in innerlamp-be.
14. WHEN loading fails otherwise (no connection, server unreachable, `500`), THE SYSTEM SHALL show the empty block in place of the page, with the back control, and no article content. (FR-ART-008)
    > ⚠️ Not confirmed (product): retry action and text of the empty block (product Appendix A item 3) — blocks the copy and action in `tasks.md` Phase 3; hand back to ba-writer in innerlamp-be.
15. WHEN the page is shown, THE SYSTEM SHALL show, in the order of FR-ART-004: the category and "{n} phút đọc" (in the sticky header band); the cover image; the title; the author with initials and the date "{d} tháng {m}" ({d} month {m}); the body paragraphs as plain text; the quote with its source; the source line and the summary notice; the "Chia sẻ" (Share) action; "Đọc tiếp". (FR-ART-004)
16. WHEN the page image is shown, THE SYSTEM SHALL use the cover, else the thumbnail, else the placeholder; WHEN the image fails to load, THE SYSTEM SHALL keep the placeholder, show no error and still show the text. (BR-ART-05)
17. WHEN a value is missing, THE SYSTEM SHALL leave it out as BR-ART-07 says (no date → date-free meta line; no author → no author line; no quote → no quote block; no category → no category label); WHEN the article has no body paragraph, THE SYSTEM SHALL show its summary followed by "Bài viết chưa có nội dung chi tiết." (This article has no detailed content yet.). (BR-ART-07)
18. WHEN the page is shown, THE SYSTEM SHALL show "Nguồn: {source name}" (Source: {source name}) — tappable and opening the original page in Safari only when the source link is an `http`/`https` URL, plain text otherwise — and below it the notice "Đây là bản tóm tắt. Vui lòng đọc bài gốc để có đầy đủ nội dung." (This is a summary. Please read the original for the full content.). (BR-ART-06, BR-ART-07)
19. WHEN the page is shown, THE SYSTEM SHALL mark the title, body, summary and quote text with the article's `language` so VoiceOver and hyphenation use it; interface text (header, actions, states) stays Vietnamese. (BR-ART-08)
20. THE SYSTEM SHALL show no "Lưu bài" (Save article) / "Đã lưu" (Saved) action and no saved-articles list. (BR-ART-09)

### "Đọc tiếp" (FR-ART-005)

21. WHEN the article has loaded, THE SYSTEM SHALL request `GET /v1/articles/{id}/related` and show the returned articles (0–2) under "Đọc tiếp" as cards in the order received. (FR-ART-005, BR-ART-04)
22. WHEN the related request returns no article or fails (including `404`), THE SYSTEM SHALL hide the "Đọc tiếp" heading and list and leave the rest of the page unchanged. (FR-ART-005)
23. WHEN the user taps a card under "Đọc tiếp", THE SYSTEM SHALL show that article on the same screen scrolled to its top, run criteria 12–22 for it, and drop any response that belongs to the article shown before. (FR-ART-005, platform)

### Share (FR-ART-006)

24. WHEN the user taps "Chia sẻ" on a loaded article, THE SYSTEM SHALL open the system share sheet with the article's title and its website link `https://<web-domain>/articles/<id>` (the unprefixed form, ADR-0004); "Chia sẻ" is not shown while the article is loading, not found or failed. (FR-ART-006, platform)
    > ⚠️ Not confirmed: the website domain per environment (product Appendix A item 2, ADR-0004 open question) — blocks the exact link in `tasks.md` Phase 6.

### Open a shared link (FR-ART-007)

25. WHEN the system opens the app with a Universal Link whose path is `/articles/<id>` or `/en/articles/<id>` on the environment's website domain — app running, in the background or not started — THE SYSTEM SHALL open the article page for `<id>` (criteria 12–24). (FR-ART-007, ADR-0004)
    > ⚠️ Not confirmed: where the article page opens when a link arrives while the app shows splash, onboarding, sign-up or login (no main tab yet) — push it once the main tab is shown, or present it over the auth flow — blocks the routing task in `tasks.md` Phase 7 (iOS decision, ask the product owner).
26. WHEN the app receives a Universal Link for a path it does not route, THE SYSTEM SHALL open that URL in Safari and change nothing in the app. (ADR-0004, platform)
27. WHEN a shared link names an article that does not exist, THE SYSTEM SHALL show the not-found state of criterion 13, never a different article. (FR-ART-007, FR-ART-003)

## Error → UI mapping

Operations are cited, not copied; the contract is innerlamp-be `docs/specs/api/openapi.yaml` (tag
Articles) plus the planned `articlesRelated` of backend article requirements v3.0 AC 20–25. There is
no cached copy in any case.

| Operation | Failure case | What the user sees |
|---|---|---|
| `GET /v1/articles/top` | any failure, or `items` empty | Home block empty block; the rest of Home loads (criterion 3) |
| `GET /v1/articles` page 1 | any failure, or `total` 0 | empty block in place of the list, no count, no end line (criterion 10) |
| `GET /v1/articles` page > 1 | any failure | cards kept, loading line removed, page retried on the next reach of the end (criterion 9) |
| `GET /v1/articles` | `400 INVALID_PAGE` | same as the other failures (the app never sends such a page — a bug, logged, not a user error) |
| `GET /v1/articles/{id}` | `404 ARTICLE_NOT_FOUND` | not-found state with back (criteria 13, 27) |
| `GET /v1/articles/{id}` | offline / unreachable / `500` / other | empty block with back (criterion 14) |
| `GET /v1/articles/{id}/related` (planned) | any failure incl. `404`, or `items` empty | no "Đọc tiếp" section; the article stays (criterion 22) |
| image URL (cover / thumbnail) | any failure | placeholder, no message (criteria 5, 16) |

## Out of scope (this feature boundary, not backend work)

- Save / bookmark and a saved-articles screen (BR-ART-09, product §1.2).
- Search, category filter, reading progress, font size, text to speech, offline reading (product §1.2).
- The share-verse screen "Chia sẻ câu kinh" (Share a verse; `Docs/Specs/Share/`) — Share here uses the
  system share sheet with a link (product §1.2).
- Deferred deep links, short links and link analytics (ADR-0004).
- Serving `/.well-known/apple-app-site-association` — the website's job (ADR-0004); this spec only
  needs it to exist and to list the iOS app and its paths.
- Writing or loading article content (FR-ART-009, backend only).

## Pending (not yet implemented — see `tasks.md`)

- Remove the Save button, its state and the dead mock strings (`tasks.md` Phase 3).
- Article page: summary notice, image order cover → thumbnail, missing values left out, no-body text,
  article language, not-found state, empty block instead of the error toast (`tasks.md` Phase 3).
- All articles: empty block instead of the error toast; no end line before or without a first page
  (`tasks.md` Phase 4).
- Cards: no leading " · " when the author is missing (`tasks.md` Phase 5).
- "Đọc tiếp" from the related-articles API instead of the first two featured articles (`tasks.md`
  Phase 2).

  > ⚠️ Not confirmed: when the backend ships `GET /v1/articles/{id}/related` and adds it to `openapi.yaml` (backend article `tasks.md` Phase 7, not started) — blocks `tasks.md` Phase 2. Until then the page keeps today's "first 2 featured" suggestions (drift, product §4.2 BR-ART-04 / FR-ART-005).

- Share with the website link (`tasks.md` Phase 6) and opening shared links (`tasks.md` Phase 7).

  > ⚠️ Not confirmed: the website domain for dev / staging / prod (product Appendix A item 2, ADR-0004) — blocks the link built by Share and the `applinks:` entitlement.

  > ⚠️ Not confirmed: the Apple Team ID of `weedigital.vn.InnerLamp` (ADR-0004 open question) — blocks the content of the website's association file and so the end-to-end check of criterion 25; the iOS code does not need it.

  > ⚠️ Not confirmed: how iOS builds map to the dev / staging / prod environments (today `APIConfig.current` is a code constant and the project has only Debug / Release configurations) — blocks one `applinks:` domain per environment (ADR-0004 convention 5) in `tasks.md` Phase 7.

- Content and image rights (product Appendix A item 1) are still open — they block public release of
  the content, not this spec.

## Open questions (resolved)

- ~~What is the articles API contract?~~ → Three public operations in `openapi.yaml` (tag Articles);
  the old local contract table of v1.1–v1.3 is dropped and the spec cites `openapi.yaml` instead.
  Resolved 2026-09-30, re-cited 2026-10-15.
- ~~Is the author's initials derivable from the name?~~ → No, `author_initials` is editorial data.
  Resolved 2026-09-30.
- ~~Pagination style?~~ → Server pages of 10, 1-based, `total` / `total_pages`, a page past the end is
  empty (BR-ART-03). Resolved 2026-09-30, confirmed by product v1.0 (Q6: keep 10, drop the
  prototype's 20).
- ~~Will the backend add related articles, or does the app derive "Đọc tiếp" from `top`?~~ → The
  backend picks up to 2 related articles (BR-ART-04, `GET /v1/articles/{id}/related`, planned).
  Resolved 2026-10-15 (product v1.0 Q7).
- ~~Keep the in-memory Save?~~ → No Save action in this version (BR-ART-09). Resolved 2026-10-15.
- ~~What does Share do — the share-verse screen?~~ → System share sheet with the title and the
  website link, opened in the app by Universal Links (FR-ART-006, FR-ART-007, ADR-0004). Resolved
  2026-10-15.
- ~~What does the page show when it cannot load — an error toast?~~ → An empty block, never sample or
  cached content (FR-ART-008); retry and text still open (criterion 14 marker). Resolved 2026-10-15.
- ~~Interface languages on iOS?~~ → Vietnamese only in this version (§3.6 row BR-ART-08). Resolved
  2026-10-15.
