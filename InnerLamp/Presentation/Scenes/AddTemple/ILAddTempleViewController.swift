//
//  ILAddTempleViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILAddTempleViewController: BaseViewController, TransitionProviding {

    var pushTransition: NavigationTransitionAnimating? {
        CrossFadeTransition()
    }

    // MARK: - Properties
    private let viewModel: ILAddTempleViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let nameChangedSubject = PassthroughSubject<String, Never>()
    private let provinceChangedSubject = PassthroughSubject<String, Never>()
    private let addressChangedSubject = PassthroughSubject<String, Never>()
    private let submitTappedSubject = PassthroughSubject<Void, Never>()
    private let cancelTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView: ILNavBar = {
        let view = ILNavBar(title: "addTemple.header.title".localized)
        view.subtitle = "addTemple.header.subtitle".localized
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let introLabel = UILabel()
    private let nameField = ILField(
        label: "addTemple.field.name.label".localized,
        placeholder: "addTemple.field.name.placeholder".localized
    )
    private let provinceField = ILField(
        label: "addTemple.field.province.label".localized,
        placeholder: "addTemple.field.province.placeholder".localized
    )
    private let addressField = ILField(
        label: "addTemple.field.address.label".localized,
        placeholder: "addTemple.field.address.placeholder".localized
    )
    private let errorLabel = UILabel()

    private let footerContainer = UIView()
    private let footerDivider = UIView()
    private let submitButton = ILButton(title: "addTemple.cta.submit".localized, variant: .primary)
    private let cancelButton = ILButton(title: "addTemple.cta.cancel".localized, variant: .ghost)

    // MARK: - Initializer
    init(viewModel: ILAddTempleViewModel) {
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

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.cancelTappedSubject.send(()) }
        view.addSubview(headerView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        introLabel.numberOfLines = 0
        introLabel.attributedText = ILTypography.makeAttributedString(
            text: "addTemple.intro".localized,
            font: ILTypography.scriptureDescription,
            color: ILColors.inkSecondary,
            lineHeightMultiple: 1.6
        )

        nameField.innerTextField.returnKeyType = .next
        nameField.innerTextField.autocapitalizationType = .words
        nameField.onTextChanged = { [weak self] in self?.nameChangedSubject.send($0) }
        nameField.onReturn = { [weak self] in self?.provinceField.innerTextField.becomeFirstResponder() }

        provinceField.innerTextField.returnKeyType = .next
        provinceField.innerTextField.autocapitalizationType = .words
        provinceField.onTextChanged = { [weak self] in self?.provinceChangedSubject.send($0) }
        provinceField.onReturn = { [weak self] in self?.addressField.innerTextField.becomeFirstResponder() }

        addressField.innerTextField.returnKeyType = .done
        addressField.onTextChanged = { [weak self] in self?.addressChangedSubject.send($0) }
        addressField.onReturn = { [weak self] in self?.handleSubmitTapped() }

        errorLabel.font = ILTypography.bodyCompact
        errorLabel.textColor = ILColors.danger
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        contentStack.addArrangedSubview(introLabel)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: introLabel)
        [nameField, provinceField, addressField, errorLabel].forEach(contentStack.addArrangedSubview)

        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        footerDivider.translatesAutoresizingMaskIntoConstraints = false
        footerDivider.backgroundColor = ILColors.ink.withAlphaComponent(0.08)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.onTap = { [weak self] in self?.handleSubmitTapped() }
        cancelButton.onTap = { [weak self] in self?.cancelTappedSubject.send(()) }
        [footerDivider, submitButton, cancelButton].forEach(footerContainer.addSubview)
        view.addSubview(footerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()
        let side = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerContainer.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: side),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -side),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceLarge),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -side * 2),

            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            footerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            footerDivider.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            footerDivider.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            footerDivider.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            footerDivider.heightAnchor.constraint(equalToConstant: 1),

            submitButton.topAnchor.constraint(equalTo: footerDivider.bottomAnchor, constant: ILMetrics.spaceMedium),
            submitButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            submitButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),

            cancelButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: ILMetrics.rowSpacing),
            cancelButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),
            cancelButton.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILAddTempleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            nameChanged: nameChangedSubject.eraseToAnyPublisher(),
            provinceChanged: provinceChangedSubject.eraseToAnyPublisher(),
            addressChanged: addressChangedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            cancelTapped: cancelTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILAddTempleStateModel>) {
        guard case .success(let model) = state else { return }

        // Chỉ gán khi khác — gán `.text` luôn đẩy con trỏ về cuối chuỗi đang gõ.
        if nameField.text != model.name { nameField.text = model.name }
        if provinceField.text != model.province { provinceField.text = model.province }
        if addressField.text != model.address { addressField.text = model.address }

        nameField.fieldState = model.errorField == .name ? .error(nil) : .normal
        provinceField.fieldState = model.errorField == .province ? .error(nil) : .normal

        errorLabel.text = model.errorMessage
        errorLabel.isHidden = model.errorMessage == nil
    }

    // MARK: - Actions
    private func handleSubmitTapped() {
        view.endEditing(true)
        submitTappedSubject.send(())
    }
}
