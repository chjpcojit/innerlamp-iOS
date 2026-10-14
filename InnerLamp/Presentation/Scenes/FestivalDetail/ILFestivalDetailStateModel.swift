//
//  ILFestivalDetailStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state cho màn "Chi tiết ngày lễ" — Presentation layer, do `ILFestivalDetailViewModel` sở
/// hữu. Không UIKit, không business logic. Mục nào server chưa có dữ liệu vẫn được hiển thị với
/// `…EmptyText` (không ẩn); ViewController chọn giữa nội dung và `…EmptyText` theo mảng rỗng.
struct ILFestivalDetailStateModel: Equatable {
    // MARK: Hero
    var imageURL: String?
    /// Hiện trên khung ảnh khi `imageURL` là `nil`.
    var imageEmptyText: String = ""

    // MARK: Header
    /// "PHẬT GIÁO · VIỆT NAM" — tên nhóm viết hoa, hoặc nhãn "chưa có" khi không có nhóm.
    var kindText: String = ""
    var title: String = ""
    /// "Ngày 15 · Tháng Bảy âm lịch".
    var lunarText: String = ""

    // MARK: About
    var aboutParagraphs: [String] = []
    var aboutEmptyText: String = ""

    // MARK: Date card
    /// "05" — ngày dương, 2 chữ số.
    var dayText: String = ""
    /// "Thứ 5, Tháng 9, 2026".
    var dateText: String = ""
    /// "Dương lịch năm 2026".
    var dateCaption: String = ""
    /// "Hôm nay" / "Ngày mai" / "Còn N ngày" / "Đã qua".
    var countdownText: String = ""

    // MARK: Practices ("Phật tử thường làm gì")
    var practicesTitle: String = ""
    var practices: [String] = []
    var practicesEmptyText: String = ""

    // MARK: Sutra ("Kinh nên tụng") — chưa có nguồn dữ liệu (TD-FestivalDetail-001)
    var sutraTitle: String = ""
    var sutraEmptyText: String = ""

    // MARK: Hosts ("Chùa tổ chức") — chưa có nguồn dữ liệu (TD-FestivalDetail-001)
    var hostsTitle: String = ""
    var hostsEmptyText: String = ""
}
