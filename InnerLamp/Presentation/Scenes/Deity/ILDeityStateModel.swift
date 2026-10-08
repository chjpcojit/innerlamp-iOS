//
//  ILDeityStateModel.swift
//  InnerLamp
//

import Foundation

/// Thẻ ngày vía gần nhất ở đầu màn — ô ngày/tháng âm, tên ngày vía, đếm ngược + ngày dương.
struct ILDeityMemorialDayModel: Equatable {
    /// "19"
    let dayText: String
    /// "THÁNG 2" / "GIÊNG" / "CHẠP"
    let monthText: String
    let eventName: String
    /// "Còn 12 ngày · Thứ 5, 19-03-2026"
    let countdownText: String
}

/// 1 đại nguyện đã đánh số.
struct ILDeityVowModel: Equatable {
    let number: String
    let text: String
}

/// 1 thẻ "Thần chú & danh hiệu" — `text` là câu dùng để trì niệm (gửi sang màn Niệm Phật).
struct ILDeityMantraModel: Equatable {
    let label: String
    let text: String
    /// Phạn ngữ (nghiêng) — rỗng thì ẩn.
    let sanskrit: String
    /// Ghi chú — rỗng thì ẩn.
    let note: String
}

/// 1 hàng "Kinh liên quan". `sutraID` = `nil` → hàng chỉ để đọc, không có nút "Mở".
struct ILDeitySutraModel: Equatable {
    let title: String
    let subtitle: String
    let trailingText: String
    let sutraID: String?
}

/// UI state cho màn chi tiết Phật & Bồ Tát (`buddha` trong design handoff) — Presentation layer,
/// do `ILDeityViewModel` sở hữu và cập nhật độc quyền. Không UIKit, không business logic —
/// `ViewController` chỉ đọc để hiển thị. Nhãn UI (`.localized`) và giá trị đã format nằm ở đây;
/// dữ liệu nội dung thô nằm trên `ILDeityEntity` (xem `references/data_layer_boundaries.md`).
struct ILDeityStateModel: Equatable {
    /// Tiêu đề header — chỉ hiện khi đã cuộn qua hero (`ViewController` quyết định lúc hiện).
    var headerTitle: String = ""

    // MARK: Hero
    /// Loại vị (Phật / Bồ Tát) — giữ để test/logic; hero dùng chung bảng màu nhấn `--il-hero-acc`.
    var kind: ILDeityKind = .buddha
    var kindLabel: String = ""
    /// Cõi tịnh độ / nơi ngự — chip thứ hai trên hero.
    var realmLabel: String = ""
    var name: String = ""
    var sanskritName: String = ""
    /// Danh xưng chữ Hán — in chìm trên nền hero thay cho ảnh tôn tượng (chưa có ảnh thật).
    var watermark: String = ""
    /// Server image of the statue for the hero background — nil/empty keeps the watermark placeholder.
    var imageURL: String?

    // MARK: Memorial day
    var memorialDay: ILDeityMemorialDayModel?
    var festivalsLinkTitle: String = ""
    /// Câu mô tả ngắn dưới thẻ ngày vía (đức hạnh cốt lõi).
    var roleText: String = ""

    // MARK: Biography
    var biographyTitle: String = ""
    var biography: String = ""
    var isBiographyExpanded: Bool = false
    var biographyToggleTitle: String = ""

    // MARK: Vows
    var vowsTitle: String = ""
    var vowsCountText: String = ""
    /// Các đại nguyện đang hiển thị (đã cắt còn 5 khi thu gọn).
    var vows: [ILDeityVowModel] = []
    /// Nút "Xem đủ … / Thu gọn" — `nil` khi không quá 5 đại nguyện.
    var vowsToggleTitle: String?

    // MARK: Mantras
    var mantrasTitle: String = ""
    var mantras: [ILDeityMantraModel] = []
    var chantTitle: String = ""
    var shareTitle: String = ""

    // MARK: Related sutras
    var sutrasTitle: String = ""
    var sutras: [ILDeitySutraModel] = []

    var footnote: String = ""

    static let initial = ILDeityStateModel()
}
