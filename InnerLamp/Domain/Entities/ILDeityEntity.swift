//
//  ILDeityEntity.swift
//  InnerLamp
//

import Foundation

/// Loại của một vị trong thư viện "Phật & Bồ Tát" — khớp cột `type` (BUDDHA / BODHISATTVA)
/// trong `Docs/Assert/Data/phat_botat.json`. Domain không import UIKit nên `ViewController`
/// map sang tông màu hiển thị (`ILColors.Tone`) khi cần.
enum ILDeityKind: Equatable {
    case buddha
    case bodhisattva
}

/// 1 ngày vía / lễ kỷ niệm theo âm lịch của một vị Phật / Bồ Tát — nội dung catalog.
struct ILDeityMemorialDayEntity: Equatable {
    let lunarDay: Int
    let lunarMonth: Int
    let eventName: String
}

/// Mô tả tượng pháp của một vị Phật / Bồ Tát (thế tướng, tòa/linh thú, pháp khí, ý nghĩa).
struct ILDeityIconographyEntity: Equatable {
    let posture: String
    let mountOrThrone: String
    let sacredArtifacts: [String]
    let symbolicMeaning: String
}

/// Bộ mật chú của một vị Phật / Bồ Tát — thần chú ngắn (Phạn + phiên âm Hán-Việt) và Đà-la-ni.
struct ILDeityMantraEntity: Equatable {
    let shortSanskrit: String
    let shortSinoVietnamese: String
    let dharaniName: String
    let dharaniSnippet: String
}

/// Pure business entity cho một vị Phật / Bồ Tát — Domain layer only.
///
/// Chỉ chứa dữ liệu có ý nghĩa nghiệp vụ thực sự (danh xưng, đức hạnh, tịnh độ, kinh điển, tượng
/// pháp, tiểu sử, đại nguyện, mật chú, ngày vía). Đây là **dữ liệu nội dung** (sẽ lấy từ API /
/// nguồn dữ liệu catalog, xem `Docs/Assert/Data/phat_botat.json`), KHÔNG phải UI copy — nên không
/// đi qua `.localized`. Các nhãn UI (`kindLabel`, tiêu đề section) là việc của
/// `ILDeityStateModel` / `ILDeityViewModel`. Xem `references/data_layer_boundaries.md`.
struct ILDeityEntity: Equatable, Identifiable {
    let id: String
    let kind: ILDeityKind
    let nameVi: String
    let nameSanskrit: String
    let nameChinese: String
    let titleHonorific: String
    let canonicalSource: String
    let coreVirtue: String
    let pureLand: String
    let memorialDays: [ILDeityMemorialDayEntity]
    let iconography: ILDeityIconographyEntity
    let biographySummary: String
    let greatVows: [String]
    let mantra: ILDeityMantraEntity
}

/// Lần tới (theo dương lịch) của một ngày vía — kết quả tính của `ILDeityUseCase`, dùng cho thẻ
/// ngày vía ở đầu màn chi tiết Phật & Bồ Tát.
struct ILDeityUpcomingMemorialDayEntity: Equatable {
    let memorialDay: ILDeityMemorialDayEntity
    /// Ngày dương lịch (đã chuẩn về 12:00 trưa) của lần vía tới.
    let date: Date
    /// Số ngày từ hôm nay (0 = hôm nay, 1 = ngày mai).
    let daysUntil: Int
}

/// 1 bộ kinh liên quan tới một vị Phật / Bồ Tát (tách từ `canonicalSource`). `sutraID` chỉ có
/// khi bộ kinh đã nằm trong catalog Thư viện — lúc đó mới mở được màn chi tiết bài kinh.
struct ILDeityRelatedSutraEntity: Equatable {
    let title: String
    let sutraID: String?
}

extension ILDeityEntity {
    /// Ngày vía chính dùng cho thẻ tóm tắt (carousel Trang chủ, danh sách "Chư Phật & Bồ Tát"):
    /// ưu tiên ngày đản sinh ("Đản") hoặc ngày có chữ "Vía" (vd. Thích Ca → Phật Đản 15/4,
    /// Quán Thế Âm → Đản sinh 19/2), ngược lại lấy ngày lễ đầu tiên của catalog. `nil` khi vị
    /// không có ngày vía nào.
    var primaryMemorialDay: ILDeityMemorialDayEntity? {
        Self.primaryMemorialDay(of: memorialDays)
    }

    /// Bản static của `primaryMemorialDay` cho nơi chỉ có mảng `memorialDays` (vd. mapper của
    /// Trang chủ / Thư viện).
    static func primaryMemorialDay(of days: [ILDeityMemorialDayEntity]) -> ILDeityMemorialDayEntity? {
        days.first { $0.eventName.contains("Đản") || $0.eventName.contains("Vía") } ?? days.first
    }

    /// `canonicalSource` tách thành từng bộ kinh — cắt ở dấu phẩy nằm ngoài ngoặc đơn, để
    /// "Kinh Hoa Nghiêm (Avataṃsaka Sūtra), Kinh Đại Nhật" thành 2 mục.
    var canonicalSources: [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0
        for character in canonicalSource {
            switch character {
            case "(":
                depth += 1
            case ")":
                depth = max(0, depth - 1)
            case "," where depth == 0:
                parts.append(current)
                current = ""
                continue
            default:
                break
            }
            current.append(character)
        }
        parts.append(current)
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
