//
//  ILFamilyTreeCreateViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFamilyTreeCreateNavEvent: Equatable {
    case back
    /// The tree was validated and saved; the owning coordinator hands it back to the tree screen.
    case created(ILFamilyTreeEntity)
}

protocol ILFamilyTreeCreateViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the owning `ILFamilyTreeCreateCoordinator` subscribes
    /// to this directly in `start()`, before the ViewController exists.
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeCreateNavEvent, Never> { get }
}

final class ILFamilyTreeCreateViewModel: ILFamilyTreeCreateViewModelProtocol {

    private static let yearDigits = 4

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let clanNameChanged: AnyPublisher<String, Never>
        let hometownChanged: AnyPublisher<String, Never>
        let founderNameChanged: AnyPublisher<String, Never>
        let birthYearChanged: AnyPublisher<String, Never>
        /// true = "Còn sống", false = "Đã mất".
        let livingSelected: AnyPublisher<Bool, Never>
        let deathYearChanged: AnyPublisher<String, Never>
        let anniversaryChanged: AnyPublisher<String, Never>
        let spouseNameChanged: AnyPublisher<String, Never>
        let createTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILFamilyTreeCreateStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILFamilyTreeCreateNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILFamilyTreeCreateNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILFamilyTreeCreateStateModel>, Never>
    private var currentState: ILFamilyTreeCreateStateModel
    private let useCase: ILFamilyTreeCreateUseCase
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILFamilyTreeCreateUseCase, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
        self.currentState = .initial
        self.stateSubject = CurrentValueSubject(.success(.initial))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.publish() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.clanNameChanged
            .sink { [weak self] text in self?.edit { $0.clanName = text } }
            .store(in: &cancellables)

        input.hometownChanged
            .sink { [weak self] text in self?.edit { $0.hometown = text } }
            .store(in: &cancellables)

        input.founderNameChanged
            .sink { [weak self] text in self?.edit { $0.founderName = text } }
            .store(in: &cancellables)

        input.birthYearChanged
            .sink { [weak self] text in self?.edit { $0.birthYear = Self.yearText(text) } }
            .store(in: &cancellables)

        input.livingSelected
            .sink { [weak self] isLiving in self?.edit { $0.isFounderLiving = isLiving } }
            .store(in: &cancellables)

        input.deathYearChanged
            .sink { [weak self] text in self?.edit { $0.deathYear = Self.yearText(text) } }
            .store(in: &cancellables)

        input.anniversaryChanged
            .sink { [weak self] text in self?.edit { $0.anniversary = text } }
            .store(in: &cancellables)

        input.spouseNameChanged
            .sink { [weak self] text in self?.edit { $0.spouseName = text } }
            .store(in: &cancellables)

        input.createTapped
            .sink { [weak self] _ in self?.handleCreateTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleCreateTapped() {
        guard !currentState.isSubmitting else { return }
        let year = Calendar.current.component(.year, from: now())

        switch useCase.createTree(from: currentState.draft, currentYear: year) {
        case .failure(let issue):
            currentState.errorField = issue.field
            currentState.errorMessage = issue.message
            publish()
        case .success(let tree):
            currentState.errorField = nil
            currentState.errorMessage = nil
            currentState.isSubmitting = true
            publish()
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.useCase.save(tree)
                    self.currentState.isSubmitting = false
                    self.publish()
                    self.navigationEventSubject.send(.created(tree))
                } catch {
                    self.currentState.isSubmitting = false
                    self.publish() // release the button before the error is shown
                    self.stateSubject.send(.failure(error))
                }
            }
        }
    }

    // MARK: - State helpers
    /// Applies one field edit, clears any shown error (it may no longer apply) and refreshes the header.
    private func edit(_ change: (inout ILFamilyTreeCreateStateModel) -> Void) {
        change(&currentState)
        currentState.errorField = nil
        currentState.errorMessage = nil
        refreshHeader()
        publish()
    }

    private func refreshHeader() {
        let clan = useCase.clanDisplayName(currentState.clanName)
        currentState.headerTitle = clan.isEmpty ? ILFamilyTreeCreateStateModel.initial.headerTitle : clan

        let founder = currentState.founderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [
            currentState.hometown.trimmingCharacters(in: .whitespacesAndNewlines),
            founder.isEmpty ? "" : String(format: "familyTreeCreate.header.subtitle.founder".localized, founder)
        ].filter { !$0.isEmpty }
        currentState.headerSubtitle = parts.isEmpty
            ? ILFamilyTreeCreateStateModel.initial.headerSubtitle
            : parts.joined(separator: " · ")
    }

    /// Years take digits only, at most four.
    private static func yearText(_ text: String) -> String {
        String(text.filter(\.isNumber).prefix(yearDigits))
    }

    private func publish() {
        stateSubject.send(.success(currentState))
    }
}
