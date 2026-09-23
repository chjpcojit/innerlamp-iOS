//
//  ILLoginViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLoginViewController: BaseViewController, TransitionProviding {
    
    var pushTransition: NavigationTransitionAnimating? {
        CrossFadeTransition()
    }

    // MARK: - Properties
    private let viewModel: ILLoginViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let phoneChangedSubject = PassthroughSubject<String, Never>()
    private let countryChangedSubject = PassthroughSubject<ILCountry, Never>()
    private let passwordChangedSubject = PassthroughSubject<String, Never>()
    private let submitTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let signupTappedSubject = PassthroughSubject<Void, Never>()
    private let forgotPasswordTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private let backgroundGradientLayer = CAGradientLayer()

    // Header dùng chung — khớp `IL-NavBar` (`title="Đăng nhập", on-back`) trong design handoff
    // (`isLogin`), cùng pattern với Đăng ký/Quên mật khẩu/OTP.
    private lazy var headerView: ILHeaderView = {
        let view = ILHeaderView(title: "login.header.title".localized)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Nền sáng — khai báo tường minh để không rơi vào bảng màu `.onDark` mặc định của Splash.
    private let lampIcon = ILLampGlowView(diameter: 56, style: .onLight)

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let phoneField = ILPhoneField(
        label: "login.field.phone.label".localized,
        placeholder: "login.field.phone.placeholder".localized
    )
    private let passwordField = ILField(
        placeholder: "login.field.password.placeholder".localized,
        trailingText: "login.forgot".localized
    )
    private let fieldsStack: UIStackView

    private let loginButton = ILButton(
        title: "login.cta.login".localized,
        variant: .primary,
        loadingTitle: "login.cta.loggingIn".localized
    )
    private let smsCodeButton = ILButton(title: "login.cta.smsCode".localized, variant: .ghost)

    // Ghim đáy màn hình, cuộn riêng phần trên — khớp `flex:1` (đẩy khối này xuống đáy) trong
    // design handoff (`isLogin`), cùng pattern `footerContainer` với màn Đăng ký.
    private let footerContainer = UIView()
    private let dividerRow = ILDividerRow(text: "login.divider.or".localized)
    private let createAccountButton = ILButton(title: "login.cta.createAccount".localized, variant: .goldOutline)
    private let guestPreviewButton = UIButton(type: .system)

    // MARK: - Initializer
    init(viewModel: ILLoginViewModel) {
        self.viewModel = viewModel
        self.fieldsStack = UIStackView(arrangedSubviews: [phoneField, passwordField])
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
        backgroundGradientLayer.frame = view.bounds
    }

    // `layer.colors` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi hệ
    // thống đổi light/dark (giống Onboarding/Splash).
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        backgroundGradientLayer.colors = [
            ILColors.canvasWarm.cgColor,
            ILColors.canvasWarmEnd1.cgColor
        ]
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()

        // Nền gradient dọc `card2 → sunk` khớp design handoff (`isLogin`), cùng cặp token với
        // Onboarding/Splash (canvasWarm/canvasWarmEnd1) — chỉ khác điểm kết thúc gradient.
        backgroundGradientLayer.colors = [
            ILColors.canvasWarm.cgColor,
            ILColors.canvasWarmEnd1.cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)

        headerView.onBack = { [weak self] in
            self?.backTappedSubject.send(())
        }
        view.addSubview(headerView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        titleLabel.font = ILTypography.authTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0
        titleLabel.text = "login.title".localized

        subtitleLabel.font = ILTypography.body
        subtitleLabel.textColor = ILColors.inkTertiary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "login.subtitle".localized

        phoneField.innerTextField.returnKeyType = .next
        phoneField.onCountryTap = { [weak self] in
            self?.handleCountryTap()
        }
        phoneField.onTextChanged = { [weak self] text in
            self?.phoneChangedSubject.send(text)
        }
        phoneField.onReturn = { [weak self] in
            self?.passwordField.innerTextField.becomeFirstResponder()
        }

        passwordField.innerTextField.isSecureTextEntry = true
        passwordField.innerTextField.returnKeyType = .done
        passwordField.onTextChanged = { [weak self] text in
            self?.passwordChangedSubject.send(text)
        }
        passwordField.onTrailingTap = { [weak self] in
            self?.forgotPasswordTappedSubject.send(())
        }
        passwordField.onReturn = { [weak self] in
            self?.handleSubmitTapped()
        }

        fieldsStack.axis = .vertical
        fieldsStack.spacing = ILMetrics.rowSpacing
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false

        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.onTap = { [weak self] in
            self?.handleSubmitTapped()
        }

        smsCodeButton.translatesAutoresizingMaskIntoConstraints = false
        smsCodeButton.onTap = { [weak self] in
            self?.handleSmsCodeTapped()
        }

        [lampIcon, titleLabel, subtitleLabel, fieldsStack, loginButton, smsCodeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        footerContainer.translatesAutoresizingMaskIntoConstraints = false

        dividerRow.translatesAutoresizingMaskIntoConstraints = false

        createAccountButton.translatesAutoresizingMaskIntoConstraints = false
        createAccountButton.onTap = { [weak self] in
            self?.signupTappedSubject.send(())
        }

        guestPreviewButton.translatesAutoresizingMaskIntoConstraints = false
        guestPreviewButton.setTitle("login.guestPreview".localized, for: .normal)
        guestPreviewButton.titleLabel?.font = ILTypography.bodySmall
        guestPreviewButton.setTitleColor(ILColors.inkSubtle, for: .normal)
        guestPreviewButton.addTarget(self, action: #selector(handleGuestPreviewTapped), for: .touchUpInside)

        [dividerRow, createAccountButton, guestPreviewButton].forEach {
            footerContainer.addSubview($0)
        }
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
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.spaceLarge),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2),

            lampIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceLarge),
            lampIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            titleLabel.topAnchor.constraint(equalTo: lampIcon.bottomAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ILMetrics.spaceSmall),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            fieldsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: ILMetrics.spaceLarge),
            fieldsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            fieldsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            loginButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: ILMetrics.spaceLarge),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            smsCodeButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: ILMetrics.rowSpacing),
            smsCodeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            smsCodeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            smsCodeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Ghim theo `keyboardLayoutGuide` — tự trồi lên theo bàn phím, không cần
            // NotificationCenter/contentInset thủ công (giống `footerContainer` ở màn Đăng ký).
            footerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -ILMetrics.spaceMedium),
            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            dividerRow.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            dividerRow.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            dividerRow.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),

            createAccountButton.topAnchor.constraint(equalTo: dividerRow.bottomAnchor, constant: ILMetrics.spaceMedium),
            createAccountButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            createAccountButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),

            guestPreviewButton.topAnchor.constraint(equalTo: createAccountButton.bottomAnchor, constant: ILMetrics.spaceMedium),
            guestPreviewButton.centerXAnchor.constraint(equalTo: footerContainer.centerXAnchor),
            guestPreviewButton.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLoginViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            phoneChanged: phoneChangedSubject.eraseToAnyPublisher(),
            countryChanged: countryChangedSubject.eraseToAnyPublisher(),
            passwordChanged: passwordChangedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            signupTapped: signupTappedSubject.eraseToAnyPublisher(),
            forgotPasswordTapped: forgotPasswordTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Gửi sau khi đã subscribe ở trên, cùng lệnh gọi đồng bộ — `PassthroughSubject` không
        // phát lại giá trị gửi trước khi có subscriber.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILLoginStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILLoginStateModel) {
        phoneField.country = model.selectedCountry
        phoneField.isValid = model.isPhoneValid
        phoneField.fieldState = model.phoneError.map { .error($0) } ?? .normal

        passwordField.fieldState = model.passwordError.map { .error($0) } ?? .normal

        loginButton.buttonState = model.isSubmitting ? .loading : (model.isSubmitEnabled ? .normal : .disabled)

        if let submitError = model.submitError {
            showError(submitError)
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

    private func handleSubmitTapped() {
        view.endEditing(true)
        submitTappedSubject.send(())
    }

    /// Đăng nhập qua OTP SMS chưa có màn riêng trong scope hiện tại (`otp` trong design handoff).
    private func handleSmsCodeTapped() {
        // TODO: điều hướng sang màn Xác thực OTP khi có ILOtpCoordinator.
    }

    @objc private func handleGuestPreviewTapped() {
        // TODO: vào xem trước không đăng nhập khi có luồng Home.
    }
}
