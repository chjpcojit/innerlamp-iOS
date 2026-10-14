//
//  ILLightLampViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILLightLampNavEvent: Equatable {
    case back
    /// Header "Vườn đèn" or the completion action "Vào vườn đèn".
    case openGarden
}

protocol ILLightLampViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the coordinator subscribes in `start()`.
    var navigationEventPublisher: AnyPublisher<ILLightLampNavEvent, Never> { get }
}

final class ILLightLampViewModel: ILLightLampViewModelProtocol {

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let gardenTapped: AnyPublisher<Void, Never>
        let kindSelected: AnyPublisher<ILLampKind, Never>
        let intentionSelected: AnyPublisher<ILLampIntention, Never>
        let durationSelected: AnyPublisher<Int, Never>
        let targetChanged: AnyPublisher<String, Never>
        let vowChanged: AnyPublisher<String, Never>
        let lightTapped: AnyPublisher<Void, Never>
        let againTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILLightLampStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILLightLampNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILLightLampNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILLightLampStateModel>, Never>(.success(.initial))
    private var currentState = ILLightLampStateModel.initial
    private var draft = ILLampDraft()
    private var activeCount = 0
    private var cancellables = Set<AnyCancellable>()
    private let useCase: ILLightLampUseCase
    private let now: () -> Date
    /// How long the lamp takes to ignite before the completion state appears (design: ~2.1 s).
    private let igniteDelay: Duration

    // MARK: - Initializer
    init(
        useCase: ILLightLampUseCase,
        now: @escaping () -> Date = Date.init,
        igniteDelay: Duration = .milliseconds(2100)
    ) {
        self.useCase = useCase
        self.now = now
        self.igniteDelay = igniteDelay
        render()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.loadActiveCount() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.gardenTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openGarden) }
            .store(in: &cancellables)

        input.kindSelected
            .sink { [weak self] kind in self?.updateDraft { $0.kind = kind } }
            .store(in: &cancellables)

        input.intentionSelected
            .sink { [weak self] intention in self?.updateDraft { $0.intention = intention } }
            .store(in: &cancellables)

        input.durationSelected
            .sink { [weak self] days in self?.updateDraft { $0.durationDays = days } }
            .store(in: &cancellables)

        input.targetChanged
            .sink { [weak self] text in self?.updateDraft { $0.target = text } }
            .store(in: &cancellables)

        input.vowChanged
            .sink { [weak self] text in self?.updateDraft { $0.vow = text } }
            .store(in: &cancellables)

        input.lightTapped
            .sink { [weak self] _ in self?.handleLight() }
            .store(in: &cancellables)

        input.againTapped
            .sink { [weak self] _ in self?.handleAgain() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func loadActiveCount() {
        Task { [weak self] in
            guard let self else { return }
            // A failed count is not worth an error: the line falls back to "will shine in the garden".
            let lamps = try? await self.useCase.loadActiveLamps(now: self.now())
            self.activeCount = lamps?.count ?? 0
            self.render()
        }
    }

    /// Selections only change while the form is shown (the lamp is mid-ignition otherwise).
    private func updateDraft(_ change: (inout ILLampDraft) -> Void) {
        guard currentState.phase == .form else { return }
        change(&draft)
        render()
    }

    private func handleLight() {
        guard currentState.phase == .form else { return }
        currentState.phase = .lighting
        render()

        let snapshot = draft
        Task { [weak self] in
            guard let self else { return }
            do {
                let lamp = try await self.useCase.light(snapshot, now: self.now())
                // Let the ignition animation play out before the completion state replaces the form.
                try? await Task.sleep(for: self.igniteDelay)
                self.activeCount += 1
                self.currentState.completion = self.makeCompletion(for: lamp)
                self.currentState.phase = .done
                self.render()
            } catch {
                // Back to the form with every value kept; the controller shows the error.
                self.currentState.phase = .form
                self.render()
                self.stateSubject.send(.failure(error))
                self.stateSubject.send(.success(self.currentState))
            }
        }
    }

    /// "Thắp thêm đèn": empty form again, keeping kind / intention / duration.
    private func handleAgain() {
        guard currentState.phase == .done else { return }
        draft.target = ""
        draft.vow = ""
        currentState.completion = nil
        currentState.phase = .form
        render()
    }

    // MARK: - Draft -> StateModel mapping
    private func render() {
        var state = currentState
        state.selectedKind = draft.kind
        state.kicker = String(format: "lightLamp.stage.kicker.format".localized, Self.title(of: draft.kind).uppercased())
        state.countLine = activeCount > 0
            ? String(format: "lightLamp.stage.count.format".localized, activeCount)
            : "lightLamp.stage.count.none".localized
        state.kinds = ILLampKind.allCases.map {
            .init(kind: $0, title: Self.title(of: $0), isSelected: $0 == draft.kind)
        }
        state.intentions = ILLampIntention.allCases.map {
            .init(intention: $0, title: Self.title(of: $0), isSelected: $0 == draft.intention)
        }
        state.durationTitles = ILLampEntity.durationOptions.map {
            String(format: "lightLamp.duration.format".localized, $0)
        }
        state.selectedDurationIndex = ILLampEntity.durationOptions.firstIndex(of: draft.durationDays) ?? 0
        state.target = draft.target
        state.vow = draft.vow
        state.buttonTitle = state.phase == .lighting
            ? "lightLamp.button.lighting".localized
            : "lightLamp.button.light".localized
        currentState = state
        stateSubject.send(.success(state))
    }

    private func makeCompletion(for lamp: ILLampEntity) -> ILLightLampStateModel.Completion {
        let dedication = lamp.target.isEmpty
            ? "lightLamp.done.dedication.all".localized
            : String(format: "lightLamp.done.dedication.target".localized, lamp.target)
        return .init(
            caption: String(
                format: "lightLamp.done.caption.format".localized,
                Self.title(of: lamp.kind), Self.title(of: lamp.intention), lamp.durationDays
            ),
            dedication: dedication,
            vowQuote: lamp.vow.isEmpty ? "" : String(format: "lightLamp.done.vow.format".localized, lamp.vow)
        )
    }

    // MARK: - Titles
    static func title(of kind: ILLampKind) -> String {
        "lightLamp.kind.\(kind.rawValue)".localized
    }

    static func title(of intention: ILLampIntention) -> String {
        "lightLamp.intention.\(intention.rawValue)".localized
    }
}
