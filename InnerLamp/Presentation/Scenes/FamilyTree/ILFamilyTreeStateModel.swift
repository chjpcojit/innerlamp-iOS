//
//  ILFamilyTreeStateModel.swift
//  InnerLamp
//

import Foundation
import CoreGraphics

/// What a hexagon medallion looks like — shared by the canvas nodes and the detail sheet header.
struct ILFamilyTreeMedallionLook: Equatable {
    let gender: ILFamilyGender
    let isLiving: Bool
    let isFounder: Bool
    let isClanHead: Bool
}

struct ILFamilyTreeNodeModel: Equatable {
    let id: String
    let center: CGPoint
    let width: CGFloat
    let name: String
    /// "ĐỜI 5", "TỘC TRƯỞNG · ĐỜI 5"...
    let meta: String
    let look: ILFamilyTreeMedallionLook
    /// Deceased blood descendant with no children — shows the "— DỨT NHÁNH —" marker.
    let isBranchEnd: Bool
    /// The signed-in viewer — shows the gold "BẠN" pill above the medallion.
    let isMe: Bool
}

struct ILFamilyTreeGenerationChipModel: Equatable {
    /// 0 = all generations.
    let generation: Int
    let title: String
    let isSelected: Bool
}

struct ILFamilyTreeRelationModel: Equatable {
    let memberID: String
    let kind: String
    let name: String
    let generation: String
}

struct ILFamilyTreeLineageStepModel: Equatable {
    let memberID: String
    let name: String
    let meta: String
    let isSelected: Bool
    /// A line continues down to the next step.
    let hasNext: Bool
}

/// "TƯỞNG NIỆM" card shown for a deceased member.
struct ILFamilyTreeMemorialModel: Equatable {
    /// "Giỗ 15 tháng Chạp" or "Chưa rõ ngày giỗ".
    let title: String
    let subtitle: String
    let buttonTitle: String
    /// Filled (call to action) when the anniversary is known, outlined otherwise.
    let isButtonFilled: Bool
}

struct ILFamilyTreeDetailModel: Equatable {
    let memberID: String
    let look: ILFamilyTreeMedallionLook
    let name: String
    let meta: String
    let status: String
    let role: String?
    let years: String
    let anniversary: String?
    let branch: String
    let isBranchEnd: Bool
    /// Extra facts — `nil` means "not recorded yet" (the sheet shows "Chưa cập nhật").
    let residence: String?
    let burialPlace: String?
    let dharmaName: String?
    let tabletTemple: String?
    let memorial: ILFamilyTreeMemorialModel?
    /// Outlined bottom pill: "Thêm con cháu" (living) / "Nhắc ngày giỗ" (deceased).
    let contextualActionTitle: String
    let note: String?
    /// "Với bạn" text; `nil` hides the row (no viewer, or the relation cannot be derived).
    let kinship: String?
    let relations: [ILFamilyTreeRelationModel]
    let lineage: [ILFamilyTreeLineageStepModel]
    /// Section title above the lineage: "HUYẾT THỐNG TỪ THỦY TỔ", or "ĐƯỜNG NỐI VỚI BẠN" in the merged view.
    var lineageTitle: String = "familyTree.detail.lineage".localized
}

/// What the canvas shows: one of the user's clan books, or the merged "Nội – ngoại của bạn" tree.
enum ILFamilyTreeViewKind: Equatable {
    case book(String)
    case merged
}

/// One row of the book switcher menu.
struct ILFamilyTreeSwitcherRowModel: Equatable {
    let kind: ILFamilyTreeViewKind
    /// Which book it is — picks the seal colour; `nil` for the merged view.
    let side: ILFamilyTreeSide?
    /// 譜 for a book, 合 for the merged view.
    let glyph: String
    let title: String
    let subtitle: String
    let isSelected: Bool
}

/// Asks the canvas to scroll a person to the middle of the visible area. `token` changes on every
/// request so selecting the same person twice still re-centres.
struct ILFamilyTreeFocusRequest: Equatable {
    let memberID: String
    let token: Int
}

/// UI state for the FamilyTree screen — Presentation layer, owned and mutated exclusively by
/// `ILFamilyTreeViewModel`. No UIKit import, no business logic.
struct ILFamilyTreeStateModel: Equatable {
    var title = ""
    var subtitle = ""
    var isEmpty = true

    /// The ▾ next to the clan name; the menu lists the books, the merged view and the chronicle link.
    var canSwitch = false
    var isSwitcherOpen = false
    var switcherRows: [ILFamilyTreeSwitcherRowModel] = []
    /// "Tạo gia phả mới" row at the bottom of the menu (at most one paternal and one maternal book).
    var canCreateBook = false
    /// Showing the merged "Nội – ngoại" view: no "+" button, different legend.
    var isMerged = false

    var isSearchOpen = false
    var searchText = ""
    var searchCountText = ""

    var generationChips: [ILFamilyTreeGenerationChipModel] = []

    var layout = ILFamilyTreeLayout.empty
    var nodes: [ILFamilyTreeNodeModel] = []

    var selectedID: String?
    /// The viewer's member id; `nil` hides every "BẠN" element.
    var meID: String?
    /// Members on the founder → selected-person line, drawn in gold.
    var lineageIDs: Set<String> = []
    /// Opacity of members hidden by the generation filter or the search; absent = fully visible.
    var nodeAlphas: [String: CGFloat] = [:]

    var detail: ILFamilyTreeDetailModel?
    var isSheetExpanded = false
    var focus: ILFamilyTreeFocusRequest?

    static let initial = ILFamilyTreeStateModel()
}
