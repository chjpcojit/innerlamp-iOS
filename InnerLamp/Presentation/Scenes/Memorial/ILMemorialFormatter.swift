//
//  ILMemorialFormatter.swift
//  InnerLamp
//

import Foundation

/// Display strings of the memorial book, shared by the list and the form ViewModels. Pure
/// formatting over Domain values — no UIKit, no state.
enum ILMemorialFormatter {

    static func relationshipLabel(_ relationship: ILMemorialRelationship) -> String {
        "memorial.relationship.\(relationship.rawValue)".localized
    }

    /// "Hôm nay" / "Ngày mai" / "còn 12 ngày".
    static func daysLabel(_ days: Int) -> String {
        switch days {
        case ...0: return "memorial.days.today".localized
        case 1: return "memorial.days.tomorrow".localized
        default: return String(format: "memorial.days.format".localized, days)
        }
    }

    /// "GIỖ HÔM NAY" / "GIỖ NGÀY MAI" / "GIỖ SẮP TỚI · CÒN 12 NGÀY".
    static func eyebrow(days: Int) -> String {
        switch days {
        case ...0: return "memorial.eyebrow.today".localized
        case 1: return "memorial.eyebrow.tomorrow".localized
        default: return String(format: "memorial.eyebrow.format".localized, days)
        }
    }

    /// "Giỗ đầu" / "Giỗ hết" / "Giỗ lần thứ 5"; empty when there is no ordinal.
    static func ordinalText(_ ordinal: Int?) -> String {
        switch ordinal {
        case nil: return ""
        case 1?: return "memorial.ordinal.first".localized
        case 2?: return "memorial.ordinal.second".localized
        case let n?: return String(format: "memorial.ordinal.format".localized, n)
        }
    }

    /// "15 tháng Chạp âm lịch" or "15/12 dương lịch" — the date as stored.
    static func storedDateLine(_ entry: ILMemorialEntity) -> String {
        switch entry.calendarKind {
        case .lunar:
            return String(format: "memorial.date.lunarFormat".localized, entry.day, lunarMonthName(entry.month))
        case .solar:
            return String(format: "memorial.date.solarFormat".localized, entry.day, entry.month)
        }
    }

    /// "Thứ Bảy, 15/11/2026".
    static func solarLine(_ date: Date) -> String {
        let text = solarFormatter.string(from: date)
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    /// "Trước 1 ngày · 07:00 · có trong Lời nhắc", "Đúng ngày · 07:00", or "Chưa bật".
    static func reminderLine(_ entry: ILMemorialEntity) -> String {
        guard let reminder = entry.reminder else { return "memorial.reminder.off".localized }
        let lead = leadLabel(reminder.leadDays)
        let time = timeLabel(hour: reminder.hour, minute: reminder.minute)
        var line = "\(lead) · \(time)"
        if entry.syncToReminders {
            line += " · " + "memorial.reminder.inReminders".localized
        }
        return line
    }

    /// "Đúng ngày" / "Trước 3 ngày".
    static func leadLabel(_ leadDays: Int) -> String {
        leadDays == 0
            ? "memorial.reminder.lead.onDay".localized
            : String(format: "memorial.reminder.lead.format".localized, leadDays)
    }

    /// "07:00".
    static func timeLabel(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// " · Giỗ đầu" — the ordinal as a suffix of a preview line; empty when there is none.
    static func ordinalSuffix(_ ordinal: Int?) -> String {
        let text = ordinalText(ordinal)
        return text.isEmpty ? "" : " · \(text)"
    }

    static func lunarMonthName(_ month: Int) -> String {
        "lunarCalendar.month.\(max(1, min(12, month)))".localized
    }

    private static let solarFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter
    }()
}
