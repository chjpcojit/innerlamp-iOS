//
//  ILSutrasViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILSutrasNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn "Kinh sách".
    case back
    /// Chạm 1 thẻ — mở màn Chi tiết bài kinh theo `id`.
    case openSutra(id: String)
}

protocol ILSutrasViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILSutrasCoordinator` subscribe trực tiếp trong `start()`.
    var navigationEventPublisher: AnyPublisher<ILSutrasNavEvent, Never> { get }
}

final class ILSutrasViewModel: ILSutrasViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let categorySelected: AnyPublisher<ILSutraCategory, Never>
        let lengthSelected: AnyPublisher<ILSutraLengthFilter, Never>
        let queryChanged: AnyPublisher<String, Never>
        let sutraTapped: AnyPublisher<String, Never>
        /// Fired when the scroll view nears the bottom of the list.
        let loadMoreTriggered: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILSutrasStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILSutrasNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILSutrasNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILSutrasStateModel>, Never>(.idle)
    private var entity: ILSutrasEntity = .empty
    /// Bộ lọc (chip + từ khóa tìm kiếm) gửi lên server — UI state, giữ ở ViewModel.
    private var filter = ILSutraFilter()
    private var isLoading = false
    /// Tăng mỗi lần bộ lọc đổi: kết quả của request thuộc đời cũ bị bỏ.
    private var loadGeneration = 0
    private var loadTask: Task<Void, Never>?
    private let useCase: ILSutrasUseCase
    private var cancellables = Set<AnyCancellable>()

    /// Wait for the user to pause typing before hitting the server.
    private static let searchDebounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
    /// The server answers `400 INVALID_FILTER` for a `q` longer than 100 characters.
    private static let maxQueryLength = 100

    // MARK: - Initializer
    init(useCase: ILSutrasUseCase) {
        self.useCase = useCase
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.categorySelected
            .sink { [weak self] category in
                guard let self, self.filter.category != category else { return }
                self.filter.category = category
                self.reload()
            }
            .store(in: &cancellables)

        input.lengthSelected
            .sink { [weak self] length in
                guard let self, self.filter.length != length else { return }
                self.filter.length = length
                self.reload()
            }
            .store(in: &cancellables)

        input.queryChanged
            .debounce(for: Self.searchDebounce, scheduler: DispatchQueue.main)
            .map { Self.normalizedQuery($0) }
            .sink { [weak self] query in
                guard let self, self.filter.query != query else { return }
                self.filter.query = query
                self.reload()
            }
            .store(in: &cancellables)

        input.sutraTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openSutra(id: id)) }
            .store(in: &cancellables)

        input.loadMoreTriggered
            .sink { [weak self] _ in self?.loadMore() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Loading
    /// Bắt đầu lại từ trang 1 với bộ lọc hiện tại (lần mở màn hoặc đổi chip).
    private func reload() {
        loadTask?.cancel()
        loadGeneration += 1
        entity = .empty
        load { [useCase, filter] _ in try await useCase.loadFirstPage(filter: filter) }
    }

    private func loadMore() {
        // Guard against duplicate/concurrent loads and against loading past the end of the list.
        guard entity.hasMore, !isLoading else { return }
        load { [useCase, filter] current in try await useCase.loadNextPage(after: current, filter: filter) }
    }

    /// Runs one page request. The footer spinner covers both the first page and later pages. On
    /// failure the rows already loaded are kept, the spinner is cleared, and the error is surfaced
    /// afterwards.
    private func load(_ request: @escaping (ILSutrasEntity) async throws -> ILSutrasEntity) {
        isLoading = true
        publishState()

        let generation = loadGeneration
        let current = entity
        loadTask = Task { [weak self] in
            do {
                let loaded = try await request(current)
                guard let self, self.loadGeneration == generation else { return }
                self.entity = loaded
                self.isLoading = false
                self.publishState()
            } catch {
                guard let self, self.loadGeneration == generation else { return }
                self.isLoading = false
                self.publishState()
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Entity -> StateModel
    private func publishState() {
        var state = ILSutrasStateModel()
        state.subtitle = "sutras.header.subtitle".localized
        state.categories = ILSutraCategory.allCases.map {
            ILSutrasFilterModel(
                id: Self.categoryLabel($0), label: Self.categoryLabel($0), value: $0,
                isSelected: $0 == filter.category
            )
        }
        state.lengths = ILSutraLengthFilter.allCases.map {
            ILSutrasFilterModel(
                id: Self.lengthLabel($0), label: Self.lengthLabel($0), value: $0,
                isSelected: $0 == filter.length
            )
        }
        // The server total already reflects the active chips and keyword.
        state.countText = String(
            format: (filter.query.isEmpty ? "sutras.count.format" : "sutras.count.matchedFormat").localized,
            entity.totalCount
        )
        state.items = entity.sutras.map { Self.makeItem(from: $0) }
        state.isLoadingMore = isLoading
        state.hasMore = entity.hasMore
        if entity.sutras.isEmpty && !isLoading {
            state.emptyTitle = "sutras.empty.title".localized
            state.emptyMessage = "sutras.empty.message".localized
        }
        stateSubject.send(.success(state))
    }

    private static func makeItem(from sutra: ILSutraEntity) -> ILSutrasItemModel {
        ILSutrasItemModel(
            id: sutra.id,
            name: sutra.title,
            originalName: sutra.originalTitle,
            durationText: sutra.durationMinutes.map { durationText(minutes: $0) } ?? "",
            translatorLine: [sutra.translator, sutra.tradition.map { categoryLabel(.tradition($0)) } ?? ""]
                .filter { !$0.isEmpty }
                .joined(separator: "sutras.translatorSeparator".localized),
            // @ai: the app has no download feature yet — see Docs/Tech-Debt/Sutras/TD-Sutras-002-*.md
            isDownloaded: false,
            hasAudio: sutra.hasAudio,
            purposeLabels: (sutra.isDailyChant ? [categoryLabel(.dailyChant)] : [])
                + sutra.purposes.map { categoryLabel(.purpose($0)) }
        )
    }

    /// Trim and cap the keyword to what the server accepts; blank → "" (no `q` parameter).
    static func normalizedQuery(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(String.UnicodeScalarView(trimmed.unicodeScalars.prefix(maxQueryLength)))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func durationText(minutes: Int) -> String {
        guard minutes >= 60 else { return String(format: "sutras.duration.minutesFormat".localized, minutes) }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0
            ? String(format: "sutras.duration.hoursFormat".localized, hours)
            : String(format: "sutras.duration.hoursMinutesFormat".localized, hours, rest)
    }

    static func categoryLabel(_ category: ILSutraCategory) -> String {
        switch category {
        case .all: return "sutras.category.all".localized
        case .dailyChant: return "sutras.category.daily".localized
        case .purpose(.blessing): return "sutras.category.blessing".localized
        case .purpose(.requiem): return "sutras.category.requiem".localized
        case .purpose(.mantra): return "sutras.category.mantra".localized
        case .purpose(.repentance): return "sutras.category.repentance".localized
        case .purpose(.dedication): return "sutras.category.dedication".localized
        case .purpose(.vow): return "sutras.category.vow".localized
        case .purpose(.karmicReward): return "sutras.category.karmicReward".localized
        case .purpose(.meditation): return "sutras.category.meditation".localized
        case .purpose(.study): return "sutras.category.study".localized
        case .purpose(.refugePrecepts): return "sutras.category.refugePrecepts".localized
        case .tradition(.theravada): return "sutras.category.theravada".localized
        case .tradition(.mahayana): return "sutras.category.mahayana".localized
        case .tradition(.vajrayana): return "sutras.category.vajrayana".localized
        }
    }

    static func lengthLabel(_ length: ILSutraLengthFilter) -> String {
        switch length {
        case .any: return "sutras.length.any".localized
        case .upTo5: return "sutras.length.upTo5".localized
        case .upTo15: return "sutras.length.upTo15".localized
        case .upTo30: return "sutras.length.upTo30".localized
        }
    }
}
