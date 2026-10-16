//
//  ILSutrasEntity.swift
//  InnerLamp
//

import Foundation

/// Mục đích tụng của một bản văn — khớp enum `purpose` của `GET /v1/sutras` (10 giá trị).
nonisolated enum ILSutraPurpose: Equatable, CaseIterable {
    case blessing       // CAU_AN
    case requiem        // CAU_SIEU
    case mantra         // TRI_CHU
    case repentance     // SAM_HOI
    case dedication     // HOI_HUONG
    case vow            // PHAT_NGUYEN
    case karmicReward   // BAO_HIEU
    case meditation     // THIEN_DINH
    case study          // HOC_GIAO_LY
    case refugePrecepts // QUY_Y_THO_GIOI
}

/// Truyền thống của bản văn — khớp enum `tradition`.
nonisolated enum ILSutraTradition: Equatable, CaseIterable {
    case theravada
    case mahayana
    case vajrayana
}

/// Thể loại bản văn — khớp enum `kind` (kinh / kệ / chú).
nonisolated enum ILSutraKind: Equatable {
    case sutra
    case verse
    case dharani
}

/// Một bản kinh / kệ / chú trong danh sách "Kinh sách" — dữ liệu nghiệp vụ từ `GET /v1/sutras`.
/// Chuỗi đã format ("~22 phút", nhãn mục đích) là UI state nên không nằm ở đây.
nonisolated struct ILSutraEntity: Equatable, Identifiable {
    /// Slug do server cấp, ví dụ `kinh-hanh-phuc`.
    let id: String
    let title: String
    /// Tên nguyên ngữ (Pāli / Anh) khi khác `title`; rỗng nếu không có.
    let originalTitle: String
    /// `nil` khi server trả giá trị mà app chưa biết.
    let kind: ILSutraKind?
    let tradition: ILSutraTradition?
    let collection: String
    let reference: String
    let isDailyChant: Bool
    let purposes: [ILSutraPurpose]
    /// `nil` khi server chưa có ước tính thời lượng.
    let durationMinutes: Int?
    /// Dịch giả của bản dịch ưu tiên (tiếng Việt nếu có); rỗng nếu server không ghi.
    let translator: String
    /// URL audio do server cấp; rỗng khi bản kinh chưa có audio.
    let audioURL: String

    var hasAudio: Bool { !audioURL.isEmpty }
}

/// Một trang kết quả của `GET /v1/sutras` (20 mục/trang cố định).
nonisolated struct ILSutraPageEntity: Equatable {
    let items: [ILSutraEntity]
    let page: Int
    let totalCount: Int
    let hasMore: Bool
}

/// Bộ lọc theo mục đích / tông phái (hàng chip trên cùng của màn "Kinh sách"). Mỗi giá trị ứng với
/// đúng một tham số lọc của server — các chip loại trừ nhau.
nonisolated enum ILSutraCategory: Equatable, CaseIterable {
    case all
    case dailyChant
    case purpose(ILSutraPurpose)
    case tradition(ILSutraTradition)

    static let allCases: [ILSutraCategory] =
        [.all, .dailyChant]
        + ILSutraPurpose.allCases.map { .purpose($0) }
        + ILSutraTradition.allCases.map { .tradition($0) }
}

/// Bộ lọc theo độ dài (hàng chip thứ hai) — server chỉ hỗ trợ trần `max_minutes`.
/// @ai: chips follow the server enums; the 60-minute chip is pending — see Docs/Specs/Sutra/ (BR-STR-03, tasks.md Phase 3)
nonisolated enum ILSutraLengthFilter: Equatable, CaseIterable {
    case any
    case upTo5
    case upTo15
    case upTo30

    /// `nil` = không giới hạn.
    var maxMinutes: Int? {
        switch self {
        case .any: return nil
        case .upTo5: return 5
        case .upTo15: return 15
        case .upTo30: return 30
        }
    }
}

/// Bộ lọc gửi lên server; đổi bộ lọc luôn bắt đầu lại từ trang 1.
nonisolated struct ILSutraFilter: Equatable {
    var category: ILSutraCategory = .all
    var length: ILSutraLengthFilter = .any
    /// Từ khóa tìm kiếm gửi lên server (`q`); đã trim và giới hạn độ dài, rỗng = không tìm.
    var query: String = ""
}

/// Pure business entity cho màn "Kinh sách" — các trang đã tải, theo thứ tự server.
struct ILSutrasEntity: Equatable {
    var sutras: [ILSutraEntity] = []
    /// Tổng số bản kinh khớp bộ lọc hiện tại (theo server, không chỉ phần đã tải).
    var totalCount: Int = 0
    var lastLoadedPage: Int = 0
    var hasMore: Bool = false

    static let empty = ILSutrasEntity()
}
