//
//  ILFestivalDetailStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state cho màn "Chi tiết ngày lễ" — Presentation layer, do `ILFestivalDetailViewModel` sở
/// hữu. Không UIKit, không business logic. Mục nào server chưa có nội dung thì bị ẩn
/// (BR-CAL-14); ViewController ẩn theo chuỗi/mảng rỗng.
struct ILFestivalDetailStateModel: Equatable {
    // MARK: Hero
    var imageURL: String?
    /// Hiện trên khung ảnh khi `imageURL` là `nil`.
    var imageEmptyText: String = ""

    // MARK: Header
    /// "LỄ LỚN · PHẬT GIÁO" — nhãn lễ lớn rồi tên nhóm viết hoa; rỗng thì ẩn hàng.
    var kindText: String = ""
    var title: String = ""
    /// "Ngày 15 · Tháng Bảy âm lịch".
    var lunarText: String = ""

    // MARK: About
    var aboutParagraphs: [String] = []

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
}
