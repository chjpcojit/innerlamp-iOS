//
//  ILLunarDayDetailUseCase.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation

protocol ILLunarDayDetailUseCase {
    /// Tính trọn bộ dữ liệu lịch âm cho 1 ngày dương — thuần tính toán trên `ILLunarCalendar`,
    /// không network/disk.
    func getDetail(for date: Date) -> ILLunarDayDetailEntity
}

final class ILLunarDayDetailUseCaseImpl: ILLunarDayDetailUseCase {

    func getDetail(for date: Date) -> ILLunarDayDetailEntity {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        let solarDay = components.day ?? 1
        let solarMonth = components.month ?? 1
        let solarYear = components.year ?? 2000

        let lunar = ILLunarCalendar.solarToLunar(day: solarDay, month: solarMonth, year: solarYear)
        let indices = ILLunarCalendar.dayCanChiIndices(day: solarDay, month: solarMonth, year: solarYear)
        let verse = Self.verse(forLunarDay: lunar.day, lunarMonth: lunar.month)

        return ILLunarDayDetailEntity(
            date: date,
            solarDay: solarDay,
            solarMonth: solarMonth,
            solarYear: solarYear,
            lunarDay: lunar.day,
            lunarMonth: lunar.month,
            lunarYear: lunar.year,
            isLunarLeapMonth: lunar.isLeapMonth,
            isHoangDao: ILLunarCalendar.isHoangDao(
                solarDay: solarDay,
                solarMonth: solarMonth,
                solarYear: solarYear,
                lunarMonth: lunar.month
            ),
            dayCanIndex: indices.can,
            dayChiIndex: indices.chi,
            goodHourChiIndices: ILLunarCalendar.goodHourChiIndices(dayChiIndex: indices.chi),
            clashChiIndex: ILLunarCalendar.clashChiIndex(dayChiIndex: indices.chi),
            joyStarDirection: ILLunarCalendar.joyStarDirection(dayCanIndex: indices.can),
            wealthStarDirection: ILLunarCalendar.wealthStarDirection(dayCanIndex: indices.can),
            craneStarDirection: ILLunarCalendar.craneStarDirection(can: indices.can, chi: indices.chi),
            verseLines: verse.lines,
            verseSource: verse.source
        )
    }

    /// Câu kinh trong ngày — index `(lunarDay + lunarMonth) % 4`, khớp `VERSES` trong design
    /// handoff (`InnerLamp Prototype.dc.html`, `dcVerse`/`dcSource`). Nội dung tĩnh, chưa có API
    /// "lời dạy hôm nay" thật.
    static func verse(forLunarDay lunarDay: Int, lunarMonth: Int) -> (lines: [String], source: String) {
        let index = ((lunarDay + lunarMonth) % Self.verseCatalog.count + Self.verseCatalog.count) % Self.verseCatalog.count
        return Self.verseCatalog[index]
    }

    private static let verseCatalog: [(lines: [String], source: String)] = [
        (
            [
                "lunarDayDetail.verse.0.line.0".localized,
                "lunarDayDetail.verse.0.line.1".localized,
                "lunarDayDetail.verse.0.line.2".localized,
                "lunarDayDetail.verse.0.line.3".localized
            ],
            "lunarDayDetail.verse.0.source".localized
        ),
        (
            [
                "lunarDayDetail.verse.1.line.0".localized,
                "lunarDayDetail.verse.1.line.1".localized,
                "lunarDayDetail.verse.1.line.2".localized,
                "lunarDayDetail.verse.1.line.3".localized
            ],
            "lunarDayDetail.verse.1.source".localized
        ),
        (
            [
                "lunarDayDetail.verse.2.line.0".localized,
                "lunarDayDetail.verse.2.line.1".localized,
                "lunarDayDetail.verse.2.line.2".localized,
                "lunarDayDetail.verse.2.line.3".localized
            ],
            "lunarDayDetail.verse.2.source".localized
        ),
        (
            [
                "lunarDayDetail.verse.3.line.0".localized,
                "lunarDayDetail.verse.3.line.1".localized,
                "lunarDayDetail.verse.3.line.2".localized,
                "lunarDayDetail.verse.3.line.3".localized
            ],
            "lunarDayDetail.verse.3.source".localized
        )
    ]
}
