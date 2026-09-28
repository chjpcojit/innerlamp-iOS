# Requirements — Paywall

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; StoreKit products & entitlement unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Paywall/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner, I want to see and choose a Sen Vàng (Golden Lotus)
subscription, so that I can unlock the full library and offline downloads.

## Acceptance Criteria (EARS notation)

- WHEN the Paywall screen loads, THE SYSTEM SHALL show the dark backdrop, the
  title ("Mở trọn thư viện pháp bảo"), and four benefits (kinh song ngữ có
  phiên âm, khóa thiền 8 tuần, tải về nghe không mạng, nhật ký không giới hạn).
- WHEN the screen renders the plans, THE SYSTEM SHALL show three plans with
  radio selection: Tháng 79.000₫, Năm 589.000₫ (49.000₫/tháng, "TIẾT KIỆM 38%"),
  Trọn đời 1.890.000₫ — defaulting to the Năm plan.
- WHEN the user selects a plan, THE SYSTEM SHALL update the CTA and note to
  match: Tháng/Năm → "Dùng thử 7 ngày miễn phí" + the post-trial price; Trọn đời
  → "Thỉnh gói trọn đời" + "Thanh toán một lần".
- WHEN the user taps the CTA, THE SYSTEM SHALL start the purchase flow (StoreKit)
  and navigate to a receipt/confirmation on success.
- WHEN the user taps "Để sau, tôi dùng bản miễn phí", THE SYSTEM SHALL dismiss
  the Paywall.

## Out of scope (this feature boundary, not backend work)

- The Profile "Sen Vàng" banner that opens this screen — owned by the Profile
  feature.
- Entitlement enforcement (gating content behind the plan) — a shared concern;
  this feature only presents and purchases the plans.
- The Receipt screen (if shared with Offering) — see `Docs/Specs/Offering/`.

## Pending (not yet implemented — see `tasks.md`)

- StoreKit products and entitlement.

  > ⚠️ Not confirmed: the exact StoreKit product identifiers, price points, the
  > trial eligibility, and how entitlement is stored/verified — blocks
  > `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->
