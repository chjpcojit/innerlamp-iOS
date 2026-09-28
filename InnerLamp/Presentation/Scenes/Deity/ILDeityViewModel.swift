//
//  ILDeityViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILDeityNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn chi tiết Phật & Bồ Tát.
    case back
    /// Link "Lịch lễ" trên thẻ ngày vía.
    case openFestivals
    /// "Trì niệm với tràng hạt" — mở màn Niệm Phật với câu niệm của thẻ.
    case openMala(mantraText: String)
    /// "Chia sẻ" trên thẻ thần chú.
    case share(text: String)
    /// Hàng "Kinh liên quan" đã có trong Thư viện.
    case openSutra(id: String)
}

protocol ILDeityViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILDeityCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILDeityNavEvent, Never> { get }
}

final class ILDeityViewModel: ILDeityViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let biographyToggled: AnyPublisher<Void, Never>
        let vowsToggled: AnyPublisher<Void, Never>
        let festivalsTapped: AnyPublisher<Void, Never>
        /// Chỉ số thẻ trong `ILDeityStateModel.mantras`.
        let chantTapped: AnyPublisher<Int, Never>
        /// Chỉ số thẻ trong `ILDeityStateModel.mantras`.
        let shareTapped: AnyPublisher<Int, Never>
        /// Chỉ số hàng trong `ILDeityStateModel.sutras`.
        let sutraTapped: AnyPublisher<Int, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILDeityStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILDeityNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    /// Số đại nguyện hiển thị khi thu gọn (design `lim = 5`).
    static let collapsedVowLimit = 5

    private let navigationEventSubject = PassthroughSubject<ILDeityNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILDeityStateModel>, Never>
    private let useCase: ILDeityUseCase
    private let deityID: String
    private var entity: ILDeityEntity
    private var currentState: ILDeityStateModel
    private var isBiographyExpanded = false
    private var areVowsExpanded = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILDeityUseCase, deityID: String) {
        self.useCase = useCase
        self.deityID = deityID
        let initialEntity = useCase.getInitialState(deityID: deityID)
        self.entity = initialEntity
        let initialState = Self.makeStateModel(
            from: initialEntity,
            upcoming: useCase.upcomingMemorialDay(for: initialEntity),
            sutras: useCase.relatedSutras(for: initialEntity),
            isBiographyExpanded: false,
            areVowsExpanded: false
        )
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.biographyToggled
            .sink { [weak self] _ in
                guard let self else { return }
                isBiographyExpanded.toggle()
                publishState()
            }
            .store(in: &cancellables)

        input.vowsToggled
            .sink { [weak self] _ in
                guard let self else { return }
                areVowsExpanded.toggle()
                publishState()
            }
            .store(in: &cancellables)

        input.festivalsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openFestivals) }
            .store(in: &cancellables)

        input.chantTapped
            .sink { [weak self] index in
                guard let self, currentState.mantras.indices.contains(index) else { return }
                let mantra = currentState.mantras[index]
                navigationEventSubject.send(.openMala(mantraText: mantra.text))
            }
            .store(in: &cancellables)

        input.shareTapped
            .sink { [weak self] index in
                guard let self, currentState.mantras.indices.contains(index) else { return }
                let mantra = currentState.mantras[index]
                let text = [mantra.text, mantra.sanskrit, currentState.name]
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                navigationEventSubject.send(.share(text: text))
            }
            .store(in: &cancellables)

        input.sutraTapped
            .sink { [weak self] index in
                guard let self, currentState.sutras.indices.contains(index),
                      let sutraID = currentState.sutras[index].sutraID else { return }
                navigationEventSubject.send(.openSutra(id: sutraID))
            }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        entity = useCase.getInitialState(deityID: deityID)
        publishState()
    }

    private func publishState() {
        currentState = Self.makeStateModel(
            from: entity,
            upcoming: useCase.upcomingMemorialDay(for: entity),
            sutras: useCase.relatedSutras(for: entity),
            isBiographyExpanded: isBiographyExpanded,
            areVowsExpanded: areVowsExpanded
        )
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (nhãn, format ngày vía, cắt danh sách
    /// đại nguyện khi thu gọn) nên nằm ở đây, không phải trong Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(
        from entity: ILDeityEntity,
        upcoming: ILDeityUpcomingMemorialDayEntity?,
        sutras: [ILDeityRelatedSutraEntity],
        isBiographyExpanded: Bool,
        areVowsExpanded: Bool
    ) -> ILDeityStateModel {
        var state = ILDeityStateModel()

        state.headerTitle = entity.nameVi

        state.kind = entity.kind
        state.kindLabel = entity.kind == .buddha
            ? "deity.kind.buddha".localized
            : "deity.kind.bodhisattva".localized
        state.realmLabel = entity.pureLand
        state.name = entity.nameVi
        state.sanskritName = entity.nameSanskrit
        state.watermark = entity.nameChinese

        state.memorialDay = upcoming.map(makeMemorialDayModel)
        state.festivalsLinkTitle = "deity.memorial.festivals".localized
        state.roleText = entity.coreVirtue

        state.biographyTitle = "deity.section.biography".localized
        state.biography = entity.biographySummary
        state.isBiographyExpanded = isBiographyExpanded
        state.biographyToggleTitle = isBiographyExpanded
            ? "deity.biography.collapse".localized
            : "deity.biography.expand".localized

        let allVows = entity.greatVows.enumerated().map { index, text in
            ILDeityVowModel(number: "\(index + 1)", text: text)
        }
        let isVowListLong = allVows.count > collapsedVowLimit
        state.vowsTitle = "deity.section.vows".localized
        state.vowsCountText = String(format: "deity.vows.countFormat".localized, allVows.count)
        state.vows = isVowListLong && !areVowsExpanded ? Array(allVows.prefix(collapsedVowLimit)) : allVows
        if isVowListLong {
            state.vowsToggleTitle = areVowsExpanded
                ? "deity.vows.collapse".localized
                : String(format: "deity.vows.expandFormat".localized, allVows.count)
        }

        state.mantrasTitle = "deity.section.mantras".localized
        state.mantras = makeMantras(from: entity)
        state.chantTitle = "deity.mantra.chant".localized
        state.shareTitle = "deity.mantra.share".localized

        state.sutrasTitle = "deity.section.sutras".localized
        state.sutras = sutras.map { sutra in
            ILDeitySutraModel(
                title: sutra.title,
                subtitle: sutra.sutraID == nil
                    ? "deity.sutra.pending".localized
                    : "deity.sutra.available".localized,
                trailingText: sutra.sutraID == nil ? "" : "deity.sutra.open".localized,
                sutraID: sutra.sutraID
            )
        }

        state.footnote = "deity.footnote".localized
        return state
    }

    /// 3 thẻ: danh hiệu (hiệu tôn) · thần chú ngắn (Hán Việt + Phạn) · Đà-la-ni (trích đoạn, ghi
    /// chú là tên Đà-la-ni). Thẻ nào thiếu câu chính thì bỏ.
    private static func makeMantras(from entity: ILDeityEntity) -> [ILDeityMantraModel] {
        let mantra = entity.mantra
        return [
            ILDeityMantraModel(
                label: "deity.mantra.label.title".localized,
                text: entity.titleHonorific,
                sanskrit: "",
                note: ""
            ),
            ILDeityMantraModel(
                label: "deity.mantra.label.short".localized,
                text: mantra.shortSinoVietnamese,
                sanskrit: mantra.shortSanskrit,
                note: ""
            ),
            ILDeityMantraModel(
                label: "deity.mantra.label.dharani".localized,
                text: mantra.dharaniSnippet,
                sanskrit: "",
                note: mantra.dharaniName
            )
        ].filter { !$0.text.isEmpty }
    }

    private static func makeMemorialDayModel(_ upcoming: ILDeityUpcomingMemorialDayEntity) -> ILDeityMemorialDayModel {
        let day = upcoming.memorialDay
        return ILDeityMemorialDayModel(
            dayText: String(format: "%02d", day.lunarDay),
            monthText: monthText(day.lunarMonth),
            eventName: day.eventName,
            countdownText: countdownText(daysUntil: upcoming.daysUntil, date: upcoming.date)
        )
    }

    /// "GIÊNG" / "CHẠP" cho tháng 1 / 12 (cách gọi quen thuộc), còn lại "THÁNG n".
    private static func monthText(_ lunarMonth: Int) -> String {
        switch lunarMonth {
        case 1, 12:
            return "lunarCalendar.month.\(lunarMonth)".localized.uppercased()
        default:
            return String(format: "deity.memorial.monthFormat".localized, lunarMonth)
        }
    }

    /// "Hôm nay / Ngày mai / Còn N ngày · Thứ X, dd-MM-yyyy" (lịch Việt Nam, UTC+7).
    private static func countdownText(daysUntil: Int, date: Date) -> String {
        let countdown: String
        switch daysUntil {
        case 0: countdown = "deity.memorial.today".localized
        case 1: countdown = "deity.memorial.tomorrow".localized
        default: countdown = String(format: "deity.memorial.daysLeft".localized, daysUntil)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let weekday = calendar.component(.weekday, from: date)
        let weekdayText = weekday == 1
            ? "deity.weekday.sunday".localized
            : String(format: "deity.weekday.format".localized, weekday)

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd-MM-yyyy"

        return String(
            format: "deity.memorial.dateFormat".localized,
            countdown, weekdayText, formatter.string(from: date)
        )
    }
}
