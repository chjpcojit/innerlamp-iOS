//
//  ILLunarDayDetailViewModelTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 27/9/26.
//

import XCTest
import Combine
@testable import InnerLamp

final class ILLunarDayDetailViewModelTests: XCTestCase {

    private var mockUseCase: MockILLunarDayDetailUseCase!
    private var mockAlmanac: MockILAlmanacUseCase!
    private var mockSutraQuote: MockILLunarDayDetailSutraQuoteUseCase!
    private var mockCalendarImage: MockILCalendarImageUseCase!
    private var sut: ILLunarDayDetailViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!

    private let date = Date(timeIntervalSince1970: 0)

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLunarDayDetailUseCase(entity: Self.makeEntity())
        mockAlmanac = MockILAlmanacUseCase(result: Self.makeAlmanacResult())
        mockSutraQuote = MockILLunarDayDetailSutraQuoteUseCase()
        mockCalendarImage = MockILCalendarImageUseCase()
        sut = makeSUT()
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        sut = nil
        mockAlmanac = nil
        mockSutraQuote = nil
        mockCalendarImage = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeSUT(verse: ILHomeQuoteEntity? = nil) -> ILLunarDayDetailViewModel {
        ILLunarDayDetailViewModel(
            useCase: mockUseCase,
            almanacUseCase: mockAlmanac,
            sutraQuoteUseCase: mockSutraQuote,
            calendarImageUseCase: mockCalendarImage,
            date: date,
            verse: verse
        )
    }

    private func makeInput() -> ILLunarDayDetailViewModel.Input {
        ILLunarDayDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILLunarDayDetailStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILLunarDayDetailStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_buildsHeroFromEntity() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertTrue(mockUseCase.getDetailCalled)
        XCTAssertEqual(state?.eyebrowText, "lunarDayDetail.hero.eyebrow".localized)
        XCTAssertEqual(state?.heroDay, "15")
        XCTAssertEqual(state?.heroMonth, ILLunarCalendar.lunarMonthLabel(7, isLeap: false))
        XCTAssertEqual(state?.typeTone, .gold)
        XCTAssertEqual(state?.typeLabel, "lunarDayDetail.type.fullMoon.hoangDao".localized)
        XCTAssertEqual(state?.adviceText, "lunarDayDetail.advice.fullMoon".localized)
    }

