# Tasks — Article

Version: 2.0
Last updated: 2026-10-15
Status: in-progress — Phase 1 (built and still matching product v1.0) done; Phase 2–8 pending; Phase 2 blocked on the backend related-articles contract; Phase 6–7 blocked on the website domain (ADR-0004); empty-block and not-found copy blocked on ⚠️ product

> See `changelog.md` in this folder for the version history of this spec.

> Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flows.
> `[x]` = verified in the code on 2026-10-15 **and** matching this spec v2.0; work that exists but no
> longer matches product v1.0 is listed as a `[ ]` change task instead.

## Phase 1 — Built and kept (retroactive record)

- [x] Shared Data layer: `TopArticlesEndpoint`, `ArticlesPageEndpoint`, `ArticleDetailEndpoint` (public), `ILArticleSummaryDTO`, `ILArticleDetailDTO`, `ILArticleMapper` (date-only GMT date, only `http(s)` source link), `ILArticleRepository` + `ILArticleRepositoryImpl` (network-only), `ARTICLE_NOT_FOUND` → `ILCatalogError.notFound`
- [x] Home block: featured cards from `GET /v1/articles/top` in server order, skeleton while loading, failure does not fail Home, "Xem tất cả" (See all) → all articles, card → article page (criteria 1, 2)
- [x] Card image: thumbnail, else cover, else placeholder, via `ILRemoteImageView`; failure keeps the placeholder (criteria 4 image part, 5)
- [x] All articles: `ILArticlesCoordinator`, `ILArticlesViewController` (sticky header, `ILArticlesListView`), page 1 on load, header "{loaded} / {total} bài", load-more 120 pt from the end with an in-flight guard, append-only de-duplicated cards, "Đang tải thêm bài viết…" (Loading more articles…), later-page failure keeps cards and is retried on the next reach of the end, card → page, back (criteria 6, 7, 9, 11)
- [x] Article page shell: `ILArticleCoordinator` (leaf; back; source link → Safari), `ILArticleViewController` (sticky header band with category + read time, hero, title, author + initials, "{d} tháng {m} · {n} phút đọc", body paragraphs, quote, "Nguồn: …"), `ILArticleHeroImageView`, `ILArticleQuoteView`, `ILArticleNextArticleListView`, skeleton while loading, no previous content while loading (criteria 12, 15 except notice / Share / order of "Đọc tiếp", 18 source part)
- [x] "Đọc tiếp" tap switches the article in place, scrolls to the top, drops stale responses (criterion 23)
- [x] DI: `DIContainer.makeArticleRepository`, `makeArticle*`, `makeArticles*`; `ILHomeCoordinator.showArticle(_:)` / `showArticles()`
- [x] Unit tests written: `ILArticleViewModelTests`, `ILArticleUseCaseTests`, `ILArticleRepositoryTests`, `ILArticlesViewModelTests`, Home article tests (type-checked, not run; they test the old behavior and are rewritten in Phase 2–5)

## Phase 2 — "Đọc tiếp" from the related endpoint (blocked: backend article `tasks.md` Phase 7 + `openapi.yaml`)

- [ ] Confirm `GET /v1/articles/{id}/related` (`articlesRelated`) is in innerlamp-be `docs/specs/api/openapi.yaml`; update the `Contract:` line of `requirements.md` and drop the "planned" notes of `design.md`
- [ ] `RelatedArticlesEndpoint` (public) + `ILArticleRepository.loadRelatedArticles(id:)` in `ILArticleRepositoryImpl`, decoding `ILCatalogTopListDTO<ILArticleSummaryDTO>`
- [ ] `ILArticleUseCase.loadRelatedArticles(id:)` (failure → `[]`); delete `loadNextArticles(excluding:)` and `nextArticleCount` (design Step 2)
- [ ] `ILArticleViewModel`: related loaded after the article, stale responses dropped; heading and list hidden when empty or failed (criteria 21, 22)
- [ ] Tests: `ILArticleRepositoryTests` (path, decoding, 404 → `.notFound`), `ILArticleUseCaseTests` (failure → `[]`), `ILArticleViewModelTests` (0 / 1 / 2 items, failure hides the section, stale response dropped)

## Phase 3 — Article page alignment (FR-ART-003, FR-ART-004, BR-ART-05…09)

- [ ] Remove Save: `toggleSave`, `ILArticleEntity.savedArticleIDs`, `isSaved` / `saveButtonTitle`, `saveTapped` input, `saveButton`, `article.save` / `article.saved` keys; "Chia sẻ" (Share) alone in the action row (criterion 20, BR-ART-09)
- [ ] Detail data: optional `thumbnailUrl` on `ILArticleDetailDTO`; map `thumbnailURL`, `summary`, `language` into `ILArticleItemEntity`
- [ ] Hero image = cover ?? thumbnail ?? placeholder (criterion 16, BR-ART-05)
- [ ] Summary notice under the source line, always shown; source line hidden when the source name is empty (criterion 18, BR-ART-06); add `article.summaryNotice`
- [ ] Missing values: author line, quote block, category label hidden when empty; no body → summary + "Bài viết chưa có nội dung chi tiết." (This article has no detailed content yet.; `article.noBody`) (criterion 17, BR-ART-07)
- [ ] Article language on title, body, summary and quote labels (`accessibilityLanguage`, `.languageIdentifier` attribute) (criterion 19, BR-ART-08)
- [ ] Not-found state for `ILCatalogError.notFound`: message + back, no content, no "Chia sẻ" (criterion 13) — copy blocked on ⚠️ (product)
- [ ] Empty block for other failures, replacing the `showError` toast (criterion 14) — copy and retry blocked on ⚠️ (product A3)
- [ ] Remove the dead mock strings `article.article.*` from `vi.json`
- [ ] `ILArticleViewModelTests`: section visibility for missing values, notice, no-body text, hero order, language passed through, not-found vs empty block, no Save in the state

