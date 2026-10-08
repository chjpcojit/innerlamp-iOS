//
//  ILForgotPasswordViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILForgotPasswordViewController: BaseViewController, TransitionProviding {

    // Same slide as the default used for view controllers that don't conform to `TransitionProviding`.
    var pushTransition: NavigationTransitionAnimating? {
        SlideTransition(direction: .rightToLeft)
    }

    /// Blocks the edge swipe-back while the reset request is in flight.
    var isSwipeBackEnabled: Bool { !isSubmitting }

    private var isSubmitting = false

    // MARK: - Properties
    private let viewModel: ILForgotPasswordViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let phoneChangedSubject = PassthroughSubject<String, Never>()
    private let countryChangedSubject = PassthroughSubject<ILCountry, Never>()
    private let submitTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let backToLoginTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView = ILNavBar(title: "forgot.header.title".localized)

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private lazy var contentView = UIView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.authTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        label.text = "forgot.title".localized
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.body
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.text = "forgot.subtitle".localized
        return label
    }()

    /// Control gõ số điện thoại dùng chung — cùng `ILPhoneField` với Đăng nhập/Đăng ký (cờ + mã
    /// vùng + ô nhập thật), khớp field "Số điện thoại đã đăng ký" trong design handoff. Không dùng
    /// thẻ hiển thị tĩnh vì người dùng chưa đăng nhập nên app chưa biết sẵn số này — họ phải gõ vào.
    private lazy var phoneField: ILPhoneField = {
        let field = ILPhoneField(
            label: "forgot.summary.phone.label".localized,
            placeholder: "forgot.field.phone.placeholder".localized
        )
        field.innerTextField.returnKeyType = .done
        field.onCountryTap = { [weak self] in self?.handleCountryTap() }
        field.onTextChanged = { [weak self] text in self?.phoneChangedSubject.send(text) }
        field.onReturn = { [weak self] in self?.view.endEditing(true) }
        return field
    }()

    /// Hộp gợi ý "đổi số điện thoại" — khớp khối cảnh báo mềm trong prototype
    /// (nền vàng nhạt, chấm tròn + text), đặt inline vì chỉ dùng riêng màn này.
    private lazy var noticeView: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.Tone.gold.tintBackground
        container.layer.cornerRadius = ILMetrics.radiusCardSmall
        container.layer.borderWidth = 1
        container.layer.borderColor = ILColors.goldBorder.cgColor

        let dot = UIView()
        dot.backgroundColor = ILColors.gold
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.font = ILTypography.beVietnamPro(size: 11.5)
        label.textColor = ILColors.inkDim
        label.numberOfLines = 0
        label.text = "forgot.notice.changePhone".localized
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(dot)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            dot.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),

            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 15),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -15),
            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        return container
    }()

    private lazy var submitButton: ILButton = {
        let button = ILButton(
            title: "forgot.cta.sendInstructions".localized,
            variant: .primary,
            loadingTitle: "forgot.cta.sending".localized
        )
        button.onTap = { [weak self] in self?.submitTappedSubject.send(()) }
        return button
    }()

    private lazy var backToLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("forgot.backToLogin".localized, for: .normal)
        button.titleLabel?.font = ILTypography.bodySmall
        button.setTitleColor(ILColors.inkMuted, for: .normal)
        button.addTarget(self, action: #selector(handleBackToLoginTapped), for: .touchUpInside)
        return button
    }()

    /// CTA ghim đáy màn hình — khớp prototype (flex:1 đẩy button xuống bottom, không cuộn theo nội dung).
    private lazy var bottomStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [submitButton, backToLoginButton])
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILForgotPasswordViewModel) {
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

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        view.addSubview(headerView)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, subtitleLabel, phoneField, noticeView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomStack)
    }

    override func setupConstraints() {
        super.setupConstraints()

        headerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -ILMetrics.spaceMedium),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ILMetrics.spaceSmall),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            phoneField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: ILMetrics.spaceLarge),
            phoneField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            phoneField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            noticeView.topAnchor.constraint(equalTo: phoneField.bottomAnchor, constant: ILMetrics.spaceMedium),
            noticeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            noticeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            noticeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            submitButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),

            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            // Ghim theo `keyboardLayoutGuide` — tự trồi lên theo bàn phím, không cần
            // NotificationCenter/contentInset thủ công (cùng pattern Login/SignUp).
            bottomStack.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -ILMetrics.spaceLarge)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILForgotPasswordViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            methodChanged: Empty<ILForgotPasswordMethod, Never>().eraseToAnyPublisher(),
            phoneChanged: phoneChangedSubject.eraseToAnyPublisher(),
            countryChanged: countryChangedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            backToLoginTapped: backToLoginTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILForgotPasswordStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILForgotPasswordStateModel) {
        phoneField.country = model.selectedCountry
        phoneField.isValid = model.isPhoneValid

        submitButton.buttonState = model.isSubmitting ? .loading : (model.isSubmitEnabled ? .normal : .disabled)
        setInteractionLocked(model.isSubmitting)

        if let submitError = model.submitError {
            showError(submitError)
        }
    }

    /// Locks back, phone field and bottom actions while submitting, so the user cannot leave the
    /// screen or alter the request mid-flight.
    private func setInteractionLocked(_ locked: Bool) {
        isSubmitting = locked
        headerView.isUserInteractionEnabled = !locked
        scrollView.isUserInteractionEnabled = !locked
        bottomStack.isUserInteractionEnabled = !locked
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

    @objc private func handleBackToLoginTapped() {
        backToLoginTappedSubject.send(())
    }
}