    func test_viewDidLoad_buildsInfoRowsAndSections() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertEqual(state?.infoRows.map(\.id), ["day", "month", "year", "solar"])
        XCTAssertEqual(state?.infoRows.first(where: { $0.id == "solar" })?.value, "10/09/2024")
        XCTAssertEqual(state?.goodHours.count, 6)
        XCTAssertEqual(state?.clashItems.count, 2)
        XCTAssertEqual(state?.directions.map(\.id), ["joy", "wealth", "crane"])
        XCTAssertEqual(state?.verseLines.count, 2)
    }

    func test_viewDidLoad_craneDirection_showsDirectionOrNoneWhenInHeaven() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        let crane = latest()?.directions.first(where: { $0.id == "crane" })
        XCTAssertEqual(crane?.value, "lunarCalendar.direction.south".localized)
        XCTAssertEqual(crane?.subtitle, "lunarDayDetail.directions.crane.sub".localized)
        XCTAssertEqual(crane?.kind, .crane)
    }

    func test_viewDidLoad_usesPassedVerse_insteadOfStaticCatalog() {
        let passed = ILHomeQuoteEntity(lines: ["a", "b", "c", "d"], source: "— Kinh Pháp Cú (Dhammapada), câu 5")
        sut = makeSUT(verse: passed)
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.verseLines, passed.lines)
        XCTAssertEqual(latest()?.verseSource, passed.source)
    }

    func test_viewDidLoad_withPassedVerse_doesNotQueryCoreData() async {
        sut = makeSUT(verse: ILHomeQuoteEntity(lines: ["a", "b", "c", "d"], source: "src"))
        _ = observeLatestState()

        viewDidLoadSubject.send(())
        await Task.yield()

        XCTAssertEqual(mockSutraQuote.quoteForDateCallCount, 0)
    }

    func test_viewDidLoad_withoutPassedVerse_loadsDailyQuoteFromCoreData() {
        mockSutraQuote.quoteForDateResult = ILSutraQuoteEntity(
            id: 1,
            sutraName: "Kinh Pháp Cú (Dhammapada)",
            translator: "Hòa thượng Thích Minh Châu",
            chapterNumber: "I",
            chapterName: "Phẩm Song Yếu",
            verseNumber: 5,
            content: "Với hận diệt hận thù, Ðời này không có được. Không hận diệt hận thù, Là định luật ngàn thu"
        )
        let expected = ILHomeQuoteEntity(quote: mockSutraQuote.quoteForDateResult!)
        let loaded = expectation(description: "daily quote applied")
        _ = sut.transform(input: makeInput()).state
            .sink { state in
                if case .success(let model) = state, model.verseLines == expected.lines {
                    XCTAssertEqual(model.verseSource, expected.source)
                    loaded.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [loaded], timeout: 1)
        XCTAssertEqual(mockSutraQuote.lastQuoteDate, date)
        XCTAssertEqual(expected.lines.count, 4)
    }

    func test_viewDidLoad_keepsStaticVerse_whenCoreDataQuoteFails() async {
        mockSutraQuote.error = NSError(domain: "test", code: 1)
        sut = makeSUT(verse: ILHomeQuoteEntity())
        let latest = observeLatestState()

        viewDidLoadSubject.send(())
        for _ in 0..<5 { await Task.yield() }

        XCTAssertEqual(mockSutraQuote.quoteForDateCallCount, 1)
        XCTAssertEqual(latest()?.verseLines, ["line-1", "line-2"])
        XCTAssertEqual(latest()?.verseSource, "source")
    }

    // MARK: - Hero image

    private static let heroImage = ILCalendarImageEntity(
        id: "buddha_034",
        imageURL: "http://h:8080/static/images/home-calendar/buddha_034.jpg",
        author: "Judgefloro",
        license: "Public domain",
        licenseURL: nil,
        sourceURL: nil
    )

    func test_viewDidLoad_beforeImageLoads_hasNoHeroImage() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.heroImageURL)
        XCTAssertEqual(latest()?.heroImageCredit, "")
    }

    func test_viewDidLoad_loadsHeroImageForTheScreenDate_andFormatsCredit() {
        mockCalendarImage.result = .success(Self.heroImage)
        let loaded = expectation(description: "hero image applied")
        _ = sut.transform(input: makeInput()).state
            .sink { state in
                if case .success(let model) = state, model.heroImageURL != nil {
                    XCTAssertEqual(model.heroImageURL, Self.heroImage.imageURL)
                    XCTAssertEqual(
                        model.heroImageCredit,
                        String(format: "lunarDayDetail.hero.imageCreditFormat".localized, "Judgefloro", "Public domain")
                    )
                    loaded.fulfill()
                }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        wait(for: [loaded], timeout: 1)
        XCTAssertEqual(mockCalendarImage.requestedDates, [date])
    }

    func test_viewDidLoad_heroImageFailure_keepsGradientAndStateSuccess() async {
        mockCalendarImage.result = .failure(ILCatalogError.offline)
        let latest = observeLatestState()

        viewDidLoadSubject.send(())
        for _ in 0..<5 { await Task.yield() }

        XCTAssertEqual(mockCalendarImage.requestedDates.count, 1)
        XCTAssertNil(latest()?.heroImageURL)
        XCTAssertEqual(latest()?.heroImageCredit, "")
        XCTAssertNotNil(latest(), "A failed image must never turn the screen into a failure state")
    }

    func test_viewDidLoad_unsupportedYear_returnsNilImage() async {
        mockCalendarImage.result = .success(nil)
        let latest = observeLatestState()

        viewDidLoadSubject.send(())
        for _ in 0..<5 { await Task.yield() }

        XCTAssertNil(latest()?.heroImageURL)
    }

    func test_viewDidLoad_twice_requestsHeroImageOnce() async {
        mockCalendarImage.result = .success(Self.heroImage)
        _ = observeLatestState()

        viewDidLoadSubject.send(())
        viewDidLoadSubject.send(())
        for _ in 0..<5 { await Task.yield() }

        XCTAssertEqual(mockCalendarImage.requestedDates.count, 1)
    }

    func test_viewDidLoad_buildsAlmanacCard() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertEqual(state?.almanac.rating, .daiCat)
        XCTAssertEqual(state?.almanac.ratingLabel, "lunarDayDetail.almanac.rating.daiCat".localized)
        XCTAssertEqual(
            state?.almanac.ratingSub,
            String(format: "lunarDayDetail.almanac.sub.hoangDao".localized, Self.makeAlmanacResult().truc)
        )
        XCTAssertEqual(state?.almanac.dos, ["việc nên 1"])
        XCTAssertEqual(state?.almanac.donts, ["việc kiêng 1"])
    }

    func test_viewDidLoad_mapsAlmanacRatingFromTier() {
        let tierToRating: [(ILAuspiciousTier, ILLunarDayDetailDayRating)] = [
            (.daiCat, .daiCat),
            (.trungCat, .cat),
            (.tieuCat, .cat),
            (.binhHoa, .binh),
            (.tieuHung, .hung),
            (.hung, .hung),
            (.daiHung, .daiHung)
        ]
        for (tier, rating) in tierToRating {
            mockAlmanac = MockILAlmanacUseCase(result: Self.makeAlmanacResult(tier: tier))
            sut = makeSUT()
            let latest = observeLatestState()
            viewDidLoadSubject.send(())
            XCTAssertEqual(latest()?.almanac.rating, rating, "tier \(tier)")
        }
    }

    func test_viewDidLoad_buildsElements() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertEqual(state?.elementsTitle, "lunarDayDetail.elements.title".localized)
        XCTAssertEqual(state?.elements.map(\.id), ["can", "chi", "napAm"])
        XCTAssertEqual(state?.elements.first?.name, ILLunarCalendar.canName(0))
        XCTAssertEqual(state?.elements.first?.element, .moc)
        XCTAssertEqual(state?.elements.first?.elementName, ILLunarCalendar.elementName(.moc))
        XCTAssertEqual(state?.napamLine, ILLunarCalendar.napAmName(can: 0, chi: 6))
        XCTAssertEqual(state?.napamElement, ILLunarCalendar.napAmElement(can: 0, chi: 6))
    }

    func test_viewDidLoad_mapsGoodHoursNamesAndRanges() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let hours = latest()?.goodHours ?? []
        XCTAssertEqual(hours.first?.name, ILLunarCalendar.chiName(0))
        XCTAssertEqual(hours.first?.range, String(format: "lunarDayDetail.hour.rangeFormat".localized, 23, 1))
        XCTAssertEqual(hours.last?.name, ILLunarCalendar.chiName(9))
        XCTAssertEqual(hours.last?.range, String(format: "lunarDayDetail.hour.rangeFormat".localized, 17, 19))
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLunarDayDetailNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    // MARK: - Fixture

    private static func makeEntity() -> ILLunarDayDetailEntity {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2024, month: 9, day: 10, hour: 12)) ?? Date()

        return ILLunarDayDetailEntity(
            date: date,
            solarDay: 10,
            solarMonth: 9,
            solarYear: 2024,
            lunarDay: 15,
            lunarMonth: 7,
            lunarYear: 2024,
            isLunarLeapMonth: false,
            isHoangDao: true,
            dayCanIndex: 0,
            dayChiIndex: 6,
            goodHourChiIndices: [0, 1, 4, 5, 8, 9],
            clashChiIndex: 0,
            joyStarDirection: "lunarCalendar.direction.northeast".localized,
            wealthStarDirection: "lunarCalendar.direction.southeast".localized,
            craneStarDirection: "lunarCalendar.direction.south".localized,
            verseLines: ["line-1", "line-2"],
            verseSource: "source"
        )
    }

    private static func makeAlmanacResult(
        tier: ILAuspiciousTier = .daiCat,
        score: Int = 85,
        dos: [String] = ["việc nên 1"],
        donts: [String] = ["việc kiêng 1"]
    ) -> ILLunarCalendar.AlmanacResult {
        ILLunarCalendar.AlmanacResult(
            lunarDay: 15,
            lunarMonth: 7,
            lunarYear: 2024,
            canChiDay: "Giáp Tý",
            canChiMonth: "Nhâm Thân",
            canChiYear: "Giáp Thìn",
            solarTerm: "lunarCalendar.solarTerm.0".localized,
            isHoangDao: true,
            hoangDaoDeity: "lunarCalendar.star.0".localized,
            truc: "lunarCalendar.truc.0".localized,
            star28: "lunarCalendar.star28.0".localized,
            hoangDaoHours: [],
            hyThanDirection: "lunarCalendar.direction.northeast".localized,
            taiThanDirection: "lunarCalendar.direction.southeast".localized,
            isPersonalized: false,
            personalTier: tier,
            personalScore: score,
            compatibilitySummary: "sum",
            recommendedDos: dos,
            recommendedDonts: donts
        )
    }
}

