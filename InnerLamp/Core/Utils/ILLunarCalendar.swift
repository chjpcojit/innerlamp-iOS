//
//  ILLunarCalendar.swift
//  InnerLamp
//

import Foundation

/// Chuyển đổi dương lịch ↔ âm lịch Việt Nam (múi giờ UTC+7) — port của thuật toán thiên văn
/// công khai của Hồ Ngọc Đức (chuẩn dùng cho lịch Việt Nam, chính xác trong khoảng 1200–2200),
/// dùng cho thẻ âm lịch lớn và dải lịch tuần ở Trang chủ. Không phụ thuộc thư viện ngoài.
enum ILLunarCalendar {

    nonisolated struct LunarDate: Equatable {
        let day: Int
        let month: Int
        let year: Int
        let isLeapMonth: Bool
    }

    private nonisolated static let timeZone: Double = 7.0

    // MARK: - Julian day number

    private nonisolated static func jdFromDate(day: Int, month: Int, year: Int) -> Int {
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

    private nonisolated static func newMoon(_ k: Double) -> Double {
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

    private nonisolated static func sunLongitude(_ jdn: Double) -> Double {
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

    private nonisolated static func sunLongitudeIndex(jdn: Int) -> Int {
        let longitude = sunLongitude(Double(jdn) - 0.5 - timeZone / 24)
        return Int(floor(longitude / Double.pi * 6))
    }

    private nonisolated static func newMoonDay(k: Double) -> Int {
        Int(floor(newMoon(k) + 0.5 + timeZone / 24))
    }

    private nonisolated static func lunarMonth11(year: Int) -> Int {
        let off = Double(jdFromDate(day: 31, month: 12, year: year)) - 2415021.076998695
        let k = floor(off / 29.530588853)
        var nm = newMoonDay(k: k)
        if sunLongitudeIndex(jdn: nm) >= 9 {
            nm = newMoonDay(k: k - 1)
        }
        return nm
    }

    private nonisolated static func leapMonthOffset(a11: Int) -> Int {
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

    nonisolated static func solarToLunar(day: Int, month: Int, year: Int) -> LunarDate {
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

    nonisolated struct SolarDate: Equatable {
        let day: Int
        let month: Int
        let year: Int
    }

    /// Inverse of `solarToLunar`: the solar date of lunar `day`/`month` in lunar `year` (same
    /// algorithm, UTC+7). A day 30 in a 29-day lunar month resolves to day 29 — the same
    /// short-month rule as `matchesLunarDay`. Returns `nil` when the request does not exist (a
    /// leap month the year does not have, or a day outside 1...30).
    nonisolated static func lunarToSolar(day: Int, month: Int, year: Int, isLeap: Bool = false) -> SolarDate? {
        guard (1...30).contains(day), (1...12).contains(month) else { return nil }

        let a11: Int
        let b11: Int
        if month < 11 {
            a11 = lunarMonth11(year: year - 1)
            b11 = lunarMonth11(year: year)
        } else {
            a11 = lunarMonth11(year: year)
            b11 = lunarMonth11(year: year + 1)
        }

        let k = floor(0.5 + (Double(a11) - 2415021.076998695) / 29.530588853)
        var offset = month - 11
        if offset < 0 { offset += 12 }

        if b11 - a11 > 365 {
            let leapOffset = leapMonthOffset(a11: a11)
            var leapMonth = leapOffset - 2
            if leapMonth < 0 { leapMonth += 12 }
            if isLeap && month != leapMonth { return nil }
            if isLeap || offset >= leapOffset { offset += 1 }
        } else if isLeap {
            return nil
        }

        let monthStart = newMoonDay(k: k + Double(offset))
        let nextMonthStart = newMoonDay(k: k + Double(offset) + 1)
        let monthLength = nextMonthStart - monthStart
        let resolvedDay = min(day, monthLength)
        return solarDate(fromJulianDay: monthStart + resolvedDay - 1)
    }

    private nonisolated static func solarDate(fromJulianDay jd: Int) -> SolarDate {
        let b: Int
        let c: Int
        if jd > 2299160 {
            let a = jd + 32044
            b = (4 * a + 3) / 146097
            c = a - (b * 146097) / 4
        } else {
            b = 0
            c = jd + 32082
        }
        let d = (4 * c + 3) / 1461
        let e = c - (1461 * d) / 4
        let m = (5 * e + 2) / 153
        let day = e - (153 * m + 2) / 5 + 1
        let month = m + 3 - 12 * (m / 10)
        let year = b * 100 + d - 4800 + m / 10
        return SolarDate(day: day, month: month, year: year)
    }

    static func solarToLunar(date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> LunarDate {
        let comps = calendar.dateComponents([.day, .month, .year], from: date)
        return solarToLunar(day: comps.day ?? 1, month: comps.month ?? 1, year: comps.year ?? 2000)
    }

    /// `true` when `date` is the last day of a short (29-day) lunar month, i.e. day 29 whose next
    /// solar day is day 1 of the following lunar month. `lunar` must be `solarToLunar(date:)` of `date`.
    /// Only day 29 triggers the extra conversion, so the cost is one extra call about once a month.
    static func isLastDayOfShortMonth(
        _ lunar: LunarDate,
        on date: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Bool {
        guard lunar.day == 29, let next = calendar.date(byAdding: .day, value: 1, to: date) else { return false }
        return solarToLunar(date: next, calendar: calendar).day == 1
    }

    /// Short-month rule for a recurring lunar day: a day-30 observance falls on day 29 when the
    /// lunar month has only 29 days. Any other target matches only its exact lunar day. Leap-month
    /// handling stays with the caller (see `isLeapMonthEligible`).
    static func matchesLunarDay(
        _ target: Int,
        lunar: LunarDate,
        on date: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Bool {
        if lunar.day == target { return true }
        return target == 30 && isLastDayOfShortMonth(lunar, on: date, calendar: calendar)
    }

    /// Chỉ số (0...11) của Thần Sát cai quản ngày trong vòng 12 Thần Sát (Thanh Long Hoàng Đạo):
    /// Thanh Long khởi tại `((lunarMonth - 1) % 6) * 2` rồi thuận hành; `dz = (jd + 1) % 12` là
    /// Địa Chi của ngày. Chỉ số này quyết định tên sao (`dayStarName`) và tốt/xấu (`isHoangDao`).
    static func dayStarIndex(solarDay: Int, solarMonth: Int, solarYear: Int, lunarMonth: Int) -> Int {
        let dz = (jdFromDate(day: solarDay, month: solarMonth, year: solarYear) + 1) % 12
        let shift = ((lunarMonth - 1) % 6) * 2
        return ((dz - shift) % 12 + 12) % 12
    }

    /// `true` nếu ngày là "Hoàng đạo" (ngày tốt), `false` nếu "Hắc đạo" (ngày xấu) — 12 Thần Sát
    /// (Thanh Long Hoàng Đạo): ngày tốt khi Địa Chi của ngày rơi vào 6 sao tốt `{0, 1, 4, 5, 8, 9}`
    /// (Thanh Long, Minh Đường, Kim Quỹ, Bảo Quang, Ngọc Đường, Tư Mệnh).
    static func isHoangDao(solarDay: Int, solarMonth: Int, solarYear: Int, lunarMonth: Int) -> Bool {
        isGoodDayStar(dayStarIndex(solarDay: solarDay, solarMonth: solarMonth, solarYear: solarYear, lunarMonth: lunarMonth))
    }

    /// `true` nếu chỉ số Thần Sát (0...11) là 1 trong 6 sao Hoàng đạo (ngày tốt).
    static func isGoodDayStar(_ index: Int) -> Bool {
        goodStarOffsets.contains(((index % 12) + 12) % 12)
    }

    /// Tên Thần Sát theo chỉ số 0...11 — 6 sao Hoàng đạo: Thanh Long (0), Minh Đường (1),
    /// Kim Quỹ (4), Bảo Quang (5), Ngọc Đường (8), Tư Mệnh (9); 6 sao Hắc đạo: Thiên Hình (2),
    /// Chu Tước (3), Bạch Hổ (6), Thiên Lao (7), Huyền Vũ (10), Câu Trần (11).
    static func dayStarName(_ index: Int) -> String {
        "lunarCalendar.star.\(((index % 12) + 12) % 12)".localized
    }

    // MARK: - Can Chi (Thiên Can – Địa Chi)

    /// Tên năm âm theo Can Chi — vd năm âm lịch 2024 -> "Giáp Thìn".
    static func canChiYear(_ lunarYear: Int) -> String {
        let can = "lunarCalendar.can.\(((lunarYear + 6) % 10 + 10) % 10)".localized
        let chi = "lunarCalendar.chi.\(((lunarYear + 8) % 12 + 12) % 12)".localized
        return String(format: "lunarCalendar.year.format".localized, can, chi)
    }

    /// "Tháng Bảy" — tháng nhuận thêm hậu tố "(nhuận)".
    static func lunarMonthLabel(_ month: Int, isLeap: Bool) -> String {
        let index = max(1, min(12, month))
        let name = "lunarCalendar.month.\(index)".localized
        let formatKey = isLeap ? "lunarCalendar.month.label.leap" : "lunarCalendar.month.label"
        return String(format: formatKey.localized, name)
    }

    // MARK: - Can Chi ngày/tháng & giờ hoàng đạo (dùng cho màn Chi tiết ngày âm)

    /// Tên Thiên Can theo chỉ số 0...9 (an toàn với mọi chỉ số nguyên).
    static func canName(_ index: Int) -> String {
        "lunarCalendar.can.\(((index % 10) + 10) % 10)".localized
    }

    /// Tên Địa Chi theo chỉ số 0...11 (an toàn với mọi chỉ số nguyên).
    static func chiName(_ index: Int) -> String {
        "lunarCalendar.chi.\(((index % 12) + 12) % 12)".localized
    }

    /// Chỉ số Thiên Can & Địa Chi (0-based) của 1 ngày dương:
    /// `can = (jd + 9) % 10`, `chi = (jd + 1) % 12`.
    static func dayCanChiIndices(day: Int, month: Int, year: Int) -> (can: Int, chi: Int) {
        let jd = jdFromDate(day: day, month: month, year: year)
        return (((jd + 9) % 10 + 10) % 10, ((jd + 1) % 12 + 12) % 12)
    }

    /// Tên Can Chi của 1 ngày dương — ví dụ "Giáp Tý".
    static func canChiDay(day: Int, month: Int, year: Int) -> String {
        let indices = dayCanChiIndices(day: day, month: month, year: year)
        return "\(canName(indices.can)) \(chiName(indices.chi))"
    }

    /// Tên Can Chi của 1 tháng âm:
    /// `can = (lunarYear*12 + lunarMonth + 3) % 10`, `chi = (lunarMonth + 1) % 12`.
    static func canChiMonth(lunarYear: Int, lunarMonth: Int) -> String {
        let can = ((lunarYear * 12 + lunarMonth + 3) % 10 + 10) % 10
        let chi = ((lunarMonth + 1) % 12 + 12) % 12
        return "\(canName(can)) \(chiName(chi))"
    }

    /// 6 vị trí "Hoàng đạo" trong vòng 12 Thần Sát (0-based): Thanh Long (0), Minh Đường (1),
    /// Kim Quỹ (4), Bảo Quang (5), Ngọc Đường (8), Tư Mệnh (9).
    private static let goodStarOffsets = [0, 1, 4, 5, 8, 9]

    /// Chỉ số Địa Chi (0...11) của 6 giờ hoàng đạo trong ngày, theo thứ tự giờ trong ngày.
    ///
    /// Quy tắc (12 Thần Sát áp cho giờ): Thanh Long khởi giờ theo Địa Chi của ngày rồi thuận hành:
    ///   Tý/Ngọ → Thân, Sửu/Mùi → Tuất, Dần/Thân → Tý, Mão/Dậu → Dần, Thìn/Tuất → Thìn, Tỵ/Hợi → Ngọ.
    /// Tức `start = ((chiNgay - 2) * 2) mod 12`; giờ tốt = `start + {0,1,4,5,8,9}` (mod 12).
    static func goodHourChiIndices(dayChiIndex: Int) -> [Int] {
        let chi = ((dayChiIndex % 12) + 12) % 12
        let start = (((chi - 2) * 2) % 12 + 12) % 12
        return goodStarOffsets.map { (start + $0) % 12 }.sorted()
    }

    /// Chỉ số Địa Chi của tuổi xung khắc trong ngày — chi đối xung (Lục Xung, cách 6 vị trí).
    static func clashChiIndex(dayChiIndex: Int) -> Int {
        ((dayChiIndex + 6) % 12 + 12) % 12
    }

    /// Chỉ số Thiên Can (0...9) của 2 tuổi xung khắc theo Can của ngày, xếp mạnh nhất trước:
    ///   +6: Thiên Can tương xung (Giáp–Canh, Ất–Tân, Bính–Nhâm, Đinh–Quý, Mậu–Giáp, Kỷ–Ất).
    ///   +4: Ngũ hành tương khắc (Mộc khắc Thổ, Hỏa khắc Kim, Thổ khắc Thủy, Kim khắc Mộc, Thủy khắc Hỏa).
    /// Ví dụ ngày Giáp (0) → Canh (6) và Mậu (4); ghép với `clashChiIndex` ra Canh Ngọ / Mậu Ngọ.
    static func clashCanIndices(dayCanIndex: Int) -> [Int] {
        let can = ((dayCanIndex % 10) + 10) % 10
        return [(can + 6) % 10, (can + 4) % 10]
    }

    /// Hướng Hỷ thần theo Thiên Can của ngày (0...9), theo cặp Can (mod 5):
    ///   Giáp/Kỷ → Đông Bắc, Ất/Canh → Tây Bắc, Bính/Tân → Tây Nam, Đinh/Nhâm → Nam, Mậu/Quý → Đông Nam.
    static func joyStarDirection(dayCanIndex: Int) -> String {
        joyStarDirectionKeys[((dayCanIndex % 5) + 5) % 5].localized
    }

    /// Hướng Tài thần theo Thiên Can của ngày (0...9):
    ///   Giáp/Ất → Đông Nam, Bính/Đinh → Đông, Mậu → Bắc, Kỷ → Nam,
    ///   Canh/Tân → Tây Nam, Nhâm → Tây, Quý → Tây Bắc.
    static func wealthStarDirection(dayCanIndex: Int) -> String {
        wealthStarDirectionKeys[((dayCanIndex % 10) + 10) % 10].localized
    }

    private static let joyStarDirectionKeys = [
        "lunarCalendar.direction.northeast", "lunarCalendar.direction.northwest",
        "lunarCalendar.direction.southwest", "lunarCalendar.direction.south",
        "lunarCalendar.direction.southeast"
    ]

    private static let wealthStarDirectionKeys = [
        "lunarCalendar.direction.southeast", "lunarCalendar.direction.southeast",
        "lunarCalendar.direction.east", "lunarCalendar.direction.east",
        "lunarCalendar.direction.north", "lunarCalendar.direction.south",
        "lunarCalendar.direction.southwest", "lunarCalendar.direction.southwest",
        "lunarCalendar.direction.west", "lunarCalendar.direction.northwest"
    ]

    // MARK: - Hạc thần (hướng xấu cần tránh khi xuất hành)

    /// Hướng Hạc thần — hướng xấu cần TRÁNH khi xuất hành — theo ngày Can Chi (chu kỳ 60 ngày).
    /// Trả `nil` khi Hạc thần "bận việc trên trời" (16 ngày trong chu kỳ) — hôm đó không có hướng
    /// phải tránh. 44 ngày còn lại Hạc thần đi tuần 8 hướng, mỗi hướng giữ 5–6 ngày liên tiếp.
    static func craneStarDirection(can: Int, chi: Int) -> String? {
        craneStarDirectionKeys[sexagenaryDayIndex(can: can, chi: chi)]?.localized
    }

    /// Chỉ số (0...59) của ngày trong chu kỳ Can Chi 60 ngày — Giáp Tý = 0 … Quý Hợi = 59.
    static func sexagenaryDayIndex(can: Int, chi: Int) -> Int {
        let c = ((can % 10) + 10) % 10
        let z = ((chi % 12) + 12) % 12
        for n in 0..<60 where n % 10 == c && n % 12 == z {
            return n
        }
        return 0
    }

    /// Bảng tra Hạc thần theo chỉ số ngày Can Chi (0...59). `nil` = Hạc thần bận việc trên trời
    /// (16 ngày liên tiếp: Quý Tỵ … Mậu Thân), hôm đó không có hướng phải tránh. Nguồn quy ước:
    /// "1001 Kiêng Kỵ Trong Tín Ngưỡng Dân Gian" (Thanh Hóa, 2010).
    private static let craneStarDirectionKeys: [String?] = [
        // 0–1  Giáp Tý, Ất Sửu → Đông Nam
        "lunarCalendar.direction.southeast", "lunarCalendar.direction.southeast",
        // 2–6  Bính Dần … Canh Ngọ → Nam
        "lunarCalendar.direction.south", "lunarCalendar.direction.south",
        "lunarCalendar.direction.south", "lunarCalendar.direction.south",
        "lunarCalendar.direction.south",
        // 7–12 Tân Mùi … Bính Tý → Tây Nam
        "lunarCalendar.direction.southwest", "lunarCalendar.direction.southwest",
        "lunarCalendar.direction.southwest", "lunarCalendar.direction.southwest",
        "lunarCalendar.direction.southwest", "lunarCalendar.direction.southwest",
        // 13–17 Đinh Sửu … Tân Tỵ → Tây
        "lunarCalendar.direction.west", "lunarCalendar.direction.west",
        "lunarCalendar.direction.west", "lunarCalendar.direction.west",
        "lunarCalendar.direction.west",
        // 18–23 Nhâm Ngọ … Đinh Hợi → Tây Bắc
        "lunarCalendar.direction.northwest", "lunarCalendar.direction.northwest",
        "lunarCalendar.direction.northwest", "lunarCalendar.direction.northwest",
        "lunarCalendar.direction.northwest", "lunarCalendar.direction.northwest",
        // 24–28 Mậu Tý … Nhâm Thìn → Bắc
        "lunarCalendar.direction.north", "lunarCalendar.direction.north",
        "lunarCalendar.direction.north", "lunarCalendar.direction.north",
        "lunarCalendar.direction.north",
        // 29–44 Quý Tỵ … Mậu Thân → Hạc thần bận việc trên trời (không có hướng tránh)
        nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil,
        // 45–50 Kỷ Dậu … Giáp Dần → Đông Bắc
        "lunarCalendar.direction.northeast", "lunarCalendar.direction.northeast",
        "lunarCalendar.direction.northeast", "lunarCalendar.direction.northeast",
        "lunarCalendar.direction.northeast", "lunarCalendar.direction.northeast",
        // 51–55 Ất Mão … Kỷ Mùi → Đông
        "lunarCalendar.direction.east", "lunarCalendar.direction.east",
        "lunarCalendar.direction.east", "lunarCalendar.direction.east",
        "lunarCalendar.direction.east",
        // 56–59 Canh Thân … Quý Hợi → Đông Nam
        "lunarCalendar.direction.southeast", "lunarCalendar.direction.southeast",
        "lunarCalendar.direction.southeast", "lunarCalendar.direction.southeast"
    ]

    // MARK: - Tiết khí (24 solar terms)

    /// Index (0...23) of the solar term (Tiết khí) governing a solar day — the Sun's ecliptic
    /// longitude split into 24 segments of 15°. Index `0` = Xuân Phân (0°), advancing forward along
    /// the ecliptic. Same astronomy as `sunLongitudeIndex` (the 12 major terms) but at 24-segment
    /// resolution. Used by the almanac engine for the `solarTerm` field.
    static func solarTermIndex(solarDay: Int, solarMonth: Int, solarYear: Int) -> Int {
        solarTermIndex(jdn: jdFromDate(day: solarDay, month: solarMonth, year: solarYear))
    }

    private static func solarTermIndex(jdn: Int) -> Int {
        let longitude = sunLongitude(Double(jdn) - 0.5 - timeZone / 24)
        let raw = Int(floor(longitude / Double.pi * 12))
        return ((raw % 24) + 24) % 24
    }

    /// Localized name of the 24 solar terms (index 0 = Xuân Phân … 23 = Kinh Trập).
    static func solarTermName(_ index: Int) -> String {
        "lunarCalendar.solarTerm.\(((index % 24) + 24) % 24)".localized
    }

    // MARK: - 12 Trực (Kiến, Trừ, …)

    /// Index (0...11) of the day's Trực (12 Trực). The "Kiến" branch of lunar month `M` is
    /// `ChiKien = (M + 1) % 12` (tháng Giêng Kiến Dần, tháng Hai Kiến Mão, …), then the day's
    /// Trực advances with the day's Địa Chi: `truc = (ChiDay - ChiKien + 12) % 12`.
    static func trucIndex(solarDay: Int, solarMonth: Int, solarYear: Int, lunarMonth: Int) -> Int {
        let chiDay = ((jdFromDate(day: solarDay, month: solarMonth, year: solarYear) + 1) % 12 + 12) % 12
        let chiKien = (lunarMonth + 1) % 12
        return ((chiDay - chiKien) % 12 + 12) % 12
    }

    /// Localized name of the 12 Trực (index 0 = Kiến … 11 = Bế).
    static func trucName(_ index: Int) -> String {
        "lunarCalendar.truc.\(((index % 12) + 12) % 12)".localized
    }

    // MARK: - 28 Tú (Nhị thập bát tú)

    /// Index (0...27) of the day's 28 Tú (lunar mansion), `0` = Giác. Convention `(JD + 9) % 28`,
    /// the same anchoring family as the day Can-Chi (`(JD + 9) % 10`). This anchor follows the
    /// common Vietnamese lịch convention but should be re-checked against an authoritative lịch vạn
    /// niên before any "kiêng kỵ theo sao" copy is shipped.
    static func star28Index(solarDay: Int, solarMonth: Int, solarYear: Int) -> Int {
        let jd = jdFromDate(day: solarDay, month: solarMonth, year: solarYear)
        return ((jd + 9) % 28 + 28) % 28
    }

    /// Localized name of the 28 Tú (index 0 = Giác … 27 = Chẩn).
    static func star28Name(_ index: Int) -> String {
        "lunarCalendar.star28.\(((index % 28) + 28) % 28)".localized
    }

    // MARK: - Almanac (unified day computation, optionally personalized)

    /// Complete per-day almanac result. `isPersonalized` is `false` — and the Hung/Cát fields are the
    /// general (universal) day evaluation — when no birth date was supplied to `almanac(...)`.
    struct AlmanacResult: Equatable {
        let lunarDay: Int
        let lunarMonth: Int
        let lunarYear: Int
        let canChiDay: String
        let canChiMonth: String
        let canChiYear: String
        let solarTerm: String
        let isHoangDao: Bool
        let hoangDaoDeity: String
        let truc: String
        let star28: String
        let hoangDaoHours: [String]
        let hyThanDirection: String
        let taiThanDirection: String
        let isPersonalized: Bool
        let personalTier: ILAuspiciousTier
        let personalScore: Int
        let compatibilitySummary: String
        let recommendedDos: [String]
        let recommendedDonts: [String]
    }

    /// Computes the full day almanac for a solar date. Pass the birth date (day/month/year, optional)
    /// to personalize the Hung/Cát fields; omit it (`nil`) for the general (universal) day evaluation.
    static func almanac(
        day: Int, month: Int, year: Int,
        birthDay: Int?, birthMonth: Int?, birthYear: Int?
    ) -> AlmanacResult {
        let lunar = solarToLunar(day: day, month: month, year: year)
        let indices = dayCanChiIndices(day: day, month: month, year: year)
        let starIndex = dayStarIndex(solarDay: day, solarMonth: month, solarYear: year, lunarMonth: lunar.month)
        let isHoangDao = isGoodDayStar(starIndex)
        let trucIndex = trucIndex(solarDay: day, solarMonth: month, solarYear: year, lunarMonth: lunar.month)

        let dayElement = napAmElement(can: indices.can, chi: indices.chi)

        // Derive the user's age branch + mệnh from the birth date, when provided.
        var userChiIndex: Int?
        var userElement: ILFiveElements?
        if let birthDay, let birthMonth, let birthYear {
            let birthLunar = solarToLunar(day: birthDay, month: birthMonth, year: birthYear)
            let userCan = ((birthLunar.year + 6) % 10 + 10) % 10
            let userChi = ((birthLunar.year + 8) % 12 + 12) % 12
            userChiIndex = userChi
            userElement = napAmElement(can: userCan, chi: userChi)
        }

        let personal = personalEvaluation(
            dayChiIndex: indices.chi,
            dayElement: dayElement,
            isHoangDao: isHoangDao,
            userChiIndex: userChiIndex,
            userElement: userElement
        )
        let actions = evaluateActions(tier: personal.tier, trucIndex: trucIndex)

        return AlmanacResult(
            lunarDay: lunar.day,
            lunarMonth: lunar.month,
            lunarYear: lunar.year,
            canChiDay: canChiDay(day: day, month: month, year: year),
            canChiMonth: canChiMonth(lunarYear: lunar.year, lunarMonth: lunar.month),
            canChiYear: canChiYear(lunar.year),
            solarTerm: solarTermName(solarTermIndex(solarDay: day, solarMonth: month, solarYear: year)),
            isHoangDao: isHoangDao,
            hoangDaoDeity: dayStarName(starIndex),
            truc: trucName(trucIndex),
            star28: star28Name(star28Index(solarDay: day, solarMonth: month, solarYear: year)),
            hoangDaoHours: goodHourChiIndices(dayChiIndex: indices.chi).map { chiName($0) },
            hyThanDirection: joyStarDirection(dayCanIndex: indices.can),
            taiThanDirection: wealthStarDirection(dayCanIndex: indices.can),
            isPersonalized: userChiIndex != nil,
            personalTier: personal.tier,
            personalScore: personal.score,
            compatibilitySummary: personal.reasons.joined(separator: " · "),
            recommendedDos: actions.dos,
            recommendedDonts: actions.donts
        )
    }

    /// `Date` convenience for `almanac(day:month:year:birthDay:birthMonth:birthYear:)`.
    static func almanac(
        date: Date,
        birthDate: Date?,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> AlmanacResult {
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        let birthComponents = birthDate.map { calendar.dateComponents([.day, .month, .year], from: $0) }
        return almanac(
            day: components.day ?? 1, month: components.month ?? 1, year: components.year ?? 2000,
            birthDay: birthComponents?.day, birthMonth: birthComponents?.month, birthYear: birthComponents?.year
        )
    }

    // MARK: - Nạp Âm + personal matcher + rules dispatcher

    /// The Nạp Âm element of a Can-Chi pair, from the 60-Jiazi cycle grouped into 30 pairs.
    static func napAmElement(can: Int, chi: Int) -> ILFiveElements {
        napAmElements[sexagenaryDayIndex(can: can, chi: chi) / 2]
    }

    /// Localized Nạp Âm name (30 names, Jiazi-pair order: Hải Trung Kim … Đại Hải Thủy) of a
    /// Can-Chi pair — used by the "Ngũ hành & nạp âm" section of the lunar day detail screen.
    static func napAmName(can: Int, chi: Int) -> String {
        "lunarCalendar.napAm.\((sexagenaryDayIndex(can: can, chi: chi) / 2) % 30)".localized
    }

    /// Localized display name of a Ngũ Hành element ("Kim", "Thủy", "Mộc", "Hỏa", "Thổ").
    static func elementName(_ element: ILFiveElements) -> String {
        "lunarCalendar.element.\(element.rawValue)".localized
    }

    /// Fixed Ngũ Hành of a Thiên Can (0 = Giáp … 9 = Quý): Giáp/Ất Mộc, Bính/Đinh Hỏa,
    /// Mậu/Kỷ Thổ, Canh/Tân Kim, Nhâm/Quý Thủy.
    static func canElement(_ can: Int) -> ILFiveElements {
        let c = ((can % 10) + 10) % 10
        return [.moc, .moc, .hoa, .hoa, .tho, .tho, .kim, .kim, .thuy, .thuy][c]
    }

    /// Fixed Ngũ Hành of a Địa Chi (0 = Tý … 11 = Hợi): Tý/Hợi Thủy, Sửu/Thìn/Mùi/Tuất Thổ,
    /// Dần/Mão Mộc, Tỵ/Ngọ Hỏa, Thân/Dậu Kim.
    static func chiElement(_ chi: Int) -> ILFiveElements {
        let z = ((chi % 12) + 12) % 12
        return [.thuy, .tho, .moc, .moc, .tho, .hoa, .hoa, .tho, .kim, .kim, .tho, .thuy][z]
    }

    /// Computes the score (0–100) and tier from the day's Địa Chi + Nạp Âm element, the day's
    /// Hoàng đạo/Hắc đạo flag, and — optionally — the user's age branch + mệnh element.
    ///
    /// When `userChiIndex`/`userElement` are `nil` (no birth profile), the personal Địa Chi and Ngũ
    /// Hành steps are skipped and only the Thần Sát signal remains — the "general" day evaluation.
    ///
    /// Base score 50, then:
    ///   1. Địa Chi — Lục Xung (distance 6) `-40`; Tam Hợp `((day - user) mod 4 == 0, ≠ 0)` `+25`;
    ///      Nhị Hợp `((day + user) mod 12 == 1)` `+20`.
    ///   2. Ngũ Hành — Sinh nhập (day generates mệnh) `+20`; Khắc xuất (mệnh khắc day) `-5`;
    ///      Khắc nhập (day khắc mệnh) `-25`; Đồng hành `+10`. Sinh xuất (mệnh sinh day) is neutral.
    ///   3. Thần Sát — Hoàng đạo `+10`, Hắc đạo `-10`.
    /// Clamped to 0–100.
    static func personalEvaluation(
        dayChiIndex: Int,
        dayElement: ILFiveElements,
        isHoangDao: Bool,
        userChiIndex: Int?,
        userElement: ILFiveElements?
    ) -> (score: Int, tier: ILAuspiciousTier, reasons: [String]) {
        var score = 50
        var reasons: [String] = []

        // 1. Địa Chi relation (Lục Xung / Tam Hợp / Nhị Hợp are mutually exclusive).
        if let userChiIndex {
            let distance = abs(dayChiIndex - userChiIndex)
            let isTamHop = ((dayChiIndex - userChiIndex) % 4 + 4) % 4 == 0 && dayChiIndex != userChiIndex
            let isNhiHop = (dayChiIndex + userChiIndex) % 12 == 1

            if distance == 6 {
                score -= 40
                reasons.append("almanac.reason.lucXung".localized)
            } else if isTamHop {
                score += 25
                reasons.append("almanac.reason.tamHop".localized)
            } else if isNhiHop {
                score += 20
                reasons.append("almanac.reason.nhiHop".localized)
            }
        }

        // 2. Ngũ Hành Nạp Âm relation.
        if let userElement {
            if dayElement.generates == userElement {
                score += 20
                reasons.append("almanac.reason.sinhNhap".localized)
            } else if userElement.overcomes == dayElement {
                score -= 5
                reasons.append("almanac.reason.khacXuat".localized)
            } else if dayElement.overcomes == userElement {
                score -= 25
                reasons.append("almanac.reason.khacNhap".localized)
            } else if dayElement == userElement {
                score += 10
                reasons.append("almanac.reason.dongHanh".localized)
            }
            // else: userElement.generates == dayElement → "Sinh xuất", neutral (no score change).
        }

        // 3. Thần Sát ngày — always applied.
        if isHoangDao {
            score += 10
            reasons.append("almanac.reason.hoangDao".localized)
        } else {
            score -= 10
            reasons.append("almanac.reason.hacDao".localized)
        }

        score = max(0, min(100, score))
        return (score, tier(for: score), reasons)
    }

    /// Maps a clamped 0–100 score to its `ILAuspiciousTier`.
    static func tier(for score: Int) -> ILAuspiciousTier {
        switch score {
        case 85...100: return .daiCat
        case 70...84: return .trungCat
        case 55...69: return .tieuCat
        case 45...54: return .binhHoa
        case 30...44: return .tieuHung
        case 15...29: return .hung
        default: return .daiHung
        }
    }

    /// Maps the day's Trực (index 0...11) and tier to recommended do/don't lists. Action keys are
    /// resolved to `.localized` strings only after dedup so the HUNG/DAI_HUNG override can filter by
    /// stable key rather than localized text.
    static func evaluateActions(tier: ILAuspiciousTier, trucIndex: Int) -> (dos: [String], donts: [String]) {
        var dos: [String] = []
        var donts: [String] = []

        switch trucIndex {
        case 8, 10: // Thành, Khai
            dos += [Action.khaiTruong, Action.xuatHanh, Action.nhapTrach, Action.kyKetGiaoDich]
            donts += [Action.kienTung, Action.tranhChap]
        case 4: // Định
            dos += [Action.cungTeCauAn, Action.gapGoDoiTac, Action.dinhHon]
            donts += [Action.khoiTo, Action.diXa]
        case 6: // Phá
            dos += [Action.phaDoNhaCu, Action.chuaBenh, Action.donDep]
            donts += [Action.khoiCong, Action.cuoiHoi, Action.moCuaHang, Action.kyHopDong]
        case 11: // Bế
            dos += [Action.anTang, Action.dapDap, Action.tuBoPhanMo]
            donts += [Action.khaoKhatMuuSuLon, Action.khaiTruong, Action.xuatHanh]
        default:
            dos += [Action.lamViecThien, Action.tungKinhCauBinhAn, Action.boThi]
        }

        // Override for strongly inauspicious tiers: demote major undertakings to warnings and steer
        // toward calming practices.
        if tier == .hung || tier == .daiHung {
            let major: Set<String> = [Action.khaiTruong, Action.kyKetGiaoDich, Action.xuatHanh, Action.nhapTrach]
            donts += dos.filter { major.contains($0) }
            dos.removeAll { major.contains($0) }

            dos += [Action.tinhTam, Action.thienDinh, Action.triChuCauAn, Action.donDepNhaCua]
            donts += [Action.muuTinhDaiSu, Action.giaoDichTaiChinhLon, Action.tranhLuan]
        }

        return (
            dos: uniquePreservingOrder(dos).map(\.localized),
            donts: uniquePreservingOrder(donts).map(\.localized)
        )
    }

    private static func uniquePreservingOrder(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }

    /// The 30 Nạp Âm elements in Jiazi-pair order: Hải Trung Kim … Đại Hải Thủy.
    private static let napAmElements: [ILFiveElements] = [
        .kim, .hoa, .moc, .tho, .kim,
        .hoa, .thuy, .tho, .kim, .moc,
        .thuy, .tho, .hoa, .moc, .thuy,
        .kim, .hoa, .moc, .tho, .kim,
        .hoa, .thuy, .tho, .kim, .moc,
        .thuy, .tho, .hoa, .moc, .thuy
    ]

    /// Stable localization keys for recommended/avoided actions.
    private enum Action {
        static let khaiTruong = "almanac.action.khaiTruong"
        static let xuatHanh = "almanac.action.xuatHanh"
        static let nhapTrach = "almanac.action.nhapTrach"
        static let kyKetGiaoDich = "almanac.action.kyKetGiaoDich"
        static let kienTung = "almanac.action.kienTung"
        static let tranhChap = "almanac.action.tranhChap"
        static let cungTeCauAn = "almanac.action.cungTeCauAn"
        static let gapGoDoiTac = "almanac.action.gapGoDoiTac"
        static let dinhHon = "almanac.action.dinhHon"
        static let khoiTo = "almanac.action.khoiTo"
        static let diXa = "almanac.action.diXa"
        static let phaDoNhaCu = "almanac.action.phaDoNhaCu"
        static let chuaBenh = "almanac.action.chuaBenh"
        static let donDep = "almanac.action.donDep"
        static let khoiCong = "almanac.action.khoiCong"
        static let cuoiHoi = "almanac.action.cuoiHoi"
        static let moCuaHang = "almanac.action.moCuaHang"
        static let kyHopDong = "almanac.action.kyHopDong"
        static let anTang = "almanac.action.anTang"
        static let dapDap = "almanac.action.dapDap"
        static let tuBoPhanMo = "almanac.action.tuBoPhanMo"
        static let khaoKhatMuuSuLon = "almanac.action.khaoKhatMuuSuLon"
        static let lamViecThien = "almanac.action.lamViecThien"
        static let tungKinhCauBinhAn = "almanac.action.tungKinhCauBinhAn"
        static let boThi = "almanac.action.boThi"
        static let tinhTam = "almanac.action.tinhTam"
        static let thienDinh = "almanac.action.thienDinh"
        static let triChuCauAn = "almanac.action.triChuCauAn"
        static let donDepNhaCua = "almanac.action.donDepNhaCua"
        static let muuTinhDaiSu = "almanac.action.muuTinhDaiSu"
        static let giaoDichTaiChinhLon = "almanac.action.giaoDichTaiChinhLon"
        static let tranhLuan = "almanac.action.tranhLuan"
    }
}

/// The five elements (Ngũ Hành). Raw value is the stable storage string (`"kim"`, `"thuy"`, …) so it
/// round-trips through Core Data as a `String`, mirroring `ILBuddhistTradition`.
enum ILFiveElements: String, CaseIterable, Equatable {
    case kim
    case thuy
    case moc
    case hoa
    case tho

    /// Position in the generating cycle Kim → Thủy → Mộc → Hỏa → Thổ (→ Kim).
    var cycleIndex: Int {
        switch self {
        case .kim: return 0
        case .thuy: return 1
        case .moc: return 2
        case .hoa: return 3
        case .tho: return 4
        }
    }

    private static func element(cycleIndex: Int) -> ILFiveElements {
        let ordered: [ILFiveElements] = [.kim, .thuy, .moc, .hoa, .tho]
        return ordered[((cycleIndex % 5) + 5) % 5]
    }

    /// The element this one generates (Sinh xuất).
    var generates: ILFiveElements { Self.element(cycleIndex: cycleIndex + 1) }

    /// The element this one overcomes (Khắc xuất): Kim → Mộc, Mộc → Thổ, Thổ → Thủy, Thủy → Hỏa,
    /// Hỏa → Kim.
    var overcomes: ILFiveElements { Self.element(cycleIndex: cycleIndex + 2) }
}

/// Auspicious/inauspicious tier derived from a score 0–100 (see `ILLunarCalendar.tier(for:)`).
enum ILAuspiciousTier: Int, CaseIterable, Equatable {
    case daiCat
    case trungCat
    case tieuCat
    case binhHoa
    case tieuHung
    case hung
    case daiHung
}
