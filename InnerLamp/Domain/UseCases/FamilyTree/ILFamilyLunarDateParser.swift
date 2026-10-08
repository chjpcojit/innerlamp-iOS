//
//  ILFamilyLunarDateParser.swift
//  InnerLamp
//

import Foundation

/// Reads the free-text "ngày giỗ" typed in the family-tree forms. Shared by the create and
/// add-member UseCases.
enum ILFamilyLunarDateParser {

    /// Reads "15 tháng Chạp", "15 tháng 12", "15/12" or "15-12": a day (1–30) and a lunar month
    /// given as a number or by its name ("Giêng"…"Chạp"). Anything else is rejected.
    // @ai: assumption — see Docs/Assumptions/FamilyTreeCreate/AS-FamilyTreeCreate-002-anniversary-text-format.md
    static func parse(_ text: String) -> ILFamilyLunarDate? {
        let folded = fold(text)
        let numbers = folded.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let day = numbers.first, (1...30).contains(day) else { return nil }

        if numbers.count >= 2 {
            return (1...12).contains(numbers[1]) ? ILFamilyLunarDate(day: day, month: numbers[1]) : nil
        }
        // Longest names first so "Mười Một" wins over "Mười".
        let names = (1...12)
            .map { (month: $0, name: fold("lunarCalendar.month.\($0)".localized)) }
            .sorted { $0.name.count > $1.name.count }
        let words = folded.replacingOccurrences(of: "thang", with: " ")
        guard let match = names.first(where: { words.contains($0.name) }) else { return nil }
        return ILFamilyLunarDate(day: day, month: match.month)
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi"))
            .replacingOccurrences(of: "đ", with: "d")
    }
}
