//
//  ILMeritBookViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILMeritBookNavEvent: Equatable {
    /// Back chip — pop to the previous screen.
    case goBack
    /// "Cúng dường" pill in the header — the donation flow (`donate`, not built yet).
    case openDonate
}

protocol ILMeritBookViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILMeritBookCoordinator` subscribes in `start()`,
    /// before the view controller / `Input` exist.
    var navigationEventPublisher: AnyPublisher<ILMeritBookNavEvent, Never> { get }
}

final class ILMeritBookViewModel: ILMeritBookViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let donateTapped: AnyPublisher<Void, Never>
        let stopMonthlyTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILMeritBookStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILMeritBookNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILMeritBookNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILMeritBookStateModel>, Never>(.idle)
    private let useCase: ILMeritBookUseCase
    private let calendar: Calendar
    private let now: () -> Date
    private var entity: ILMeritBookEntity?
    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(
        useCase: ILMeritBookUseCase,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.useCase = useCase
        self.calendar = calendar
        self.now = now
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.donateTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openDonate) }
            .store(in: &cancellables)

        input.stopMonthlyTapped
            .sink { [weak self] _ in self?.stopMonthly() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func load() {
        loadTask?.cancel()
        stateSubject.send(.loading)
        loadTask = Task { [weak self, useCase] in
            do {
                let loaded = try await useCase.getMeritBook()
                guard !Task.isCancelled, let self else { return }
                self.entity = loaded
                self.publish()
            } catch {
                guard !Task.isCancelled, let self else { return }
                self.stateSubject.send(.failure(error))
            }
        }
    }

    private func stopMonthly() {
        guard entity?.monthlySupport != nil else { return }
        Task { [weak self, useCase] in
            do {
                try await useCase.stopMonthlySupport()
                guard let self, let current = self.entity else { return }
                self.entity = ILMeritBookEntity(
                    offerings: current.offerings,
                    letter: current.letter,
                    monthlySupport: nil,
                    buildProject: current.buildProject
                )
                self.publish()
            } catch {
                self?.stateSubject.send(.failure(error))
            }
        }
    }

    private func publish() {
        guard let entity else { return }
        stateSubject.send(.success(makeStateModel(from: entity)))
    }

    // MARK: - Entity -> StateModel mapping
    private func makeStateModel(from entity: ILMeritBookEntity) -> ILMeritBookStateModel {
        var model = ILMeritBookStateModel()
        model.stats = makeStats(from: entity.offerings)
        model.history = entity.offerings
            .sorted { $0.date > $1.date }
            .map(makeHistoryRow)
        model.letter = entity.letter.map {
            .init(
                body: $0.body,
                signature: String(format: "meritBook.letter.signatureFormat".localized, $0.signerName, $0.signerTitle)
            )
        }
        model.monthly = entity.monthlySupport.map {
            .init(
                title: String(format: "meritBook.monthly.titleFormat".localized, Self.money($0.amount)),
                subtitle: String(format: "meritBook.monthly.subtitleFormat".localized, $0.templeName)
            )
        }
        model.buildProject = entity.buildProject.map(makeBuildProject)
        return model
    }

    private func makeStats(from offerings: [ILMeritOfferingEntity]) -> [ILMeritBookStateModel.Stat] {
        let year = calendar.component(.year, from: now())
        let yearTotal = offerings
            .filter { calendar.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.amount }
        let lampCount = offerings.filter { $0.purpose == .templeLamp }.count
        let templeCount = Set(offerings.map(\.templeName)).count
        return [
            .init(
                value: Self.compactAmount(yearTotal),
                caption: String(format: "meritBook.stats.yearTotalFormat".localized, year)
            ),
            .init(value: String(lampCount), caption: "meritBook.stats.lamps".localized),
            .init(value: String(templeCount), caption: "meritBook.stats.temples".localized)
        ]
    }

    private func makeHistoryRow(_ offering: ILMeritOfferingEntity) -> ILMeritBookStateModel.HistoryRow {
        .init(
            id: offering.id,
            title: Self.purposeTitle(offering.purpose),
            subtitle: "\(offering.templeName) · \(formatDate(offering.date))",
            amount: Self.money(offering.amount),
            statusText: (offering.isConfirmedByTemple
                ? "meritBook.history.status.confirmed"
                : "meritBook.history.status.pending").localized,
            isConfirmed: offering.isConfirmedByTemple
        )
    }

    private func makeBuildProject(_ project: ILMeritBuildProjectEntity) -> ILMeritBookStateModel.BuildProject {
        let ratio = project.goalMillions > 0
            ? Double(project.raisedMillions) / Double(project.goalMillions)
            : 0
        return .init(
            name: project.name,
            subtitle: project.subtitle,
            progress: ratio,
            progressLine: String(
                format: "meritBook.build.progressFormat".localized,
                project.raisedMillions,
                project.goalMillions
            ),
            percentText: "\(Int((ratio * 100).rounded()))%",
            lines: project.expenses.map { .init(label: $0.label, value: Self.money($0.amount)) },
            updatedText: String(format: "meritBook.build.updatedFormat".localized, formatDate(project.updatedAt))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private static func purposeTitle(_ purpose: ILMeritPurpose) -> String {
        switch purpose {
        case .threeJewels: return "meritBook.purpose.threeJewels".localized
        case .monkMeal: return "meritBook.purpose.monkMeal".localized
        case .templeLamp: return "meritBook.purpose.templeLamp".localized
        case .construction: return "meritBook.purpose.construction".localized
        case .charityKitchen: return "meritBook.purpose.charityKitchen".localized
        case .lifeRelease: return "meritBook.purpose.lifeRelease".localized
        }
    }

    // MARK: - Formatting
    /// "200.000đ" — dot-grouped whole VND, independent of the device locale.
    static func money(_ amount: Int) -> String {
        let digits = String(max(0, amount))
        var grouped = ""
        for (offset, character) in digits.reversed().enumerated() {
            if offset > 0, offset % 3 == 0 { grouped.append(".") }
            grouped.append(character)
        }
        return String(grouped.reversed()) + "đ"
    }

    /// "1,1 tr" for >= 1 million, "300k" for >= 1000, otherwise the plain number (design `compact`).
    static func compactAmount(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            let millions = (Double(amount) / 100_000).rounded() / 10
            let text = millions == millions.rounded()
                ? String(Int(millions))
                : String(millions).replacingOccurrences(of: ".", with: ",")
            return String(format: "meritBook.stats.millionFormat".localized, text)
        }
        if amount >= 1_000 {
            return "\(Int((Double(amount) / 1_000).rounded()))k"
        }
        return String(amount)
    }
}