// MARK: - Mock ILLunarDayDetailUseCase
final class MockILLunarDayDetailUseCase: ILLunarDayDetailUseCase {
    var stubEntity: ILLunarDayDetailEntity
    var getDetailCalled = false

    init(entity: ILLunarDayDetailEntity) {
        self.stubEntity = entity
    }

    func getDetail(for date: Date) -> ILLunarDayDetailEntity {
        getDetailCalled = true
        return stubEntity
    }
}

// MARK: - Mock ILAlmanacUseCase
final class MockILCalendarImageUseCase: ILCalendarImageUseCase {

    var result: Result<ILCalendarImageEntity?, Error> = .success(nil)
    private(set) var requestedDates: [Date] = []

    func loadImage(for date: Date) async throws -> ILCalendarImageEntity? {
        requestedDates.append(date)
        return try result.get()
    }
}

final class MockILAlmanacUseCase: ILAlmanacUseCase {
    var stubResult: ILLunarCalendar.AlmanacResult

    init(result: ILLunarCalendar.AlmanacResult) {
        self.stubResult = result
    }

    func makeBirthProfile(solarBirthDate: Date) -> ILUserBirthProfileEntity {
        ILUserBirthProfileEntity(solarBirthDate: solarBirthDate, lunarYear: 2024, canIndex: 0, chiIndex: 4, element: .hoa)
    }

    func calculateDailyAlmanac(for date: Date, profile: ILUserBirthProfileEntity?) -> ILLunarCalendar.AlmanacResult {
        stubResult
    }
}

final class MockILLunarDayDetailSutraQuoteUseCase: ILSutraQuoteUseCase {

    var quoteForDateResult: ILSutraQuoteEntity?
    var error: Error?
    private(set) var quoteForDateCallCount = 0
    private(set) var lastQuoteDate: Date?

    func prepare() async throws {}

    func quote(for date: Date) async throws -> ILSutraQuoteEntity? {
        quoteForDateCallCount += 1
        lastQuoteDate = date
        if let error { throw error }
        return quoteForDateResult
    }

    func randomQuote() async throws -> ILSutraQuoteEntity? { nil }

    func randomQuotes(count: Int) async throws -> [ILSutraQuoteEntity] { [] }
}
