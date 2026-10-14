//
//  ILDonateViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILDonateViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILDonateViewModel
    private var cancellables = Set<AnyCancellable>()
    private var appliedStep: ILDonateStateModel.Step = .form

    private let closeTappedSubject = PassthroughSubject<Void, Never>()
    private let amountSelectedSubject = PassthroughSubject<Int, Never>()
    private let customAmountChangedSubject = PassthroughSubject<String, Never>()
    private let messageChangedSubject = PassthroughSubject<String, Never>()
    private let continueTappedSubject = PassthroughSubject<Void, Never>()
    private let changeAmountTappedSubject = PassthroughSubject<Void, Never>()
    private let confirmTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var backgroundView: ILImmersiveBackgroundView = {
        let view = ILImmersiveBackgroundView()
        return view
    }()

    private lazy var headerBand: ILStickyHeaderBand = {
        let band = ILStickyHeaderBand(tintColor: ILColors.medBackgroundCenter, tintRestAlpha: 0)
        return band
    }()

    private lazy var headerView: ILNavBar = {
        let navBar = ILNavBar(
            title: "donate.title".localized,
            showBack: false,
            showClose: true
        )
        return navBar
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    // Form
    private lazy var formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    private lazy var logoView: ILLogoView = {
        let view = ILLogoView(size: 80)
        return view
    }()

    private lazy var amountGrid: ILDonateAmountGridView = {
        let view = ILDonateAmountGridView()
        return view
    }()

    private lazy var customField: ILInputCardView = {
        let field = ILInputCardView(label: "", placeholder: "donate.custom.placeholder".localized)
        field.keyboardType = .numberPad
        field.isHidden = true
        return field
    }()

    private lazy var messageField: ILInputCardView = {
        let field = ILInputCardView(label: "", placeholder: "donate.message.placeholder".localized)
        return field
    }()

    private lazy var continueButton: ILButton = {
        let button = ILButton(title: "", variant: .gold)
        return button
    }()

    private lazy var laterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("common.later".localized, for: .normal)
        button.setTitleColor(ILColors.medInkTertiary, for: .normal)
        button.titleLabel?.font = ILTypography.bodySmall
        return button
    }()

    // Transfer
    private lazy var transferStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.spaceMedium
        stack.isHidden = true
        return stack
    }()

    private lazy var qrView: ILDonateQRView = {
        let view = ILDonateQRView()
        return view
    }()

    private lazy var infoTable: ILDonateInfoTableView = {
        let view = ILDonateInfoTableView()
        return view
    }()

    private lazy var confirmButton: ILButton = {
        let button = ILButton(title: "donate.confirm".localized, variant: .gold)
        return button
    }()

    private lazy var changeAmountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("donate.changeAmount".localized, for: .normal)
        button.setTitleColor(ILColors.medInkTertiary, for: .normal)
        button.titleLabel?.font = ILTypography.bodySmall
        return button
    }()

    // Thanks
    private lazy var thanksView: ILDonateThanksView = {
        let view = ILDonateThanksView()
        view.isHidden = true
        return view
    }()

    // MARK: - Initializer
    init(viewModel: ILDonateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyHeaderInset()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onClose = { [weak self] in self?.closeTappedSubject.send(()) }
        headerBand.addSubview(headerView)
        headerBand.bind(to: scrollView)

        amountGrid.onSelect = { [weak self] index in self?.amountSelectedSubject.send(index) }
        customField.onTextChanged = { [weak self] text in self?.customAmountChangedSubject.send(text) }
        messageField.onTextChanged = { [weak self] text in self?.messageChangedSubject.send(text) }
        continueButton.onTap = { [weak self] in self?.continueTappedSubject.send(()) }
        laterButton.addAction(UIAction { [weak self] _ in self?.closeTappedSubject.send(()) }, for: .touchUpInside)
        confirmButton.onTap = { [weak self] in self?.confirmTappedSubject.send(()) }
        changeAmountButton.addAction(
            UIAction { [weak self] _ in self?.changeAmountTappedSubject.send(()) },
            for: .touchUpInside
        )
        thanksView.onBack = { [weak self] in self?.closeTappedSubject.send(()) }

        buildFormStack()
        buildTransferStack()

        [formStack, transferStack, thanksView].forEach { contentStack.addArrangedSubview($0) }

        [backgroundView, scrollView, headerBand, headerView, contentStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        [backgroundView, scrollView, headerBand].forEach { view.addSubview($0) }
        scrollView.addSubview(contentStack)
    }

    private func buildFormStack() {
        let logoRow = UIStackView(arrangedSubviews: [logoView])
        logoRow.alignment = .center
        logoRow.axis = .vertical

        let heading = makeLabel(
            text: "donate.heading".localized,
            font: ILTypography.displayLarge,
            color: ILColors.medInk,
            alignment: .center
        )
        let intro = makeLabel(
            text: "donate.intro".localized,
            font: ILTypography.scriptureDescription,
            color: ILColors.medInkStrong,
            alignment: .center
        )

        let uses = UIStackView(
            arrangedSubviews: ["donate.use.servers", "donate.use.content", "donate.use.features"].map {
                makeUseRow(text: $0.localized)
            }
        )
        uses.axis = .vertical
        uses.spacing = ILMetrics.spaceMedium - 2

        let note = makeLabel(
            text: "donate.note".localized,
            font: ILTypography.bodySmall,
            color: ILColors.medInkTertiary,
            alignment: .center
        )

        [logoRow, heading, intro].forEach { formStack.addArrangedSubview($0) }
        formStack.setCustomSpacing(ILMetrics.groupSpacing, after: logoRow)
        formStack.setCustomSpacing(ILMetrics.spaceSmall, after: heading)
        formStack.addArrangedSubview(ILSectionEyebrowView(title: "donate.section.uses".localized))
        formStack.addArrangedSubview(uses)
        formStack.addArrangedSubview(ILSectionEyebrowView(title: "donate.section.amount".localized))
        [amountGrid, customField, messageField, continueButton, note, laterButton].forEach {
            formStack.addArrangedSubview($0)
        }
        formStack.setCustomSpacing(ILMetrics.groupSpacing, after: messageField)
    }

    private func buildTransferStack() {
        let title = makeLabel(
            text: "donate.transfer.title".localized,
            font: ILTypography.displayMedium,
            color: ILColors.medInk,
            alignment: .center
        )
        let subtitle = makeLabel(
            text: "donate.transfer.subtitle".localized,
            font: ILTypography.bodySmall,
            color: ILColors.medInkTertiary,
            alignment: .center
        )
        let qrRow = UIStackView(arrangedSubviews: [qrView])
        qrRow.axis = .vertical
        qrRow.alignment = .center

        [title, subtitle, qrRow, infoTable, confirmButton, changeAmountButton].forEach {
            transferStack.addArrangedSubview($0)
        }
        transferStack.setCustomSpacing(ILMetrics.groupSpacing, after: subtitle)
        transferStack.setCustomSpacing(ILMetrics.groupSpacing, after: qrRow)
        transferStack.setCustomSpacing(ILMetrics.groupSpacing, after: infoTable)
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            headerView.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.spaceSmall),

            // Scroll view runs under the header; its height is applied as top content inset.
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILDonateViewModel.Input(
            closeTapped: closeTappedSubject.eraseToAnyPublisher(),
            amountSelected: amountSelectedSubject.eraseToAnyPublisher(),
            customAmountChanged: customAmountChangedSubject.eraseToAnyPublisher(),
            messageChanged: messageChangedSubject.eraseToAnyPublisher(),
            continueTapped: continueTappedSubject.eraseToAnyPublisher(),
            changeAmountTapped: changeAmountTappedSubject.eraseToAnyPublisher(),
            confirmTapped: confirmTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)
    }

    // MARK: - Render
    private func render(state: ViewState<ILDonateStateModel>) {
        switch state {
        case .idle, .loading, .failure:
            break
        case .success(let model):
            updateUI(with: model)
        }
    }

    private func updateUI(with model: ILDonateStateModel) {
        amountGrid.configure(options: model.amountOptions)
        customField.isHidden = !model.isCustomSelected
        customField.text = model.customText
        messageField.text = model.message
        continueButton.title = model.ctaTitle
        continueButton.buttonState = model.isCTAEnabled ? .normal : .disabled

        qrView.configure(payload: model.qrPayload)
        infoTable.configure(rows: model.infoRows)
        thanksView.bodyText = model.thanksText

        guard model.step != appliedStep else { return }
        appliedStep = model.step
        view.endEditing(true)
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        UIView.transition(
            with: contentStack,
            duration: reduceMotion ? 0 : 0.2,
            options: [.transitionCrossDissolve, .allowUserInteraction]
        ) {
            self.formStack.isHidden = model.step != .form
            self.transferStack.isHidden = model.step != .transfer
            self.thanksView.isHidden = model.step != .thanks
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: false)
    }

    // MARK: - Helpers
    /// Pushes the content below the header; on the first layout the offset is set to the content top.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }

    private func makeLabel(text: String, font: UIFont, color: UIColor, alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = 0
        return label
    }

    private func makeUseRow(text: String) -> UIView {
        let badge = UIView()
        badge.backgroundColor = ILColors.medGoldTint
        badge.layer.cornerRadius = ILMetrics.sectionIconSize / 2
        let check = UIImageView(image: ILIcons.checkmark)
        check.tintColor = ILColors.goldDeep
        check.contentMode = .scaleAspectFit
        [badge, check].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        badge.addSubview(check)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: ILMetrics.sectionIconSize),
            badge.heightAnchor.constraint(equalToConstant: ILMetrics.sectionIconSize),
            check.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            check.widthAnchor.constraint(equalTo: badge.widthAnchor, multiplier: 0.55),
            check.heightAnchor.constraint(equalTo: badge.heightAnchor, multiplier: 0.55)
        ])

        let label = makeLabel(text: text, font: ILTypography.bodyLarge, color: ILColors.medInkStrong, alignment: .natural)
        let row = UIStackView(arrangedSubviews: [badge, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium - 2
        return row
    }
}
