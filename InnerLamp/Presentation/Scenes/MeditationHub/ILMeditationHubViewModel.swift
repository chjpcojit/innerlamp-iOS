//
//  ILMeditationHubViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILMeditationHubNavEvent: Equatable {
    /// Nút ‹ trên header — đóng màn Thiền định.
    case goBack
    /// Chạm 1 preset "Thiền chuông" hoặc nút "+ Tự thiết lập đồng hồ & chuông" — mở màn cấu hình
    /// đồng hồ & chuông (`medtimer`). `presetID` = nil khi người dùng tự thiết lập.
    case openTimerConfig(presetID: String?)
    /// Chạm 1 bài "Thiền dẫn" — bắt đầu luồng thực hành (màn Chuẩn bị thiền `setup`).
    case startGuidedSession(sessionID: String)
    /// Chạm thẻ tổng quan — mở Thống kê (`stats`).
    case openStats
}

protocol ILMeditationHubViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILMeditationHubCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILMeditationHubNavEvent, Never> { get }
}

final class ILMeditationHubViewModel: ILMeditationHubViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let tabSelected: AnyPublisher<ILMeditationHubTabKind, Never>
        let presetTapped: AnyPublisher<String, Never>
        let customTimerTapped: AnyPublisher<Void, Never>
        let guidedTapped: AnyPublisher<String, Never>
        let downloadTapped: AnyPublisher<String, Never>
        let summaryTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILMeditationHubStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILMeditationHubNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILMeditationHubNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILMeditationHubStateModel>, Never>
    private var currentEntity: ILMeditationHubEntity
    private var currentState: ILMeditationHubStateModel
    /// Tab đang chọn — UI state, giữ ở ViewModel (không đưa lên Entity).
    private var selectedTab: ILMeditationHubTabKind = .timer
    private let useCase: ILMeditationHubUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILMeditationHubUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = Self.makeStateModel(from: initialEntity, selectedTab: .timer)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.tabSelected
            .sink { [weak self] kind in self?.handleTabSelected(kind) }
            .store(in: &cancellables)

        input.presetTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTimerConfig(presetID: id)) }
            .store(in: &cancellables)

        input.customTimerTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openTimerConfig(presetID: nil)) }
            .store(in: &cancellables)

        input.guidedTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.startGuidedSession(sessionID: id)) }
            .store(in: &cancellables)

        input.downloadTapped
            .sink { [weak self] id in self?.handleDownloadTapped(id) }
            .store(in: &cancellables)

        input.summaryTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openStats) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
    }

    private func handleTabSelected(_ kind: ILMeditationHubTabKind) {
        // Chạm lại tab đang chọn: giữ nguyên.
        guard kind != selectedTab else { return }
        selectedTab = kind
        publishState()
    }

    private func handleDownloadTapped(_ id: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.downloadGuidedMeditation(id: id)
            } catch {
                self.stateSubject.send(.failure(error))
            }
        }
    }

    private func applyEntity(_ entity: ILMeditationHubEntity) {
        currentEntity = entity
        publishState()
    }

    private func publishState() {
        currentState = Self.makeStateModel(from: currentEntity, selectedTab: selectedTab)
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (chuỗi `.localized`, format "N phút",
    /// alpha heatmap) nên nằm ở đây, không phải trong một Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(
        from entity: ILMeditationHubEntity,
        selectedTab: ILMeditationHubTabKind
    ) -> ILMeditationHubStateModel {
        var state = ILMeditationHubStateModel()
        state.headerTitle = "meditationHub.header.title".localized
        state.headerSubtitle = "meditationHub.header.subtitle".localized
        state.selectedTab = selectedTab
        state.tabs = [
            ILMeditationHubTabModel(
                kind: .timer,
                title: "meditationHub.tab.timer".localized,
                isSelected: selectedTab == .timer
            ),
            ILMeditationHubTabModel(
                kind: .guided,
                title: "meditationHub.tab.guided".localized,
                isSelected: selectedTab == .guided
            )
        ]

        state.summary = ILMeditationHubSummaryModel(
            valueText: String(entity.streakDays),
            unitText: "meditationHub.summary.unit".localized,
            noteText: String(
                format: "meditationHub.summary.noteFormat".localized,
                entity.streakDays,
                entity.weeklyMinutes
            ),
            intensities: makeIntensities(from: entity.dailyMinutes),
            startLabel: "meditationHub.summary.startLabel".localized,
            endLabel: "meditationHub.summary.endLabel".localized,
            accessibilityLabel: "meditationHub.a11y.summary".localized
        )

        state.timerSectionTitle = "meditationHub.timer.section".localized
        state.customTimerTitle = "meditationHub.timer.custom".localized
        state.presets = entity.presets.map { preset in
            ILMeditationHubPresetModel(
                id: preset.id,
                minutesText: String(preset.minutes),
                minutesUnitText: "meditationHub.preset.minutesUnit".localized,
                name: preset.name,
                subtitle: preset.subtitle,
                accessibilityLabel: String(
                    format: "meditationHub.a11y.presetFormat".localized,
                    preset.name,
                    preset.minutes
                )
            )
        }

        state.guidedSectionTitle = "meditationHub.guided.section".localized
        state.guidedSessions = entity.guidedSessions.map { session in
            ILMeditationHubGuidedModel(
                id: session.id,
                method: session.method,
                name: session.name,
                metaText: String(
                    format: "meditationHub.guided.metaFormat".localized,
                    session.teacher,
                    session.minutes
                ),
                summary: session.summary,
                downloadTitle: session.isDownloaded
                    ? "meditationHub.guided.downloaded".localized
                    : "meditationHub.guided.download".localized,
                isDownloaded: session.isDownloaded,
                accessibilityLabel: String(
                    format: "meditationHub.a11y.guidedFormat".localized,
                    session.name,
                    session.teacher,
                    session.minutes
                )
            )
        }
        return state
    }

    /// Số phút → alpha ô heatmap (0 = chưa ngồi). Đỉnh = ngày nhiều phút nhất trong 12 tuần; mỗi
    /// ngày có ngồi được nâng alpha tối thiểu để vẫn thấy rõ trên nền thẻ.
    private static func makeIntensities(from dailyMinutes: [Int]) -> [CGFloat] {
        guard let peak = dailyMinutes.max(), peak > 0 else {
            return dailyMinutes.map { _ in 0 }
        }
        return dailyMinutes.map { minutes in
            guard minutes > 0 else { return 0 }
            return min(1, max(0.35, CGFloat(minutes) / CGFloat(peak)))
        }
    }
}
