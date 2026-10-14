//
//  ILDonateViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILDonateNavEvent: Equatable {
    case close
}

protocol ILDonateViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — the coordinator subscribes in `startModal()`.
    var navigationEventPublisher: AnyPublisher<ILDonateNavEvent, Never> { get }
}

final class ILDonateViewModel: ILDonateViewModelProtocol {

    struct Input {
        let closeTapped: AnyPublisher<Void, Never>
        /// Index into the amount options; the last index is "Tùy tâm".
        let amountSelected: AnyPublisher<Int, Never>
        let customAmountChanged: AnyPublisher<String, Never>
        let messageChanged: AnyPublisher<String, Never>
        let continueTapped: AnyPublisher<Void, Never>
        let changeAmountTapped: AnyPublisher<Void, Never>
        let confirmTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILDonateStateModel>, Never>
    }

    static let maxMessageLength = 120

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILDonateNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILDonateNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILDonateStateModel>, Never>(.success(.initial))
    private var step: ILDonateStateModel.Step = .form
    private var selectedIndex: Int
    private var customDigits = ""
    private var message = ""
    private var cancellables = Set<AnyCancellable>()
    private let useCase: ILDonateUseCase

    // MARK: - Initializer
    init(useCase: ILDonateUseCase) {
        self.useCase = useCase
        self.selectedIndex = useCase.defaultPresetIndex
        render()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.closeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.close) }
            .store(in: &cancellables)

        input.amountSelected
            .sink { [weak self] index in self?.selectAmount(at: index) }
            .store(in: &cancellables)

        input.customAmountChanged
            .sink { [weak self] text in self?.updateCustom(text) }
            .store(in: &cancellables)

        input.messageChanged
            .sink { [weak self] text in self?.updateMessage(text) }
            .store(in: &cancellables)

        input.continueTapped
            .sink { [weak self] _ in self?.handleContinue() }
            .store(in: &cancellables)

        input.changeAmountTapped
            .sink { [weak self] _ in self?.moveTo(.form, from: .transfer) }
            .store(in: &cancellables)

        input.confirmTapped
            .sink { [weak self] _ in self?.moveTo(.thanks, from: .transfer) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private var customOptionIndex: Int { useCase.presetAmounts.count }

    private var amount: Int {
        if selectedIndex < useCase.presetAmounts.count { return useCase.presetAmounts[selectedIndex] }
        return Int(customDigits) ?? 0
    }

    private func selectAmount(at index: Int) {
        guard step == .form, (0...customOptionIndex).contains(index) else { return }
        selectedIndex = index
        render()
    }

    private func updateCustom(_ text: String) {
        guard step == .form else { return }
        customDigits = useCase.sanitizeCustomDigits(text)
        render()
    }

    private func updateMessage(_ text: String) {
        guard step == .form else { return }
        message = String(text.prefix(Self.maxMessageLength))
        render()
    }

    private func handleContinue() {
        guard step == .form, useCase.isValid(amount: amount) else { return }
        step = .transfer
        render()
    }

    private func moveTo(_ target: ILDonateStateModel.Step, from source: ILDonateStateModel.Step) {
        guard step == source else { return }
        step = target
        render()
    }

    // MARK: - State mapping
    private func render() {
        var state = ILDonateStateModel()
        state.step = step
        state.amountOptions = useCase.presetAmounts.enumerated().map {
            .init(title: Self.format($0.element), isSelected: $0.offset == selectedIndex)
        } + [.init(title: "donate.amount.custom".localized, isSelected: selectedIndex == customOptionIndex)]
        state.isCustomSelected = selectedIndex == customOptionIndex
        state.customText = customDigits.isEmpty ? "" : Self.grouped(Int(customDigits) ?? 0)
        state.message = message

        let isValid = useCase.isValid(amount: amount)
        state.isCTAEnabled = isValid
        state.ctaTitle = isValid
            ? String(format: "donate.cta.format".localized, Self.format(amount))
            : String(format: "donate.cta.minimum.format".localized, Self.format(useCase.minimumAmount))

        if isValid {
            let transfer = useCase.makeTransfer(amount: amount)
            state.qrPayload = transfer.account.qrPayload
            state.infoRows = [
                .init(title: "donate.info.recipient".localized, value: transfer.account.recipient),
                .init(title: "donate.info.bank".localized, value: transfer.account.bank),
                .init(title: "donate.info.amount".localized, value: Self.format(transfer.amount)),
                .init(title: "donate.info.note".localized, value: transfer.note)
            ]
            state.thanksText = String(format: "donate.thanks.body.format".localized, Self.format(transfer.amount))
        }
        stateSubject.send(.success(state))
    }

    // MARK: - Formatting
    /// "150000" -> "150.000" — fixed separator, independent of the device locale.
    static func grouped(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = "."
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// "50.000₫"
    static func format(_ amount: Int) -> String {
        grouped(amount) + "₫"
    }
}
