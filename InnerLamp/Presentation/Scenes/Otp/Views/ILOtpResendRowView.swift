//
//  ILOtpResendRowView.swift
//  InnerLamp
//

import UIKit

/// Hàng "Gửi lại mã sau 00:47" / nút "Gửi lại" trên màn OTP — gắn chặt với format countdown
/// và copy riêng của luồng xác thực OTP nên đặt ở `Scenes/Otp/Views/`, không phải Design
/// System dùng chung.
final class ILOtpResendRowView: UIView {

    // MARK: - Properties
    /// Gọi khi người dùng bấm "Gửi lại" (chỉ nhận tap khi `canResend == true`, nút đã
    /// `isEnabled = canResend`).
    var onResendTapped: (() -> Void)?

    /// Số giây còn lại trước khi được bấm "Gửi lại". `0` ẩn label countdown.
    var secondsRemaining: Int = 0 {
        didSet {
            guard oldValue != secondsRemaining else { return }
            updateCountdownLabel()
        }
    }

    /// `true` khi hết cooldown và không có request gửi-lại nào đang chạy — bật nút "Gửi lại".
    var canResend: Bool = false {
        didSet {
            guard oldValue != canResend else { return }
            updateResendButton()
        }
    }

    // MARK: - UI Elements
    private lazy var countdownLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = ILColors.inkFaint
        return label
    }()

    private lazy var resendButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.bodySmallMedium
        button.setTitle("otp.resend.action".localized, for: .normal)
        button.addTarget(self, action: #selector(handleResendTapped), for: .touchUpInside)
        return button
    }()

    private lazy var rowStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [countdownLabel, resendButton])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        updateCountdownLabel()
        updateResendButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowStack.topAnchor.constraint(equalTo: topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateCountdownLabel() {
        guard secondsRemaining > 0 else {
            countdownLabel.isHidden = true
            return
        }
        countdownLabel.isHidden = false
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        let mmss = String(format: "%02d:%02d", minutes, seconds)
        countdownLabel.text = String(format: "otp.resend.countdown".localized, mmss)
    }

    private func updateResendButton() {
        resendButton.isEnabled = canResend
        resendButton.setTitleColor(canResend ? ILColors.goldDeep : ILColors.inkFaint, for: .normal)
    }

    // MARK: - Actions
    @objc private func handleResendTapped() {
        onResendTapped?()
    }
}
