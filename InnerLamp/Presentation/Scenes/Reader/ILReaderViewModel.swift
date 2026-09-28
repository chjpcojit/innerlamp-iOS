//
//  ILReaderViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILReaderNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn Tụng kinh.
    case back
    /// Nút "Aa" ở header — mở tùy chỉnh cỡ chữ kinh văn (chưa build).
    case openFontSize
    /// Chip "Chia sẻ câu kinh" — mở modal chia sẻ (màn `share` chưa build).
    case share
    /// Chip "Tải để nghe offline" — mở màn nghe không cần mạng (màn `downloads` chưa build).
    case download
    /// Nút tốc độ "1.0×" — mở trình phát toàn màn (màn `player` chưa build).
    case openPlayer
}

protocol ILReaderViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILReaderCoordinator` subscribe trực tiếp trong `start()`,
    /// trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILReaderNavEvent, Never> { get }
}

final class ILReaderViewModel: ILReaderViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let fontSizeTapped: AnyPublisher<Void, Never>
        let shareTapped: AnyPublisher<Void, Never>
        let downloadTapped: AnyPublisher<Void, Never>
        let playPauseTapped: AnyPublisher<Void, Never>
        let speedTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILReaderStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILReaderNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILReaderNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILReaderStateModel>, Never>
    private var currentEntity: ILReaderEntity
    private var currentState: ILReaderStateModel
    private let useCase: ILReaderUseCase
    private let initialSutraID: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILReaderUseCase, sutraID: String) {
        self.useCase = useCase
        self.initialSutraID = sutraID
        let initialEntity = useCase.getInitialState(sutraID: sutraID)
        self.currentEntity = initialEntity
        self.currentState = Self.makeStateModel(from: initialEntity, useCase: useCase)
        self.stateSubject = CurrentValueSubject(.success(currentState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.fontSizeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openFontSize) }
            .store(in: &cancellables)

        input.shareTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.share) }
            .store(in: &cancellables)

        input.downloadTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.download) }
            .store(in: &cancellables)

        input.playPauseTapped
            .sink { [weak self] _ in self?.handlePlayPauseTapped() }
            .store(in: &cancellables)

        input.speedTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openPlayer) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState(sutraID: initialSutraID))
    }

    private func handlePlayPauseTapped() {
        applyEntity(useCase.togglePlayPause(currentEntity))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (format "12:04"/"1.0×", dòng
    /// "Đang phát · Thầy Minh Đạo", nhãn chip) nên nằm ở đây, không phải trong Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILReaderEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(from: entity, useCase: useCase)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILReaderEntity,
        useCase: ILReaderUseCase
    ) -> ILReaderStateModel {
        var state = ILReaderStateModel()

        let sutra = useCase.currentSutra(in: entity)
        state.title = sutra?.title ?? ""
        state.subtitle = sutra?.subtitle ?? ""
        state.readingProgress = entity.readingProgress

        if let verse = useCase.currentVerse(in: entity) {
            state.verseText = verse.vietnamese
            state.translationText = verse.english
        }
        state.nextVerseText = useCase.nextVerse(in: entity)?.vietnamese ?? ""

        state.fontSizeActionTitle = "reader.header.fontSizeAction".localized
        state.shareChipTitle = "reader.verse.share".localized
        state.downloadChipTitle = "reader.verse.download".localized

        let playStateText = (entity.isPlaying ? "reader.playback.playing" : "reader.playback.paused").localized
        state.nowPlayingText = String(
            format: "reader.playback.nowPlayingFormat".localized,
            playStateText,
            sutra?.narrator ?? ""
        )
        state.elapsedText = formatTime(seconds: entity.elapsedSeconds)
        state.speedText = String(format: "reader.playback.speedFormat".localized, entity.playbackSpeed)

        if let total = sutra?.totalDurationSeconds, total > 0 {
            state.playbackProgress = min(1, max(0, Double(entity.elapsedSeconds) / Double(total)))
        }
        state.isPlaying = entity.isPlaying

        return state
    }

    /// "724" -> "12:04".
    private static func formatTime(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "reader.playback.timeFormat".localized, clamped / 60, clamped % 60)
    }
}
