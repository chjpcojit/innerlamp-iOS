//
//  ILSignUpViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILSignUpViewController: BaseViewController, TransitionProviding {

    var pushTransition: NavigationTransitionAnimating? {
        CrossFadeTransition()
    }

    // MARK: - Properties
    private let viewModel: ILSignUpViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let suggestDisplayNameTappedSubject = PassthroughSubject<Void, Never>()
    private let displayNameChangedSubject = PassthroughSubject<String, Never>()
    private let ordinationPlaceChangedSubject = PassthroughSubject<String, Never>()
    private let countryChangedSubject = PassthroughSubject<ILCountry, Never>()
    private let phoneNumberChangedSubject = PassthroughSubject<String, Never>()
    private let emailChangedSubject = PassthroughSubject<String, Never>()
    private let passwordChangedSubject = PassthroughSubject<String, Never>()
    private let togglePasswordVisibilityTappedSubject = PassthroughSubject<Void, Never>()
    private let toggleTermsTappedSubject = PassthroughSubject<Void, Never>()
    private let submitTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let loginPromptTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView: ILNavBar = {
        let view = ILNavBar(title: "signup.header.title".localized)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ILTypography.authTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        label.text = "signup.title".localized
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ILTypography.body
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.text = "signup.subtitle".localized
        return label
    }()

    private lazy var dharmaNameField = ILDharmaNameSuggestionField(
        label: "signup.field.displayName.label".localized,
        placeholder: "signup.field.displayName.placeholder".localized,
        suggestTitle: "signup.field.displayName.suggestButton".localized
    )

    private lazy var ordinationPlaceField = ILField(
        label: "signup.field.ordinationPlace.label".localized,
        placeholder: "signup.field.ordinationPlace.placeholder".localized,
        hint: "signup.field.ordinationPlace.hint".localized
    )

    private lazy var phoneField = ILPhoneField(
        label: "signup.field.phone.label".localized,
        placeholder: "signup.field.phone.placeholder".localized
    )

    private lazy var emailField = ILField(
        label: "signup.field.email.label".localized,
        placeholder: "signup.field.email.placeholder".localized,
        hint: "signup.field.email.hint".localized
    )

    private lazy var passwordField = ILField(
        label: "signup.field.password.label".localized,
        placeholder: "signup.field.password.placeholder".localized,
        trailingText: "signup.password.show".localized
    )

    private lazy var strengthMeter = ILStrengthMeterView(numberOfSegments: 3)

    private lazy var termsRow: ILCheckboxRow = {
        let row = ILCheckboxRow(text: "signup.terms.agree".localized)
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()

    private lazy var fieldsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dharmaNameField, ordinationPlaceField, phoneField, emailField, passwordField, strengthMeter])
        stack.axis = .vertical
        stack.spacing = ILMetrics.rowSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // Ghim đáy màn hình, cuộn riêng phần trên — khớp `flex:none;border-top` trong design handoff.
    private lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var footerDivider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.ink.withAlphaComponent(0.08)
        return view
    }()

    private lazy var submitButton: ILButton = {
        let button = ILButton(
            title: "signup.cta.sendCode".localized,
            variant: .primary,
            loadingTitle: "signup.cta.sendingCode".localized
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var loginPromptButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("signup.footer.loginPrompt".localized, for: .normal)
        button.titleLabel?.font = ILTypography.bodySmall
        button.setTitleColor(ILColors.inkMuted, for: .normal)
        return button
    }()

    // MARK: - Initializer
    init(viewModel: ILSignUpViewModel) {
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
        view.backgroundColor = ILColors.canvasWarm

        headerView.onBack = { [weak self] in
            self?.backTappedSubject.send(())
        }
        view.addSubview(headerView)

        scrollView.addSubview(contentView)
        view.addSubview(scrollView)

        dharmaNameField.onSuggestTapped = { [weak self] in
            self?.suggestDisplayNameTappedSubject.send(())
        }
        dharmaNameField.onTextChanged = { [weak self] text in
            self?.displayNameChangedSubject.send(text)
        }
        dharmaNameField.innerTextField.returnKeyType = .next
        dharmaNameField.onReturn = { [weak self] in
            self?.ordinationPlaceField.innerTextField.becomeFirstResponder()
        }

        ordinationPlaceField.innerTextField.returnKeyType = .next
        ordinationPlaceField.innerTextField.autocapitalizationType = .words
        ordinationPlaceField.onTextChanged = { [weak self] text in
            self?.ordinationPlaceChangedSubject.send(text)
        }
        ordinationPlaceField.onReturn = { [weak self] in
            self?.phoneField.innerTextField.becomeFirstResponder()
        }

        phoneField.innerTextField.returnKeyType = .next
        phoneField.onCountryTap = { [weak self] in
            self?.handleCountryTap()
        }
        phoneField.onTextChanged = { [weak self] text in
            self?.phoneNumberChangedSubject.send(text)
        }
        phoneField.onReturn = { [weak self] in
            self?.emailField.innerTextField.becomeFirstResponder()
        }

        emailField.innerTextField.returnKeyType = .next
        emailField.innerTextField.keyboardType = .emailAddress
        emailField.innerTextField.autocapitalizationType = .none
        emailField.innerTextField.autocorrectionType = .no
        emailField.onTextChanged = { [weak self] text in
            self?.emailChangedSubject.send(text)
        }
        emailField.onReturn = { [weak self] in
            self?.passwordField.innerTextField.becomeFirstResponder()
        }

        passwordField.innerTextField.isSecureTextEntry = true
        passwordField.innerTextField.returnKeyType = .done
        passwordField.onTextChanged = { [weak self] text in
            self?.passwordChangedSubject.send(text)
        }
        passwordField.onTrailingTap = { [weak self] in
            self?.handleTogglePasswordVisibilityTapped()
        }
        passwordField.onReturn = { [weak self] in
            self?.handleSubmitTapped()
        }

        termsRow.onToggle = { [weak self] in
            self?.toggleTermsTappedSubject.send(())
        }

        [titleLabel, subtitleLabel, fieldsStack, termsRow].forEach { contentView.addSubview($0) }

        footerContainer.addSubview(footerDivider)

        submitButton.onTap = { [weak self] in
            self?.handleSubmitTapped()
        }
        footerContainer.addSubview(submitButton)

        loginPromptButton.addTarget(self, action: #selector(handleLoginPromptTapped), for: .touchUpInside)
        footerContainer.addSubview(loginPromptButton)

        view.addSubview(footerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerContainer.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.spaceSmall),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ILMetrics.spaceSmall),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            fieldsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: ILMetrics.spaceLarge),
            fieldsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            fieldsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            termsRow.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: ILMetrics.groupSpacing),
            termsRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            termsRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            termsRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Ghim theo `keyboardLayoutGuide` — tự trồi lên theo bàn phím, không cần
            // NotificationCenter/contentInset thủ công.
            footerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            footerDivider.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            footerDivider.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            footerDivider.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            footerDivider.heightAnchor.constraint(equalToConstant: 1),

            submitButton.topAnchor.constraint(equalTo: footerDivider.bottomAnchor, constant: ILMetrics.spaceMedium),
            submitButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            submitButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),

            loginPromptButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: ILMetrics.spaceMedium),
            loginPromptButton.centerXAnchor.constraint(equalTo: footerContainer.centerXAnchor),
            loginPromptButton.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILSignUpViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            suggestDisplayNameTapped: suggestDisplayNameTappedSubject.eraseToAnyPublisher(),
            displayNameChanged: displayNameChangedSubject.eraseToAnyPublisher(),
            ordinationPlaceChanged: ordinationPlaceChangedSubject.eraseToAnyPublisher(),
            countryChanged: countryChangedSubject.eraseToAnyPublisher(),
            phoneNumberChanged: phoneNumberChangedSubject.eraseToAnyPublisher(),
            emailChanged: emailChangedSubject.eraseToAnyPublisher(),
            passwordChanged: passwordChangedSubject.eraseToAnyPublisher(),
            togglePasswordVisibilityTapped: togglePasswordVisibilityTappedSubject.eraseToAnyPublisher(),
            toggleTermsTapped: toggleTermsTappedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            loginPromptTapped: loginPromptTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Send after subscribing above, in the same synchronous call — PassthroughSubject
        // doesn't replay values sent before a subscriber attaches.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILSignUpStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILSignUpStateModel) {
        // So sánh trước khi gán — set `.text` luôn đẩy cursor về cuối chuỗi, nếu gán lại đúng giá
        // trị đang gõ thì người dùng không thể đặt cursor giữa chuỗi để sửa. Chỉ thực sự cần gán
        // khi giá trị đổi từ nơi khác (vd. bấm "Gợi ý").
        if dharmaNameField.value != model.displayName {
            dharmaNameField.value = model.displayName
        }

        if ordinationPlaceField.innerTextField.text != model.ordinationPlace {
            ordinationPlaceField.text = model.ordinationPlace
        }

        phoneField.country = model.selectedCountry
        phoneField.isValid = model.isPhoneValid
        phoneField.hint = model.phoneHint
        phoneField.fieldState = model.phoneNumberError.map { .error($0) } ?? .normal

        if emailField.innerTextField.text != model.email {
            emailField.text = model.email
        }
        if let emailError = model.emailError {
            emailField.fieldState = .error(emailError)
        } else if model.hasEmailValue {
            emailField.fieldState = model.isEmailFormatValid ? .success(nil) : .error("signup.error.emailInvalid".localized)
        } else {
            emailField.fieldState = .normal
        }

        passwordField.fieldState = model.passwordError.map { .error($0) } ?? .normal

        passwordField.innerTextField.isSecureTextEntry = !model.isPasswordVisible
        passwordField.trailingText = model.isPasswordVisible
            ? "signup.password.hide".localized
            : "signup.password.show".localized

        if let strength = model.passwordStrength {
            strengthMeter.isHidden = false
            strengthMeter.activeColor = color(for: strength)
            strengthMeter.filledSegments = strength.filledSegments
            strengthMeter.label = strength.label
        } else {
            strengthMeter.isHidden = true
        }

        termsRow.isChecked = model.didAcceptTerms

        submitButton.buttonState = model.isSubmitting ? .loading : (model.isSubmitEnabled ? .normal : .disabled)

        if let submitError = model.submitError {
            showError(submitError)
        }
    }

    private func color(for strength: ILPasswordStrength) -> UIColor {
        switch strength {
        case .weak: return ILColors.danger
        case .fair: return ILColors.gold
        case .strong: return ILColors.green
        }
    }

    // MARK: - Actions
    private func handleCountryTap() {
        view.endEditing(true)
        let picker = ILCountryPickerViewController(selectedCountry: viewModel.state.selectedCountry)
        picker.onSelect = { [weak self] country in
            self?.countryChangedSubject.send(country)
        }
        present(picker, animated: true)
    }

    private func handleTogglePasswordVisibilityTapped() {
        let wasFirstResponder = passwordField.innerTextField.isFirstResponder
        togglePasswordVisibilityTappedSubject.send(())
        if wasFirstResponder {
            passwordField.innerTextField.becomeFirstResponder()
        }
    }

    private func handleSubmitTapped() {
        view.endEditing(true)
        submitTappedSubject.send(())
    }

    @objc private func handleLoginPromptTapped() {
        loginPromptTappedSubject.send(())
    }
}
