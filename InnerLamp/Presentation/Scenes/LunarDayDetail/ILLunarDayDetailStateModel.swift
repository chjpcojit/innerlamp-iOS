//
//  ILLunarDayDetailStateModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation

/// Tông màu chấm + viền của pill "loại ngày" ở hero — `ViewController` map sang `ILColors`.
enum ILLunarDayDetailTypeTone: Equatable {
    /// Rằm / Mùng Một — vàng.
    case gold
    /// Ngày Hoàng đạo — xanh.
    case auspicious
    /// Ngày Hắc đạo — đỏ.
    case inauspicious
}

/// 1 hàng trong bảng "Ngày · Tháng · Năm · Dương lịch".
struct ILLunarDayDetailInfoRowModel: Equatable, Identifiable {
    let id: String
    let key: String
    let value: String
}

/// 1 ô giờ hoàng đạo — tên chi, con giáp (emoji), khung giờ.
struct ILLunarDayDetailHourModel: Equatable, Identifiable {
    let id: Int
    let name: String
    let icon: String
    let range: String
}

/// 1 chip tuổi xung khắc — tên Can Chi + con giáp (emoji).
struct ILLunarDayDetailClashModel: Equatable, Identifiable {
    let id: String
    let name: String
    let icon: String
}

/// Loại ô "Hướng xuất hành" — dùng để `ViewController` map tone màu.
enum ILLunarDayDetailDirectionKind: Equatable {
    /// Hỷ thần (hướng tốt) — đỏ clash.
    case joy
    /// Tài thần (hướng tốt) — vàng accent.
    case wealth
    /// Hạc thần (hướng xấu cần tránh) — đỏ hắc đạo (`ILColors.inauspicious`).
    case crane
}

/// 1 ô "Hướng xuất hành" (Hỷ thần / Tài thần / Hạc thần).
struct ILLunarDayDetailDirectionModel: Equatable, Identifiable {
    let id: String
    let key: String
    let value: String
    let subtitle: String
    let glyph: String
    let kind: ILLunarDayDetailDirectionKind
}

/// Mức đánh giá Cát/Hung của ngày trên thang 5 bậc — khớp `alScale`/`al.rating` trong design
/// handoff (`Đại hung → Đại cát`). Được map từ `ILAuspiciousTier` (7 bậc) ở ViewModel.
enum ILLunarDayDetailDayRating: Int, CaseIterable, Equatable {
    case daiHung = 0
    case hung = 1
    case binh = 2
    case cat = 3
    case daiCat = 4

    /// Nhãn hiển thị đã `.localized` ("Đại Hung", "Hung", "Bình", "Cát", "Đại Cát").
    var localizedLabel: String {
        switch self {
        case .daiHung: return "lunarDayDetail.almanac.rating.daiHung".localized
        case .hung: return "lunarDayDetail.almanac.rating.hung".localized
        case .binh: return "lunarDayDetail.almanac.rating.binh".localized
        case .cat: return "lunarDayDetail.almanac.rating.cat".localized
        case .daiCat: return "lunarDayDetail.almanac.rating.daiCat".localized
        }
    }
}

/// Thẻ "Ngày [Cát/Hung]" — đánh giá ngày + thang 5 bậc + việc nên làm / kiêng cữ (khớp `al`
/// trong design handoff). Toàn bộ nhãn đã `.localized`/format ở ViewModel.
struct ILLunarDayDetailAlmanacModel: Equatable {
    /// Bậc hiện tại (chọn pill nào trên thang).
    let rating: ILLunarDayDetailDayRating
    /// Nhãn hiện tại ("Đại Cát", "Cát", …) dùng cho vòng tròn + tiêu đề "Ngày …".
    let ratingLabel: String
    /// Phụ đề "Trực … · ngày hoàng đạo/hắc đạo".
    let ratingSub: String
    /// Các việc nên làm (NÊN).
    let dos: [String]
    /// Các việc kiêng cữ (KHÔNG NÊN).
    let donts: [String]
}

/// 1 ô trong phần "Ngũ hành & nạp âm" — Can ngày / Chi ngày / Nạp âm, mỗi ô gồm tên + hành.
struct ILLunarDayDetailElementModel: Equatable, Identifiable {
    let id: String
    let key: String
    let name: String
    /// Ngũ Hành của ô (dùng để `ViewController` map màu chấm/chữ).
    let element: ILFiveElements
    /// Tên Ngũ Hành ("Kim", "Thủy", …) đã `.localized`.
    let elementName: String
}

/// UI state cho màn "Chi tiết ngày âm" — Presentation layer, do `ILLunarDayDetailViewModel` sở
/// hữu và cập nhật độc quyền. Không UIKit, không business logic — `ViewController` chỉ đọc để
/// hiển thị. Toàn bộ nhãn/copy đã `.localized` và format sẵn ở đây, khác với dữ liệu nghiệp vụ
/// thô nằm trên `ILLunarDayDetailEntity` (xem `references/data_layer_boundaries.md`).
struct ILLunarDayDetailStateModel: Equatable {
    var eyebrowText: String = ""
    /// Short lunar date ("15 Tháng Tám") shown in the header once the hero has scrolled away.
    var headerTitle: String = ""
    var heroDay: String = ""
    var heroMonth: String = ""
    var heroYear: String = ""
    var heroSolar: String = ""
    var typeTone: ILLunarDayDetailTypeTone = .auspicious
    var typeLabel: String = ""
    var adviceText: String = ""
    /// Server picture of the day shown behind the hero; `nil` keeps the gradient placeholder.
    var heroImageURL: String? = nil
    /// "Ảnh: <author> · <license>"; empty hides the caption.
    var heroImageCredit: String = ""

    var infoRows: [ILLunarDayDetailInfoRowModel] = []

    var almanac: ILLunarDayDetailAlmanacModel = ILLunarDayDetailAlmanacModel(
        rating: .binh, ratingLabel: "", ratingSub: "", dos: [], donts: []
    )

    var elementsTitle: String = ""
    /// Dòng nạp âm lớn ("Hải Trung Kim") — màu theo Ngũ Hành do ViewController map từ `napamElement`.
    var napamLine: String = ""
    var napamElement: ILFiveElements = .kim
    var elements: [ILLunarDayDetailElementModel] = []

    var verseLines: [String] = []
    var verseSource: String = ""

    var goodHoursTitle: String = ""
    var goodHours: [ILLunarDayDetailHourModel] = []

    var clashTitle: String = ""
    var clashItems: [ILLunarDayDetailClashModel] = []
    var clashNote: String = ""

    var directionsTitle: String = ""
    var directions: [ILLunarDayDetailDirectionModel] = []

    static let initial = ILLunarDayDetailStateModel()
}
