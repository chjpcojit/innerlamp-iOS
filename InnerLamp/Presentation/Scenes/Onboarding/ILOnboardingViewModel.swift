//
//  ILOnboardingViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import Foundation
import Combine

enum ILOnboardingNavEvent: Equatable {
    case goToSignup
    case goToLogin
}

protocol ILOnboardingViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILOnboardingCoordinator` subscribes to
    /// this directly in `start()`, before the ViewController exists (see
    /// references/coordinator_navigation_rules.md).
    var navigationEventPublisher: AnyPublisher<ILOnboardingNavEvent, Never> { get }
}

final class ILOnboardingViewModel: ILOnboardingViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let nextTrigger: AnyPublisher<Void, Never>
        let backTrigger: AnyPublisher<Void, Never>
        let skipTrigger: AnyPublisher<Void, Never>
        /// `stepIndex` = vị trí tuyệt đối trong `steps`, `itemIndex` = vị trí item trong step đó —
        /// dùng chung cho mọi step dạng "chọn từ list" (chip hoặc toggle).
        let toggleItem: AnyPublisher<(stepIndex: Int, itemIndex: Int), Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILOnboardingStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILOnboardingNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    /// Snapshot đồng bộ của state hiện tại — dùng bởi `ILOnboardingViewController` để dựng
    /// `stepViews`/`progressBar` một lần lúc `setupViews()`, trước khi `bindViewModel()` chạy và
    /// `transform(input:)` tồn tại. Không dùng để nhận cập nhật liên tục — cho việc đó dùng
    /// `Output.state`.
    var state: ILOnboardingStateModel { currentState }

    private let navigationEventSubject = PassthroughSubject<ILOnboardingNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILOnboardingStateModel>, Never>
    private var currentState: ILOnboardingStateModel
    private let useCase: ILOnboardingUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILOnboardingUseCase) {
        self.useCase = useCase
        let initialState = useCase.getInitialState()
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.nextTrigger
            .sink { [weak self] _ in self?.handleNext() }
            .store(in: &cancellables)

        input.backTrigger
            .sink { [weak self] _ in self?.handleBack() }
            .store(in: &cancellables)

        input.skipTrigger
            .sink { [weak self] _ in self?.handleSkip() }
            .store(in: &cancellables)

        input.toggleItem
            .sink { [weak self] pair in self?.handleToggleItem(stepIndex: pair.stepIndex, itemIndex: pair.itemIndex) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        currentState = useCase.getInitialState()
        stateSubject.send(.success(currentState))
    }

    private func handleNext() {
        if !currentState.isLastStep {
            currentState.currentStep += 1
            stateSubject.send(.success(currentState))
        } else {
            useCase.savePreferences(state: currentState)
            navigationEventSubject.send(.goToSignup)
        }
    }

    private func handleBack() {
        if currentState.currentStep > 0 {
            currentState.currentStep -= 1
            stateSubject.send(.success(currentState))
        } else {
            navigationEventSubject.send(.goToLogin)
        }
    }

    private func handleSkip() {
        useCase.savePreferences(state: currentState)
        navigationEventSubject.send(.goToSignup)
    }

    /// Toggle item tại 1 step bất kỳ theo index tuyệt đối trong `steps` — điểm vào chính mà
    /// `ILOnboardingViewController` gọi cho mọi step dạng "chọn từ list" (chip hoặc toggle),
    /// không quan tâm step đó là step thứ mấy hay tổng có bao nhiêu step.
    private func handleToggleItem(stepIndex: Int, itemIndex: Int) {
        currentState = currentState.togglingItem(atStep: stepIndex, itemIndex: itemIndex)
        stateSubject.send(.success(currentState))
    }
}
