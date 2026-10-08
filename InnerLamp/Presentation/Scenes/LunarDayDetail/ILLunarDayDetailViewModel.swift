//
//  ILLunarDayDetailViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation
import Combine

enum ILLunarDayDetailNavEvent: Equatable {
    /// Nút ‹ ở header — quay lại Trang chủ.
    case back
}

protocol ILLunarDayDetailViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILLunarDayDetailCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILLunarDayDetailNavEvent, Never> { get }
}

final class ILLunarDayDetailViewModel: ILLunarDayDetailViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILLunarDayDetailStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILLunarDayDetailNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILLunarDayDetailNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILLunarDayDetailStateModel>, Never>
    private let useCase: ILLunarDayDetailUseCase
    private let almanacUseCase: ILAlmanacUseCase
    private let sutraQuoteUseCase: ILSutraQuoteUseCase
    private let calendarImageUseCase: ILCalendarImageUseCase
    private let date: Date
    /// Quote shown in the verse card. Set up front when the opening screen (Home hero card) hands
    /// one over; otherwise loaded from Core Data as the fixed quote of `date`. While nil, the static
    /// verse from `ILLunarDayDetailUseCase` is shown.
    private var verse: ILHomeQuoteEntity?
    /// Picture of `date` from `GET /v1/calendar/image`; nil until loaded and after any failure
    /// (the hero then keeps its gradient).
    private var heroImage: ILCalendarImageEntity?
    private var hasRequestedHeroImage = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(
        useCase: ILLunarDayDetailUseCase,
        almanacUseCase: ILAlmanacUseCase,
        sutraQuoteUseCase: ILSutraQuoteUseCase,
        calendarImageUseCase: ILCalendarImageUseCase,
        date: Date,
        verse: ILHomeQuoteEntity? = nil
    ) {
        self.useCase = useCase
        self.almanacUseCase = almanacUseCase
        self.sutraQuoteUseCase = sutraQuoteUseCase
        self.calendarImageUseCase = calendarImageUseCase
        self.date = date
        self.verse = verse
        self.stateSubject = CurrentValueSubject(.success(Self.makeStateModel(
            from: useCase.getDetail(for: date),
            almanac: almanacUseCase.calculateDailyAlmanac(for: date, profile: nil),
            verse: verse,
            heroImage: nil
        )))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        publishState()
        if verse?.lines.isEmpty != false {
            loadDailyVerse()
        }
        loadHeroImage()
    }

    /// Fetches the picture of `date` once per screen. Failure (offline, server error) or an
    /// unsupported year is non-fatal: the gradient hero stays and no error is shown.
    private func loadHeroImage() {
        guard !hasRequestedHeroImage else { return }
        hasRequestedHeroImage = true
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let image = try await self.calendarImageUseCase.loadImage(for: self.date) else { return }
                self.heroImage = image
                self.publishState()
            } catch {
                #if DEBUG
                print("[LunarDayDetail] hero image load failed: \(error)")
                #endif
            }
        }
    }

    /// Opened without a quote (e.g. from the Lunar Calendar) — load the fixed quote of `date` from
    /// Core Data. Failure or an empty catalog is non-fatal: the static verse stays.
    private func loadDailyVerse() {
        Task { [weak self] in
            guard let self else { return }
            guard let quote = try? await self.sutraQuoteUseCase.quote(for: self.date) else { return }
            self.verse = ILHomeQuoteEntity(quote: quote)
            self.publishState()
        }
    }

    private func publishState() {
        stateSubject.send(.success(Self.makeStateModel(
            from: useCase.getDetail(for: date),
            almanac: almanacUseCase.calculateDailyAlmanac(for: date, profile: nil),
            verse: verse,
            heroImage: heroImage
        )))
    }

    // MARK: - Entity -> StateModel mapping
    /// `Entity -> StateModel` là việc riêng của presentation (tên Can Chi, nhãn loại ngày, format
    /// ngày giờ...) nên nằm ở đây, không phải trong một Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(
        from entity: ILLunarDayDetailEntity,
        almanac: ILLunarCalendar.AlmanacResult,
        verse: ILHomeQuoteEntity?,
        heroImage: ILCalendarImageEntity?
    ) -> ILLunarDayDetailStateModel {
        var state = ILLunarDayDetailStateModel()

        state.eyebrowText = "lunarDayDetail.hero.eyebrow".localized
        state.heroDay = String(format: "%02d", entity.lunarDay)
        state.heroMonth = ILLunarCalendar.lunarMonthLabel(entity.lunarMonth, isLeap: entity.isLunarLeapMonth)
        state.heroYear = String(
            format: "lunarDayDetail.hero.yearFormat".localized,
            ILLunarCalendar.canChiYear(entity.lunarYear)
        )
        state.headerTitle = "\(state.heroDay) \(state.heroMonth)"
        state.heroSolar = solarLabel(for: entity.date)

        let type = typeInfo(lunarDay: entity.lunarDay, isHoangDao: entity.isHoangDao)
        state.typeTone = type.tone
        state.typeLabel = type.label
        state.adviceText = advice(forLunarDay: entity.lunarDay)
        if let heroImage {
            state.heroImageURL = heroImage.imageURL
            state.heroImageCredit = heroImage.creditText
        }

        state.infoRows = [
            ILLunarDayDetailInfoRowModel(
                id: "day",
                key: "lunarDayDetail.info.day".localized,
                value: ILLunarCalendar.canChiDay(day: entity.solarDay, month: entity.solarMonth, year: entity.solarYear)
            ),
            ILLunarDayDetailInfoRowModel(
                id: "month",
                key: "lunarDayDetail.info.month".localized,
                value: monthInfoValue(entity)
            ),
            ILLunarDayDetailInfoRowModel(
                id: "year",
                key: "lunarDayDetail.info.year".localized,
                value: ILLunarCalendar.canChiYear(entity.lunarYear)
            ),
            ILLunarDayDetailInfoRowModel(
                id: "solar",
                key: "lunarDayDetail.info.solar".localized,
                value: solarDateValue(entity)
            )
        ]

        state.almanac = makeAlmanac(almanac: almanac)
        (state.elementsTitle, state.napamLine, state.napamElement, state.elements) = makeElements(entity)

        if let verse, !verse.lines.isEmpty {
            state.verseLines = verse.lines
            state.verseSource = verse.source
        } else {
            state.verseLines = entity.verseLines
            state.verseSource = entity.verseSource
        }

        state.goodHoursTitle = "lunarDayDetail.goodHours.title".localized
        state.goodHours = entity.goodHourChiIndices.map { chi in
            ILLunarDayDetailHourModel(
                id: chi,
                name: ILLunarCalendar.chiName(chi),
                icon: zodiacAnimal(chi),
                range: hourRange(chi)
            )
        }

        state.clashTitle = "lunarDayDetail.clash.title".localized
        let clashChiName = ILLunarCalendar.chiName(entity.clashChiIndex)
        let clashIcon = zodiacAnimal(entity.clashChiIndex)
        state.clashItems = ILLunarCalendar.clashCanIndices(dayCanIndex: entity.dayCanIndex).map { can in
            let name = "\(ILLunarCalendar.canName(can)) \(clashChiName)"
            return ILLunarDayDetailClashModel(id: name, name: name, icon: clashIcon)
        }
        let dayCanChi = ILLunarCalendar.canChiDay(day: entity.solarDay, month: entity.solarMonth, year: entity.solarYear)
        state.clashNote = String(format: "lunarDayDetail.clash.noteFormat".localized, dayCanChi, clashChiName)

        state.directionsTitle = "lunarDayDetail.directions.title".localized
        state.directions = [
            ILLunarDayDetailDirectionModel(
                id: "joy",
                key: "lunarDayDetail.directions.joy".localized,
                value: entity.joyStarDirection,
                subtitle: "lunarDayDetail.directions.joy.sub".localized,
                glyph: "喜",
                kind: .joy
            ),
            ILLunarDayDetailDirectionModel(
                id: "wealth",
                key: "lunarDayDetail.directions.wealth".localized,
                value: entity.wealthStarDirection,
                subtitle: "lunarDayDetail.directions.wealth.sub".localized,
                glyph: "財",
                kind: .wealth
            ),
            ILLunarDayDetailDirectionModel(
                id: "crane",
                key: "lunarDayDetail.directions.crane".localized,
                value: entity.craneStarDirection ?? "lunarDayDetail.directions.crane.none".localized,
                subtitle: (entity.craneStarDirection == nil
                    ? "lunarDayDetail.directions.crane.none.sub"
                    : "lunarDayDetail.directions.crane.sub").localized,
                glyph: "鶴",
                kind: .crane
            )
        ]

        return state
    }

    // MARK: - Almanac ("Ngày Cát/Hung") mapping

    private static func makeAlmanac(almanac: ILLunarCalendar.AlmanacResult) -> ILLunarDayDetailAlmanacModel {
        let rating = rating(for: almanac.personalTier)
        let subKey = almanac.isHoangDao
            ? "lunarDayDetail.almanac.sub.hoangDao"
            : "lunarDayDetail.almanac.sub.hacDao"
        return ILLunarDayDetailAlmanacModel(
            rating: rating,
            ratingLabel: rating.localizedLabel,
            ratingSub: String(format: subKey.localized, almanac.truc),
            dos: almanac.recommendedDos,
            donts: almanac.recommendedDonts
        )
    }

    /// Map 7-bậc `ILAuspiciousTier` về thang 5 bậc của design handoff (Đại hung → Đại cát).
    private static func rating(for tier: ILAuspiciousTier) -> ILLunarDayDetailDayRating {
        switch tier {
        case .daiCat: return .daiCat
        case .trungCat, .tieuCat: return .cat
        case .binhHoa: return .binh
        case .tieuHung, .hung: return .hung
        case .daiHung: return .daiHung
        }
    }

    // MARK: - Ngũ hành & nạp âm mapping

    private static func makeElements(
        _ entity: ILLunarDayDetailEntity
    ) -> (title: String, napamLine: String, napamElement: ILFiveElements, elements: [ILLunarDayDetailElementModel]) {
        let can = entity.dayCanIndex
        let chi = entity.dayChiIndex
        let napam = ILLunarCalendar.napAmElement(can: can, chi: chi)

        let elements = [
            ILLunarDayDetailElementModel(
                id: "can",
                key: "lunarDayDetail.elements.can".localized,
                name: ILLunarCalendar.canName(can),
                element: ILLunarCalendar.canElement(can),
                elementName: ILLunarCalendar.elementName(ILLunarCalendar.canElement(can))
            ),
            ILLunarDayDetailElementModel(
                id: "chi",
                key: "lunarDayDetail.elements.chi".localized,
                name: ILLunarCalendar.chiName(chi),
                element: ILLunarCalendar.chiElement(chi),
                elementName: ILLunarCalendar.elementName(ILLunarCalendar.chiElement(chi))
            ),
            ILLunarDayDetailElementModel(
                id: "napAm",
                key: "lunarDayDetail.elements.napAm".localized,
                name: ILLunarCalendar.napAmName(can: can, chi: chi),
                element: napam,
                elementName: ILLunarCalendar.elementName(napam)
            )
        ]

        return (
            "lunarDayDetail.elements.title".localized,
            ILLunarCalendar.napAmName(can: can, chi: chi),
            napam,
            elements
        )
    }

    // MARK: - Copy / formatting helpers

    private static func typeInfo(lunarDay: Int, isHoangDao: Bool) -> (tone: ILLunarDayDetailTypeTone, label: String) {
        let good = isHoangDao
        switch lunarDay {
        case 15:
            let key = good ? "lunarDayDetail.type.fullMoon.hoangDao" : "lunarDayDetail.type.fullMoon.hacDao"
            return (.gold, key.localized)
        case 1:
            let key = good ? "lunarDayDetail.type.newMoon.hoangDao" : "lunarDayDetail.type.newMoon.hacDao"
            return (.gold, key.localized)
        default:
            return good
                ? (.auspicious, "lunarDayDetail.type.hoangDao".localized)
                : (.inauspicious, "lunarDayDetail.type.hacDao".localized)
        }
    }

    private static func advice(forLunarDay lunarDay: Int) -> String {
        switch lunarDay {
        case 1: return "lunarDayDetail.advice.newMoon".localized
        case 15: return "lunarDayDetail.advice.fullMoon".localized
        case 8, 14, 23, 30: return "lunarDayDetail.advice.fastDay".localized
        default: return "lunarDayDetail.advice.ordinary".localized
        }
    }

    private static func monthInfoValue(_ entity: ILLunarDayDetailEntity) -> String {
        let canChi = ILLunarCalendar.canChiMonth(lunarYear: entity.lunarYear, lunarMonth: entity.lunarMonth)
        return entity.isLunarLeapMonth ? "\(canChi) (nhuận)" : canChi
    }

    private static func hourRange(_ chiIndex: Int) -> String {
        let start = (23 + 2 * chiIndex) % 24
        let end = (start + 2) % 24
        return String(format: "lunarDayDetail.hour.rangeFormat".localized, start, end)
    }

    /// 12 con giáp theo thứ tự Địa Chi (0 = Tý) — emoji cố định, dùng làm icon hiển thị.
    private static let zodiacAnimals = ["🐀", "🐃", "🐅", "🐈", "🐉", "🐍", "🐎", "🐐", "🐒", "🐓", "🐕", "🐖"]

    private static func zodiacAnimal(_ chiIndex: Int) -> String {
        zodiacAnimals[((chiIndex % 12) + 12) % 12]
    }

    // MARK: - Date formatting
    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = format
        return formatter
    }

    private static let solarLabelFormatter = makeFormatter("EEEE, dd/MM/yyyy")
    private static let solarDateFormatter = makeFormatter("dd/MM/yyyy")

    /// "Thứ Bảy, 16/09/2026"
    private static func solarLabel(for date: Date) -> String {
        solarLabelFormatter.string(from: date).capitalizingFirstLetter()
    }

    /// "16/09/2026"
    private static func solarDateValue(_ entity: ILLunarDayDetailEntity) -> String {
        solarDateFormatter.string(from: entity.date)
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