## Phase 4 — All articles alignment (FR-ART-002, FR-ART-008)

- [ ] `ILArticlesViewModel` / `ILArticlesStateModel`: a `loadedOnce` (or equivalent) flag so the footer shows the end line only after a loaded last page (today `hasMore == false` before and after a failed first page shows "Bạn đã xem hết bài viết") (criterion 8)
- [ ] First-page failure or `total` 0 → empty block in place of the list, no count; replaces the `showError` toast (criterion 10) — copy and retry blocked on ⚠️ (product A3)
- [ ] Later-page failure: no toast; loading line removed; retried on the next reach of the end (criterion 9)
- [ ] `ILArticlesViewModelTests`: end line only after the last page, empty block on first-page failure and on `total` 0, later-page failure keeps cards and retries

## Phase 5 — Home block and card (FR-ART-001, FR-ART-008, BR-ART-07)

- [ ] `ILArticleCardView`: meta line without " · " when the author is empty; category label hidden when empty (criterion 4)
- [ ] Home block empty block for "no article" and "failed" (criterion 3) — copy and retry blocked on ⚠️ (product A3); remove the mock `home.article.N.*` keys
- [ ] `ILHomeViewModelTests`: empty block on failure and on no item, no sample cards

## Phase 6 — Share with the website link (FR-ART-006, ADR-0004)

- [ ] `APIConfig.webBaseURL` per environment — blocked on ⚠️ web domain (product Appendix A item 2)
- [ ] `Core/Links/ILWebLink.swift`: `articleURL(id:)` (unprefixed `/articles/<id>`, id percent-encoded)
- [ ] `ILArticleUseCase.shareContent(for:)` → title + link; `ILArticleNavEvent.share(title:url:)`; `ILArticleCoordinator` presents `UIActivityViewController` (replaces the TODO); "Chia sẻ" hidden unless an article is loaded (criterion 24)
- [ ] Tests: `ILWebLinkTests` (URL shape, encoding), `ILArticleViewModelTests` (share event carries title + link)

## Phase 7 — Open shared links by Universal Links (FR-ART-007, ADR-0004)

- [ ] Associated Domains: `applinks:<web-domain>` in `InnerLamp.entitlements` per environment and the capability on App ID `weedigital.vn.InnerLamp` — blocked on ⚠️ web domain and ⚠️ build-to-environment mapping
- [ ] `ILWebLink.route(for:)`: environment host only; `/articles/<id>` and `/en/articles/<id>` → `.article(id:)`; anything else → `nil` (criteria 25, 26)
- [ ] `SceneDelegate`: handle `NSUserActivityTypeBrowsingWeb` in `scene(_:continue:)` and in `connectionOptions.userActivities` on cold start; `nil` route → `UIApplication.shared.open(url)` (criteria 25, 26)
- [ ] `AppCoordinator.open(route:)` → `ILMainTabCoordinator` selects Home → `ILHomeCoordinator.showArticle(id)`; behavior during splash / onboarding / login — blocked on ⚠️ (criterion 25 marker)
- [ ] Unknown id from a link → not-found state (criterion 27; reuses Phase 3)
- [ ] Tests: `ILWebLinkTests` (accepted paths, `/en/` form, foreign host, unknown path, empty id)
- [ ] Manual QA on a device once the website serves `apple-app-site-association` (needs the Team ID, ⚠️): link in Messages / Notes opens the page with the app installed (warm and cold), the website without it, an unknown id shows not found

## Phase 8 — Verification and documentation

- [ ] Build (`xcodebuild build`, `generic/platform=iOS`) and test run (physical device per AGENTS.md); record the result here
- [ ] Manual QA on device against the prototype screens (home §11, "Tất cả bài viết", "Bài viết Phật pháp"): scroll and paging to the end line, no connection on each surface, a missing date / quote, source link, dark mode
- [ ] `InnerLamp/Presentation/Scenes/Article/README.md` and `Articles/README.md`: status tables + changelog for these changes, and a pointer to `Docs/Specs/Article/` (both still describe Save and the client-side "Đọc tiếp")
- [ ] Separate change (not this one): delete `Docs/Specs/Articles/` and update the OKF `home.md` concept that still cites it
- [ ] `Docs/Knowledge/features/article.md` (OKF) — with `okf-writer` after Phase 2–7 are verified on device

## Deferred (separate features, not blocking Article)

- Share-verse screen "Chia sẻ câu kinh" (Share a verse) — `Docs/Specs/Share/`, out of scope (product §1.2).
- Website `apple-app-site-association` — website repo (ADR-0004 follow-up).
- Related-articles endpoint — backend article `tasks.md` Phase 7.
