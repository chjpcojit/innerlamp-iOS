# Changelog — TempleFinder Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial) — 2026-10-05

- Initial spec written alongside the implementation of the "Chọn chùa tu tập" screen (prototype `findtp`,
  pick mode), reached from the Chùa tab's "Đổi chùa", including the "Đề xuất thêm chùa" form.
- Decisions taken with the user: new standalone page (not the inline chooser); the proposal form is UI only
  (no storage / no API); minimal form fields (name, address, province, optional phone — as in the prototype).
- Deviation from the prototype: the proposal is not selected as the practice temple (nothing stored) — see
  AS-TempleFinder-001.
