//
//  ILOtpViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILOtpViewController: BaseViewController, TransitionProviding {

    // Same slide as the default used for view controllers that don't conform to `TransitionProviding`.
    var pushTransition: NavigationTransitionAnimating? {
        SlideTransition(direction: .rightToLeft)
    }

    /// Blocks the edge swipe-back while the code is being verified.
    var isSwipeBackEnabled: Bool { !isVerifying }

    private var isVerifying = false

    // MARK: - Properties
    private let viewModel: ILOtpViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let codeChangedSubject = PassthroughSubject<String, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let changeNumberTappedSubject = PassthroughSubject<Void, Never>()
    private let resendTappedSubject = PassthroughSubject<Void, Never>()
    private let requestVoiceCallTappedSubject = PassthroughSubject<Void, Never>()
    private let verifyTappedSubject = PassthroughSubject<Void, Never>()

    /// Countdown tick lại render mỗi giây trong khi `codeError` vẫn còn set — nhớ lỗi đã
    /// hiện rồi để không present lại `showError` mỗi giây.
    private var lastShownCodeError: String?
    /// Tương tự cho lỗi gửi lại — `resendError` không đổi qua mỗi tick nhưng vẫn dedup cho chắc.
    private var lastShownResendError: String?

    // MARK: - UI Elements
    private lazy var headerView: ILNavBar = {
        let view = ILNavBar(title: "otp.header.title".localized)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onBack = { [weak self] in
            self?.backTappedSubject.send(())
        }
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
        label.text = "otp.title".localized
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.body
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var changeNumberButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("otp.changeNumber".localized, for: .normal)
        button.titleLabel?.font = ILTypography.body
        button.setTitleColor(ILColors.goldDeep, for: .normal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(handleChangeNumberTapped), for: .touchUpInside)
        return button
    }()

    private lazy var subtitleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [subtitleLabel, changeNumberButton])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .firstBaseline
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var codeInputView: ILCodeInputView = {
        let view = ILCodeInputView(numberOfDigits: ILOtpStateModel.codeLength)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onCodeChanged = { [weak self] code in
            self?.codeChangedSubject.send(code)
        }
        return view
    }()

    private lazy var resendRowView: ILOtpResendRowView = {
        let view = ILOtpResendRowView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onResendTapped = { [weak self] in
            self?.handleResendTapped()
        }
        return view
    }()

    private lazy var voiceCallBannerView: ILOtpVoiceCallBannerView = {
        let view = ILOtpVoiceCallBannerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onTap = { [weak self] in
            self?.requestVoiceCallTappedSubject.send(())
        }
        return view
    }()

    private lazy var verifyButton: ILButton = {
        let button = ILButton(
            title: "otp.cta.verify".localized,
            variant: .primary,
            loadingTitle: "otp.cta.verifying".localized
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.onTap = { [weak self] in
            self?.handleVerifyTapped()
        }
        return button
    }()

    private lazy var expiryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = ILTypography.caption
        label.textColor = ILColors.inkFaint
        label.textAlignment = .center
        // Nội dung thật được set trong `updateUI(with:)` từ `ILOtpStateModel.expiryText`
        // (thời gian hiệu lực do server trả về), không hardcode ở đây.
        return label
    }()

    // Ghim đáy màn hình, cuộn riêng phần trên — cùng pattern `footerContainer` với màn
    // Đăng nhập/Đăng ký (`view.keyboardLayoutGuide`, tự trồi lên theo bàn phím).
    private lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initializer
    init(viewModel: ILOtpViewModel) {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = codeInputView.becomeFirstResponder()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvasWarm

        view.addSubview(headerView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, subtitleStack, codeInputView, resendRowView, voiceCallBannerView].forEach {
            contentView.addSubview($0)
        }

        [verifyButton, expiryLabel].forEach {
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

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            subtitleStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ILMetrics.spaceSmall),
            subtitleStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),

            codeInputView.topAnchor.constraint(equalTo: subtitleStack.bottomAnchor, constant: ILMetrics.spaceLarge),
            codeInputView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            codeInputView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            resendRowView.topAnchor.constraint(equalTo: codeInputView.bottomAnchor, constant: ILMetrics.spaceMedium),
            resendRowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            resendRowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            voiceCallBannerView.topAnchor.constraint(equalTo: resendRowView.bottomAnchor, constant: ILMetrics.groupSpacing),
            voiceCallBannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            voiceCallBannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            voiceCallBannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Ghim theo `keyboardLayoutGuide` — tự trồi lên theo bàn phím, không cần
            // NotificationCenter/contentInset thủ công (giống `footerContainer` ở màn Đăng nhập/Đăng ký).
            footerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -ILMetrics.spaceMedium),
            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            verifyButton.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            verifyButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            verifyButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            verifyButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),

            expiryLabel.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: ILMetrics.spaceMedium),
            expiryLabel.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            expiryLabel.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            expiryLabel.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILOtpViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            codeChanged: codeChangedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            changeNumberTapped: changeNumberTappedSubject.eraseToAnyPublisher(),
            resendTapped: resendTappedSubject.eraseToAnyPublisher(),
            requestVoiceCallTapped: requestVoiceCallTappedSubject.eraseToAnyPublisher(),
            verifyTapped: verifyTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILOtpStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILOtpStateModel) {
        subtitleLabel.text = String(format: "otp.subtitle".localized, model.phoneNumber)

        codeInputView.code = model.code
        codeInputView.hasError = model.codeError != nil

        verifyButton.buttonState = model.isVerifying ? .loading : (model.isSubmitEnabled ? .normal : .disabled)
        setInteractionLocked(model.isVerifying)

        resendRowView.secondsRemaining = model.secondsRemaining
        resendRowView.canResend = model.canResend

        expiryLabel.text = model.expiryText

        if let codeError = model.codeError, codeError != lastShownCodeError {
            lastShownCodeError = codeError
            showError(codeError)
        } else if model.codeError == nil {
            lastShownCodeError = nil
        }

        if let resendError = model.resendError, resendError != lastShownResendError {
            lastShownResendError = resendError
            showError(resendError)
        } else if model.resendError == nil {
            lastShownResendError = nil
        }
    }

    /// Locks back, code input, resend, voice call and change-number while verifying, so the user
    /// cannot leave the screen or alter the request mid-flight.
    private func setInteractionLocked(_ locked: Bool) {
        isVerifying = locked
        headerView.isUserInteractionEnabled = !locked
        scrollView.isUserInteractionEnabled = !locked
    }

    // MARK: - Actions
    @objc private func handleChangeNumberTapped() {
        changeNumberTappedSubject.send(())
    }

    private func handleResendTapped() {
        resendTappedSubject.send(())
        _ = codeInputView.becomeFirstResponder()
    }

    private func handleVerifyTapped() {
        view.endEditing(true)
        verifyTappedSubject.send(())
    }
}
