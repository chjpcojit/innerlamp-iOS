//
//  ILTalkViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation
import Combine

enum ILTalkNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn Pháp thoại.
    case back
    /// Thẻ "Nghe xong, ngồi thiền 10 phút" — mở màn Chuẩn bị thiền (modal full-screen).
    case openMeditationSetup
}

protocol ILTalkViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILTalkCoordinator` subscribe trực tiếp trong `start()`,
    /// trước khi `ViewController`/`Input` tồn tại (xem `references/coordinator_navigation_rules.md`).
    var navigationEventPublisher: AnyPublisher<ILTalkNavEvent, Never> { get }
}

final class ILTalkViewModel: ILTalkViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let playPauseTapped: AnyPublisher<Void, Never>
        let rewindTapped: AnyPublisher<Void, Never>
        let forwardTapped: AnyPublisher<Void, Never>
        let meditateTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILTalkStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILTalkNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILTalkNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILTalkStateModel>, Never>
    private var currentEntity: ILTalkEntity
    private var currentState: ILTalkStateModel
    private let useCase: ILTalkUseCase
    private let initialTalkID: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILTalkUseCase, talkID: String) {
        self.useCase = useCase
        self.initialTalkID = talkID
        let initialEntity = useCase.getInitialState(talkID: talkID)
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

        input.playPauseTapped
            .sink { [weak self] _ in self?.handlePlayPauseTapped() }
            .store(in: &cancellables)

        input.rewindTapped
            .sink { [weak self] _ in self?.handleRewindTapped() }
            .store(in: &cancellables)

        input.forwardTapped
            .sink { [weak self] _ in self?.handleForwardTapped() }
            .store(in: &cancellables)

        input.meditateTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openMeditationSetup) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState(talkID: initialTalkID))
    }

    private func handlePlayPauseTapped() {
        applyEntity(useCase.togglePlayPause(currentEntity))
    }

    private func handleRewindTapped() {
        applyEntity(useCase.rewind(currentEntity))
    }

    private func handleForwardTapped() {
        applyEntity(useCase.forward(currentEntity))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (format "12:48", "-33:12", "2.4k",
    /// "00:00", dòng meta) nên nằm ở đây, không phải trong một Mapper dùng chung — xem
    /// `references/data_layer_boundaries.md`.
    private func applyEntity(_ entity: ILTalkEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(from: entity, useCase: useCase)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILTalkEntity,
        useCase: ILTalkUseCase
    ) -> ILTalkStateModel {
        var state = ILTalkStateModel()

        state.headerTitle = "talk.header.title".localized

        if let talk = useCase.currentTalk(in: entity) {
            state.eyebrow = talk.eyebrow
            state.title = talk.title
            state.narratorInitial = talk.narratorInitial
            state.metaText = String(
                format: "talk.meta.format".localized,
                talk.narrator,
                String(format: "talk.duration.minutes".localized, talk.durationMinutes),
                formatListenCount(talk.listenCount)
            )
            state.descriptionText = talk.description
            state.chapters = talk.chapters.enumerated().map { index, chapter in
                ILTalkChapterModel(
                    id: chapter.id,
                    timestampText: String(
                        format: "talk.chapter.timestamp".localized,
                        chapter.timestampSeconds / 60,
                        chapter.timestampSeconds % 60
                    ),
                    title: chapter.title,
                    isCurrent: index == 0
                )
            }

            let total = talk.totalDurationSeconds
            let elapsed = max(0, entity.elapsedSeconds)
            state.elapsedText = String(format: "talk.time.elapsed".localized, elapsed / 60, elapsed % 60)
            if total > 0 {
                let remaining = max(0, total - elapsed)
                state.remainingText = String(
                    format: "talk.time.remaining".localized,
                    remaining / 60,
                    remaining % 60
                )
                state.playbackProgress = min(1, max(0, Double(elapsed) / Double(total)))
            }
        }

        state.isPlaying = entity.isPlaying

        state.rewindTitle = "talk.seek.rewind".localized
        state.forwardTitle = "talk.seek.forward".localized
        state.sectionsTitle = "talk.sections.title".localized
        state.meditateTitle = "talk.meditate.title".localized
        state.meditateSubtitle = "talk.meditate.subtitle".localized

        return state
    }

    /// 2400 → "2.4k"; 980 → "980" — số lượt nghe nén gọn ở dòng meta hero.
    private static func formatListenCount(_ count: Int) -> String {
        guard count >= 1000 else { return String(count) }
        let value = Double(count) / 1000.0
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "talk.listenCount.wholeThousands".localized, Int(value))
        }
        return String(format: "talk.listenCount.thousands".localized, value)
    }
}
