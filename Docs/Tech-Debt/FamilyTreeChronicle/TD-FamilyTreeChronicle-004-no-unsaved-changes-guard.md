---
id: TD-FamilyTreeChronicle-004
title: No unsaved-changes guard when leaving edit mode
title_vi: Chưa cảnh báo thay đổi chưa lưu khi rời chế độ sửa
feature: FamilyTreeChronicle
level: Low
status: Open
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTreeChronicle/ILFamilyTreeChronicleViewModel.swift
---

## Description / Mô tả
EN: Switching book tab while editing drops the draft silently, and the back button leaves without asking. The prototype behaves the same.
VI: Đổi tab gia phả khi đang sửa sẽ bỏ bản nháp mà không báo, nút quay lại cũng thoát không hỏi. Prototype cũng hành xử như vậy.

## Why it was taken on / Lý do chấp nhận nợ
EN: Kept the prototype's behavior; no confirmed requirement for a discard prompt.
VI: Giữ hành vi của prototype; chưa có yêu cầu xác nhận về hộp thoại hủy thay đổi.

## Impact / Ảnh hưởng
EN: A user can lose a long text typed into Phả ký by mistake.
VI: Người dùng có thể mất đoạn văn dài đã gõ trong Phả ký do nhầm thao tác.

## Proposed fix / Hướng xử lý
EN: Add a discard confirmation (ILAlert.dialog) when the draft differs from the saved chronicle.
VI: Thêm hộp thoại xác nhận bỏ thay đổi (ILAlert.dialog) khi bản nháp khác phả ký đã lưu.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
