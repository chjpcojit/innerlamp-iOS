//
//  ILLampGardenViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILLampGardenNavEvent: Equatable {
    case back
    /// Header action "Thắp đèn" — open a fresh lighting form.
    case openLighting
}

protocol ILLampGardenViewModelProtocol: ViewModelType {
    var navigationEventPublisher: AnyPublisher<ILLampGardenNavEvent, Never> { get }
}

final class ILLampGardenViewModel: ILLampGardenViewModelProtocol {

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let lightTapped: AnyPublisher<Void, Never>
        /// `nil` selects "Tất cả".
        let filterSelected: AnyPublisher<ILLampKind?, Never>
        let loadMoreTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILLampGardenStateModel>, Never>
    }

    // MARK: - Properties
    /// Lamps shown per page; "Xem thêm đèn" reveals the next page.
    static let pageSize = 12

    var navigationEventPublisher: AnyPublisher<ILLampGardenNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILLampGardenNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILLampGardenStateModel>, Never>(.success(.initial))
    private var lamps: [ILLampEntity] = []
    private var filter: ILLampKind?
    private var visibleCount = ILLampGardenViewModel.pageSize
    private var cancellables = Set<AnyCancellable>()
    private let useCase: ILLightLampUseCase
    private let now: () -> Date

    // MARK: - Initializer
    init(useCase: ILLightLampUseCase, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.lightTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openLighting) }
            .store(in: &cancellables)

        input.filterSelected
            .sink { [weak self] kind in
                guard let self, self.filter != kind else { return }
                self.filter = kind
                self.visibleCount = Self.pageSize
                self.render()
            }
            .store(in: &cancellables)

        input.loadMoreTapped
            .sink { [weak self] _ in
                guard let self else { return }
                self.visibleCount += Self.pageSize
                self.render()
            }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func load() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.lamps = try await self.useCase.loadActiveLamps(now: self.now())
                self.render()
            } catch {
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // @ai: assumption — see Docs/Assumptions/LightLamp/AS-LightLamp-002-garden-shows-own-lamps-only.md
    // MARK: - Lamps -> StateModel mapping
    private func render() {
        let currentNow = now()
        let matching = lamps.filter { filter == nil || $0.kind == filter }

        var state = ILLampGardenStateModel()
        state.subtitle = String(format: "lightLamp.garden.subtitle.format".localized, lamps.count)

        let allChip = ILLampGardenStateModel.Chip(
            kind: nil,
            title: "lightLamp.garden.filter.all".localized,
            count: String(lamps.count),
            isSelected: filter == nil
        )
        state.chips = [allChip] + ILLampKind.allCases.map { kind in
            .init(
                kind: kind,
                title: ILLightLampViewModel.title(of: kind),
                count: String(lamps.filter { $0.kind == kind }.count),
                isSelected: filter == kind
            )
        }

        state.cards = matching.prefix(visibleCount).map { lamp in
            .init(
                id: lamp.id,
                kind: lamp.kind,
                kindName: ILLightLampViewModel.title(of: lamp.kind),
                title: "\("lightLamp.garden.card.owner".localized) · \(ILLightLampViewModel.title(of: lamp.intention))",
                target: Self.targetText(lamp.target),
                remaining: Self.remainingText(daysLeft: lamp.daysLeft(now: currentNow))
            )
        }
        state.hasMore = matching.count > visibleCount
        state.isEmpty = matching.isEmpty
        stateSubject.send(.success(state))
    }

    private static func targetText(_ target: String) -> String {
        guard let first = target.first else { return "lightLamp.garden.card.target.all".localized }
        // "Cho " + the name with its first letter lower-cased, like the design ("Cho mẹ Hoa").
        let lowered = String(first).lowercased() + target.dropFirst()
        return String(format: "lightLamp.garden.card.target.format".localized, lowered)
    }

    private static func remainingText(daysLeft: Int) -> String {
        daysLeft <= 1
            ? "lightLamp.garden.card.left.lastDay".localized
            : String(format: "lightLamp.garden.card.left.format".localized, daysLeft)
    }
}
