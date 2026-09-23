//
//  ILLunarCalendar.swift
//  InnerLamp
//

import Foundation

/// Chuyển đổi dương lịch ↔ âm lịch Việt Nam (múi giờ UTC+7) — port của thuật toán thiên văn
/// công khai của Hồ Ngọc Đức (chuẩn dùng cho lịch Việt Nam, chính xác trong khoảng 1200–2200),
/// dùng cho thẻ âm lịch lớn và dải lịch tuần ở Trang chủ. Không phụ thuộc thư viện ngoài.
enum ILLunarCalendar {

    struct LunarDate: Equatable {
        let day: Int
        let month: Int
        let year: Int
        let isLeapMonth: Bool
    }

    private static let timeZone: Double = 7.0

    // MARK: - Julian day number

    private static func jdFromDate(day: Int, month: Int, year: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        var jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        if jd < 2299161 {
            jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }
        return jd
    }

    // MARK: - Astronomical helpers

    private static func newMoon(_ k: Double) -> Double {
        let T = k / 1236.85
        let T2 = T * T
        let T3 = T2 * T
        let dr = Double.pi / 180
        var jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3
        jd1 += 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)

        let M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3
        let mPr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3
        let F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3

        var c1 = (0.1734 - 0.000393 * T) * sin(M * dr) + 0.0021 * sin(2 * dr * M)
        c1 -= 0.4068 * sin(mPr * dr) + 0.0161 * sin(dr * 2 * mPr)
        c1 -= 0.0004 * sin(dr * 3 * mPr)
        c1 += 0.0104 * sin(dr * 2 * F) - 0.0051 * sin(dr * (M + mPr))
        c1 -= 0.0074 * sin(dr * (M - mPr)) + 0.0004 * sin(dr * (2 * F + M))
        c1 -= 0.0004 * sin(dr * (2 * F - M)) - 0.0006 * sin(dr * (2 * F + mPr))
        c1 += 0.0010 * sin(dr * (2 * F - mPr)) + 0.0005 * sin(dr * (2 * mPr + M))

        let deltaT: Double
        if T < -11 {
            deltaT = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3
        } else {
            deltaT = -0.000278 + 0.000265 * T + 0.000262 * T2
        }

        return jd1 + c1 - deltaT
    }

    private static func sunLongitude(_ jdn: Double) -> Double {
        let T = (jdn - 2451545.0) / 36525
        let T2 = T * T
        let dr = Double.pi / 180
        let M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
        let L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2
        var dl = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(dr * M)
        dl += (0.019993 - 0.000101 * T) * sin(dr * 2 * M) + 0.000290 * sin(dr * 3 * M)
        var l = (L0 + dl) * dr
        l -= Double.pi * 2 * floor(l / (Double.pi * 2))
        return l
    }

    private static func sunLongitudeIndex(jdn: Int) -> Int {
        let longitude = sunLongitude(Double(jdn) - 0.5 - timeZone / 24)
        return Int(floor(longitude / Double.pi * 6))
    }

    private static func newMoonDay(k: Double) -> Int {
        Int(floor(newMoon(k) + 0.5 + timeZone / 24))
    }

    private static func lunarMonth11(year: Int) -> Int {
        let off = Double(jdFromDate(day: 31, month: 12, year: year)) - 2415021.076998695
        let k = floor(off / 29.530588853)
        var nm = newMoonDay(k: k)
        if sunLongitudeIndex(jdn: nm) >= 9 {
            nm = newMoonDay(k: k - 1)
        }
        return nm
    }

    private static func leapMonthOffset(a11: Int) -> Int {
        let k = floor((Double(a11) - 2415021.076998695) / 29.530588853 + 0.5)
        var i = 1
        var last = sunLongitudeIndex(jdn: newMoonDay(k: k + Double(i)))
        var arc = last
        repeat {
            last = arc
            i += 1
            arc = sunLongitudeIndex(jdn: newMoonDay(k: k + Double(i)))
        } while arc != last && i < 14
        return i - 1
    }

    // MARK: - Public

    static func solarToLunar(day: Int, month: Int, year: Int) -> LunarDate {
        let dayNumber = jdFromDate(day: day, month: month, year: year)
        let k = floor((Double(dayNumber) - 2415021.076998695) / 29.530588853)
        var monthStart = newMoonDay(k: k + 1)
        if monthStart > dayNumber {
            monthStart = newMoonDay(k: k)
        }

        var a11 = lunarMonth11(year: year)
        var b11 = a11
        var lunarYear: Int
        if a11 >= monthStart {
            lunarYear = year
            a11 = lunarMonth11(year: year - 1)
        } else {
            lunarYear = year + 1
            b11 = lunarMonth11(year: year + 1)
        }

        let lunarDay = dayNumber - monthStart + 1
        let diff = Int(floor(Double(monthStart - a11) / 29.0))
        var isLeap = false
        var lunarMonth = diff + 11

        if b11 - a11 > 365 {
            let leapOffset = leapMonthOffset(a11: a11)
            if diff >= leapOffset {
                lunarMonth = diff + 10
                isLeap = diff == leapOffset
            }
        }
        if lunarMonth > 12 {
            lunarMonth -= 12
        }
        if lunarMonth >= 11 && diff < 4 {
            lunarYear -= 1
        }

        return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear, isLeapMonth: isLeap)
    }

    static func solarToLunar(date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> LunarDate {
        let comps = calendar.dateComponents([.day, .month, .year], from: date)
        return solarToLunar(day: comps.day ?? 1, month: comps.month ?? 1, year: comps.year ?? 2000)
    }

    // MARK: - Can Chi (Thiên Can – Địa Chi)

    private static let canNames = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    private static let chiNames = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

    /// Tên năm âm theo Can Chi — vd năm âm lịch 2024 -> "Giáp Thìn".
    static func canChiYear(_ lunarYear: Int) -> String {
        let can = canNames[((lunarYear + 6) % 10 + 10) % 10]
        let chi = chiNames[((lunarYear + 8) % 12 + 12) % 12]
        return "\(can) \(chi)"
    }

    private static let lunarMonthNames = [
        "Giêng", "Hai", "Ba", "Tư", "Năm", "Sáu", "Bảy", "Tám", "Chín", "Mười", "Mười Một", "Chạp"
    ]

    /// "Tháng Bảy" — tháng nhuận thêm hậu tố "(nhuận)".
    static func lunarMonthLabel(_ month: Int, isLeap: Bool) -> String {
        let index = max(1, min(12, month)) - 1
        let name = lunarMonthNames[index]
        return isLeap ? "Tháng \(name) (nhuận)" : "Tháng \(name)"
    }
}
