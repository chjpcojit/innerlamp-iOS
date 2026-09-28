//
//  ILAlmanacUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILAlmanacUseCaseTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let sut = ILAlmanacUseCaseImpl()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func eval(
        dayChi: Int,
        dayEl: ILFiveElements,
        hoangDao: Bool,
        userChi: Int,
        userEl: ILFiveElements
    ) -> (score: Int, tier: ILAuspiciousTier, reasons: [String]) {
        ILLunarCalendar.personalEvaluation(
            dayChiIndex: dayChi,
            dayElement: dayEl,
            isHoangDao: hoangDao,
            userChiIndex: userChi,
            userElement: userEl
        )
    }

    // MARK: - Birth profile

    func test_makeBirthProfile_tet2024Birthday() {
        // 10/2/2024 = Tết Giáp Thìn (lunar 2024). Year can = Giáp (0), chi = Thìn (4),
        // Nạp Âm = Phú Đăng Hỏa (Hỏa).
        let profile = sut.makeBirthProfile(solarBirthDate: date(2024, 2, 10))

        XCTAssertEqual(profile.lunarYear, 2024)
        XCTAssertEqual(profile.canIndex, 0)
        XCTAssertEqual(profile.chiIndex, 4)
        XCTAssertEqual(profile.element, .hoa)
    }

    func test_makeBirthProfile_yearIndicesAreSelfConsistent() {
        let profile = sut.makeBirthProfile(solarBirthDate: date(1990, 7, 15))

        let expectedCan = ((profile.lunarYear + 6) % 10 + 10) % 10
        let expectedChi = ((profile.lunarYear + 8) % 12 + 12) % 12
        XCTAssertEqual(profile.canIndex, expectedCan)
        XCTAssertEqual(profile.chiIndex, expectedChi)
        XCTAssertEqual(
            profile.element,
            ILLunarCalendar.napAmElement(can: expectedCan, chi: expectedChi)
        )
    }

    // MARK: - Nạp Âm

    func test_napAmElement_knownPairs() {
        XCTAssertEqual(ILLunarCalendar.napAmElement(can: 0, chi: 0), .kim)   // Giáp Tý → Hải Trung Kim
        XCTAssertEqual(ILLunarCalendar.napAmElement(can: 1, chi: 1), .kim)   // Ất Sửu → Hải Trung Kim
        XCTAssertEqual(ILLunarCalendar.napAmElement(can: 2, chi: 2), .hoa)   // Bính Dần → Lư Trung Hỏa
        XCTAssertEqual(ILLunarCalendar.napAmElement(can: 6, chi: 6), .tho)   // Canh Ngọ → Lộ Bàng Thổ
        XCTAssertEqual(ILLunarCalendar.napAmElement(can: 9, chi: 11), .thuy) // Quý Hợi → Đại Hải Thủy
    }

    // MARK: - Personal matcher — Địa Chi

    func test_personalEvaluation_lucXung_penalty() {
        // Tý (0) xung Ngọ (6). Nạp Âm trung tính (Kim sinh Thủy = sinh xuất), ngày hoàng đạo.
        let result = eval(dayChi: 0, dayEl: .thuy, hoangDao: true, userChi: 6, userEl: .kim)

        XCTAssertEqual(result.score, 20) // 50 - 40 + 0 + 10
        XCTAssertEqual(result.tier, .hung)
        XCTAssertTrue(result.reasons.contains("almanac.reason.lucXung".localized))
    }

    func test_personalEvaluation_tamHop_bonus() {
        // Thân (8) hợp Tý (0) trong Tam Hợp Thủy cục.
        let result = eval(dayChi: 8, dayEl: .thuy, hoangDao: true, userChi: 0, userEl: .kim)

        XCTAssertEqual(result.score, 85) // 50 + 25 + 0 + 10
        XCTAssertEqual(result.tier, .daiCat)
        XCTAssertTrue(result.reasons.contains("almanac.reason.tamHop".localized))
    }

    func test_personalEvaluation_nhiHop_bonus() {
        // Tý (0) nhị hợp Sửu (1).
        let result = eval(dayChi: 0, dayEl: .thuy, hoangDao: true, userChi: 1, userEl: .kim)

        XCTAssertEqual(result.score, 80) // 50 + 20 + 0 + 10
        XCTAssertEqual(result.tier, .trungCat)
        XCTAssertTrue(result.reasons.contains("almanac.reason.nhiHop".localized))
    }

    func test_personalEvaluation_sameChi_hasNoChiAdjustment() {
        // Same age branch → no Lục Xung / Tam Hợp / Nhị Hợp.
        let result = eval(dayChi: 3, dayEl: .thuy, hoangDao: false, userChi: 3, userEl: .kim)

        XCTAssertEqual(result.score, 40) // 50 + 0 + 0 - 10
        XCTAssertEqual(result.tier, .tieuHung)
    }

    // MARK: - Personal matcher — Ngũ Hành Nạp Âm

    func test_personalEvaluation_sinhNhap_bonus() {
        // Thổ sinh Kim: day .tho generates user .kim. Same chi, hoàng đạo.
        let result = eval(dayChi: 3, dayEl: .tho, hoangDao: true, userChi: 3, userEl: .kim)

        XCTAssertEqual(result.score, 80) // 50 + 20 + 10
        XCTAssertTrue(result.reasons.contains("almanac.reason.sinhNhap".localized))
    }

    func test_personalEvaluation_khacNhap_penalty() {
        // Hỏa khắc Kim: day .hoa overcomes user .kim. Same chi, hoàng đạo.
        let result = eval(dayChi: 3, dayEl: .hoa, hoangDao: true, userChi: 3, userEl: .kim)

        XCTAssertEqual(result.score, 35) // 50 - 25 + 10
        XCTAssertEqual(result.tier, .tieuHung)
        XCTAssertTrue(result.reasons.contains("almanac.reason.khacNhap".localized))
    }

    func test_personalEvaluation_khacXuat_penalty() {
        // Kim khắc Mộc: user .kim overcomes day .moc. Same chi, hoàng đạo.
        let result = eval(dayChi: 3, dayEl: .moc, hoangDao: true, userChi: 3, userEl: .kim)

        XCTAssertEqual(result.score, 55) // 50 - 5 + 10
        XCTAssertEqual(result.tier, .tieuCat)
        XCTAssertTrue(result.reasons.contains("almanac.reason.khacXuat".localized))
    }

    func test_personalEvaluation_dongHanh_bonus() {
        let result = eval(dayChi: 3, dayEl: .kim, hoangDao: true, userChi: 3, userEl: .kim)

        XCTAssertEqual(result.score, 70) // 50 + 10 + 10
        XCTAssertTrue(result.reasons.contains("almanac.reason.dongHanh".localized))
    }

    // MARK: - Tier thresholds

    func test_tier_thresholds() {
        let expectations: [(Int, ILAuspiciousTier)] = [
            (100, .daiCat), (85, .daiCat),
            (84, .trungCat), (70, .trungCat),
            (69, .tieuCat), (55, .tieuCat),
            (54, .binhHoa), (45, .binhHoa),
            (44, .tieuHung), (30, .tieuHung),
            (29, .hung), (15, .hung),
            (14, .daiHung), (0, .daiHung)
        ]
        for (score, tier) in expectations {
            XCTAssertEqual(ILLunarCalendar.tier(for: score), tier, "score \(score)")
        }
    }

    // MARK: - Rules dispatcher

    func test_evaluateActions_khaiAndThanh() {
        for trucIndex in [8, 10] {
            let result = ILLunarCalendar.evaluateActions(tier: .daiCat, trucIndex: trucIndex)
            XCTAssertTrue(result.dos.contains("almanac.action.khaiTruong".localized), "truc \(trucIndex)")
            XCTAssertTrue(result.dos.contains("almanac.action.xuatHanh".localized))
            XCTAssertTrue(result.donts.contains("almanac.action.kienTung".localized))
        }
    }

    func test_evaluateActions_dinh() {
        let result = ILLunarCalendar.evaluateActions(tier: .daiCat, trucIndex: 4)
        XCTAssertTrue(result.dos.contains("almanac.action.cungTeCauAn".localized))
        XCTAssertTrue(result.dos.contains("almanac.action.dinhHon".localized))
        XCTAssertTrue(result.donts.contains("almanac.action.khoiTo".localized))
    }

    func test_evaluateActions_pha() {
        let result = ILLunarCalendar.evaluateActions(tier: .daiCat, trucIndex: 6)
        XCTAssertTrue(result.dos.contains("almanac.action.phaDoNhaCu".localized))
        XCTAssertTrue(result.donts.contains("almanac.action.khoiCong".localized))
        XCTAssertTrue(result.donts.contains("almanac.action.cuoiHoi".localized))
    }

    func test_evaluateActions_be() {
        let result = ILLunarCalendar.evaluateActions(tier: .daiCat, trucIndex: 11)
        XCTAssertTrue(result.dos.contains("almanac.action.anTang".localized))
        XCTAssertTrue(result.donts.contains("almanac.action.khaiTruong".localized))
    }

    func test_evaluateActions_default_fallsBackToMerit() {
        let result = ILLunarCalendar.evaluateActions(tier: .daiCat, trucIndex: 0)
        XCTAssertTrue(result.dos.contains("almanac.action.lamViecThien".localized))
        XCTAssertTrue(result.dos.contains("almanac.action.tungKinhCauBinhAn".localized))
        XCTAssertTrue(result.dos.contains("almanac.action.boThi".localized))
    }

    func test_evaluateActions_hungOverride_demotesMajorActions() {
        let result = ILLunarCalendar.evaluateActions(tier: .hung, trucIndex: 10) // Khai

        let major = [
            "almanac.action.khaiTruong", "almanac.action.kyKetGiaoDich",
            "almanac.action.xuatHanh", "almanac.action.nhapTrach"
        ].map(\.localized)

        for action in major {
            XCTAssertFalse(result.dos.contains(action), "\(action) must move from dos to donts")
            XCTAssertTrue(result.donts.contains(action), "\(action) must be warned against")
        }

        XCTAssertTrue(result.dos.contains("almanac.action.tinhTam".localized))
        XCTAssertTrue(result.dos.contains("almanac.action.thienDinh".localized))
        XCTAssertTrue(result.donts.contains("almanac.action.giaoDichTaiChinhLon".localized))
    }

    // MARK: - Full pipeline

    func test_calculateDailyAlmanac_populatesEveryFieldConsistently() {
        let profile = sut.makeBirthProfile(solarBirthDate: date(1990, 7, 15))
        let entity = sut.calculateDailyAlmanac(for: date(2024, 9, 17), profile: profile)

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month, .year], from: date(2024, 9, 17))
        let solarDay = components.day!
        let solarMonth = components.month!
        let solarYear = components.year!
        let lunar = ILLunarCalendar.solarToLunar(day: solarDay, month: solarMonth, year: solarYear)
        let indices = ILLunarCalendar.dayCanChiIndices(day: solarDay, month: solarMonth, year: solarYear)

        XCTAssertEqual(entity.lunarDay, lunar.day)
        XCTAssertEqual(entity.lunarMonth, lunar.month)
        XCTAssertEqual(entity.lunarYear, lunar.year)

        XCTAssertEqual(entity.canChiDay, ILLunarCalendar.canChiDay(day: solarDay, month: solarMonth, year: solarYear))
        XCTAssertEqual(entity.canChiMonth, ILLunarCalendar.canChiMonth(lunarYear: lunar.year, lunarMonth: lunar.month))
        XCTAssertEqual(entity.canChiYear, ILLunarCalendar.canChiYear(lunar.year))

        XCTAssertEqual(entity.solarTerm, ILLunarCalendar.solarTermName(
            ILLunarCalendar.solarTermIndex(solarDay: solarDay, solarMonth: solarMonth, solarYear: solarYear)
        ))
        XCTAssertEqual(entity.isHoangDao, ILLunarCalendar.isHoangDao(
            solarDay: solarDay, solarMonth: solarMonth, solarYear: solarYear, lunarMonth: lunar.month
        ))
        let starIndex = ILLunarCalendar.dayStarIndex(
            solarDay: solarDay, solarMonth: solarMonth, solarYear: solarYear, lunarMonth: lunar.month
        )
        XCTAssertEqual(entity.hoangDaoDeity, ILLunarCalendar.dayStarName(starIndex))
        XCTAssertEqual(entity.truc, ILLunarCalendar.trucName(ILLunarCalendar.trucIndex(
            solarDay: solarDay, solarMonth: solarMonth, solarYear: solarYear, lunarMonth: lunar.month
        )))
        XCTAssertEqual(entity.star28, ILLunarCalendar.star28Name(
            ILLunarCalendar.star28Index(solarDay: solarDay, solarMonth: solarMonth, solarYear: solarYear)
        ))

        XCTAssertEqual(entity.hoangDaoHours.count, 6)
        XCTAssertEqual(entity.hyThanDirection, ILLunarCalendar.joyStarDirection(dayCanIndex: indices.can))
        XCTAssertEqual(entity.taiThanDirection, ILLunarCalendar.wealthStarDirection(dayCanIndex: indices.can))

        XCTAssertTrue((0...100).contains(entity.personalScore))
        XCTAssertEqual(entity.personalTier, ILLunarCalendar.tier(for: entity.personalScore))
        XCTAssertTrue(entity.isPersonalized)
        XCTAssertFalse(entity.compatibilitySummary.isEmpty)
        XCTAssertFalse(entity.recommendedDos.isEmpty)
        XCTAssertFalse(entity.recommendedDonts.isEmpty)
    }

    func test_calculateDailyAlmanac_withoutProfile_isGeneral() {
        let entity = sut.calculateDailyAlmanac(for: date(2024, 9, 17), profile: nil)

        XCTAssertFalse(entity.isPersonalized)
        XCTAssertEqual(entity.personalScore, entity.isHoangDao ? 60 : 40)
        XCTAssertEqual(entity.personalTier, ILLunarCalendar.tier(for: entity.personalScore))
        XCTAssertFalse(entity.compatibilitySummary.isEmpty)
        XCTAssertFalse(entity.recommendedDos.isEmpty)
        XCTAssertFalse(entity.recommendedDonts.isEmpty)
    }

    func test_personalEvaluation_withoutProfile_isGeneralOnly() {
        // No user → only the Hoàng đạo/Hắc đạo signal applies.
        let hoangDao = ILLunarCalendar.personalEvaluation(
            dayChiIndex: 3, dayElement: .kim, isHoangDao: true, userChiIndex: nil, userElement: nil
        )
        XCTAssertEqual(hoangDao.score, 60)
        XCTAssertEqual(hoangDao.tier, .tieuCat)
        XCTAssertEqual(hoangDao.reasons, ["almanac.reason.hoangDao".localized])

        let hacDao = ILLunarCalendar.personalEvaluation(
            dayChiIndex: 3, dayElement: .kim, isHoangDao: false, userChiIndex: nil, userElement: nil
        )
        XCTAssertEqual(hacDao.score, 40)
        XCTAssertEqual(hacDao.tier, .tieuHung)
        XCTAssertEqual(hacDao.reasons, ["almanac.reason.hacDao".localized])
    }

    func test_calculateDailyAlmanac_summaryReflectsScore() {
        let profile = sut.makeBirthProfile(solarBirthDate: date(1990, 7, 15))
        let entity = sut.calculateDailyAlmanac(for: date(2024, 9, 17), profile: profile)

        // The summary is the " · "-joined list of reason phrases, always non-empty.
        let parts = entity.compatibilitySummary.split(separator: "·").map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertFalse(parts.isEmpty)
        XCTAssertTrue(parts.allSatisfy { !$0.isEmpty })
    }
}
