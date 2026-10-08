//
//  ILSplashViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILSplashNavEvent: Equatable {
    case goToOnboarding
    case goToMain
}

protocol ILSplashViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILSplashCoordinator` subscribes to
    /// this directly in `start()`, before the ViewController exists (see
    /// references/coordinator_navigation_rules.md).
    var navigationEventPublisher: AnyPublisher<ILSplashNavEvent, Never> { get }
}

final class ILSplashViewModel: ILSplashViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Gửi bởi `ILSplashViewController` sau khi màn hình đã hiện đủ lâu để người dùng
        /// thấy trọn animation thương hiệu.
        let splashFinished: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILSplashStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILSplashNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILSplashNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILSplashStateModel>, Never>
    private var currentState: ILSplashStateModel
    private let useCase: ILSplashUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILSplashUseCase) {
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

        input.splashFinished
            .sink { [weak self] _ in self?.handleSplashFinished() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        currentState = useCase.getInitialState()
        stateSubject.send(.success(currentState))
    }

    /// Quyết định điểm đến kế tiếp sau khi màn Splash chạy xong.
    private func handleSplashFinished() {
        navigationEventSubject.send(useCase.hasSession() ? .goToMain : .goToOnboarding)
    }
}
