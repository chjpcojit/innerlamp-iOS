//
//  ILAddTempleViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILAddTempleNavEvent: Equatable {
    case back
    /// Form hợp lệ — trả đề xuất về màn gọi.
    case submitted(ILTempleProposalEntity)
}

final class ILAddTempleViewModel: ViewModelType {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let nameChanged: AnyPublisher<String, Never>
        let provinceChanged: AnyPublisher<String, Never>
        let addressChanged: AnyPublisher<String, Never>
        let submitTapped: AnyPublisher<Void, Never>
        let cancelTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILAddTempleStateModel>, Never>
    }

    // MARK: - Properties
    /// Độc lập với `transform(input:)` — coordinator subscribe trực tiếp trong `start()`.
    var navigationEventPublisher: AnyPublisher<ILAddTempleNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    var state: ILAddTempleStateModel { currentState }

    private let navigationEventSubject = PassthroughSubject<ILAddTempleNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILAddTempleStateModel>, Never>
    private var currentState: ILAddTempleStateModel
    private let useCase: ILAddTempleUseCase
    private let existingPlaces: [ILOrdinationPlaceEntity]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILAddTempleUseCase, prefillName: String, existingPlaces: [ILOrdinationPlaceEntity]) {
        self.useCase = useCase
        self.existingPlaces = existingPlaces
        var initial = ILAddTempleStateModel.initial
        initial.name = prefillName
        self.currentState = initial
        self.stateSubject = CurrentValueSubject(.success(initial))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                guard let self else { return }
                stateSubject.send(.success(currentState))
            }
            .store(in: &cancellables)

        input.nameChanged
            .sink { [weak self] text in self?.update { $0.name = text } }
            .store(in: &cancellables)

        input.provinceChanged
            .sink { [weak self] text in self?.update { $0.province = text } }
            .store(in: &cancellables)

        input.addressChanged
            .sink { [weak self] text in self?.update { $0.address = text } }
            .store(in: &cancellables)

        input.submitTapped
            .sink { [weak self] _ in self?.handleSubmit() }
            .store(in: &cancellables)

        input.cancelTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    /// Gõ lại thì xoá lỗi đang hiện.
    private func update(_ change: (inout ILAddTempleStateModel) -> Void) {
        change(&currentState)
        currentState.errorMessage = nil
        currentState.errorField = nil
        stateSubject.send(.success(currentState))
    }

    private func handleSubmit() {
        let error = useCase.validate(
            name: currentState.name,
            province: currentState.province,
            existing: existingPlaces
        )
        guard let error else {
            let proposal = useCase.makeProposal(
                name: currentState.name,
                province: currentState.province,
                address: currentState.address
            )
            navigationEventSubject.send(.submitted(proposal))
            return
        }

        switch error {
        case .nameRequired:
            currentState.errorMessage = "addTemple.error.name".localized
            currentState.errorField = .name
        case .provinceRequired:
            currentState.errorMessage = "addTemple.error.province".localized
            currentState.errorField = .province
        case .duplicate(let name):
            currentState.errorMessage = String(format: "addTemple.error.duplicate".localized, name)
            currentState.errorField = .name
        }
        stateSubject.send(.success(currentState))
    }
}
