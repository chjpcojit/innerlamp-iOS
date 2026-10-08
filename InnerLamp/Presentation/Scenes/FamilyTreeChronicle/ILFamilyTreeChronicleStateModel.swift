//
//  ILFamilyTreeChronicleStateModel.swift
//  InnerLamp
//

import Foundation

/// One tab of the book switcher ("Họ Nguyễn Hữu · nội" / "Họ Trần · ngoại").
struct ILFamilyTreeChronicleTabModel: Equatable {
    let treeID: String
    let title: String
    let isSelected: Bool
}

/// One dated line of the history timeline (view mode).
struct ILFamilyTreeChronicleTimelineRow: Equatable {
    let id: String
    let year: String
    let text: String
    /// A line continues down to the next row.
    let hasNext: Bool
}

/// "Người tiêu biểu" row.
struct ILFamilyTreeChroniclePersonRow: Equatable {
    let memberID: String
    let name: String
    let subtitle: String
    let generation: String
}

/// One candidate in the "Chọn tộc trưởng mới" sheet.
struct ILFamilyTreeChronicleCandidateRow: Equatable {
    let memberID: String
    let name: String
    let subtitle: String
    let isCurrent: Bool
}

/// The "Chuyển tộc trưởng?" confirmation, shown as a dialog by the ViewController.
struct ILFamilyTreeChroniclePendingHead: Equatable {
    let memberID: String
    let message: String
}

/// UI state of the "Phả ký" screen — owned by `ILFamilyTreeChronicleViewModel`, read-only for the
/// ViewController. View mode reads the resolved texts below; edit mode reads `draft` (raw input,
/// may be invalid mid-edit). No UIKit import, no business logic.
struct ILFamilyTreeChronicleStateModel: Equatable {
    var tabs: [ILFamilyTreeChronicleTabModel] = []
    var isEditing = false

    // Header
    var title = ""
    var home = ""
    var meta = ""

    // NGUỒN GỐC
    var founderMemberID: String?
    var founderName = ""
    var founderYears = ""
    var origin = ""

    // MỐC LỊCH SỬ
    var timeline: [ILFamilyTreeChronicleTimelineRow] = []

    // NHÀ THỜ HỌ
    var shrineName = ""
    var shrineAddress = ""
    var keeperMemberID: String?
    var keeperName = ""
    var founderAnniversary = ""
    var annualGathering = ""
    /// The founder has a known anniversary, so "Nhắc giỗ tổ hằng năm" can be offered.
    var canRemindFounder = false

    // GIA HUẤN
    var plaqueHan = ""
    var plaqueMeaning = ""
    var couplets: [String] = []
    var teachings = ""

    // NGƯỜI TIÊU BIỂU
    var people: [ILFamilyTreeChroniclePersonRow] = []

    // Edit mode
    var draft = ILFamilyTreeChronicleDraft()
    var errorField: ILFamilyTreeChronicleField?
    var errorMessage: String?
    var isSaving = false

    // Clan-head change
    var isHeadPickerOpen = false
    var candidates: [ILFamilyTreeChronicleCandidateRow] = []
    var pendingHead: ILFamilyTreeChroniclePendingHead?

    /// "Đã lưu phả ký …" confirmation; `toastToken` changes on every new one so the same text can
    /// be shown twice.
    var toastMessage: String?
    var toastToken = 0

    func error(for field: ILFamilyTreeChronicleField) -> String? {
        errorField == field ? errorMessage : nil
    }
}
