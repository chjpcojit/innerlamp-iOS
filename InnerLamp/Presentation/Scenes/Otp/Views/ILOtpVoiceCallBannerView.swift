//
//  ILOtpVoiceCallBannerView.swift
//  InnerLamp
//

import UIKit

/// Banner "nhận mã qua cuộc gọi thoại" trên màn OTP — nội dung/copy gắn chặt với luồng xác
/// thực OTP (cụm chữ tô màu là hành động gọi lại API OTP qua kênh thoại) nên đặt ở
/// `Scenes/Otp/Views/`, không phải Design System dùng chung.
final class ILOtpVoiceCallBannerView: UIView {

    // MARK: - Properties
    /// Gọi khi người dùng chạm vào banner để yêu cầu gửi mã qua cuộc gọi thoại.
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var dotView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ILColors.gold
        view.layer.cornerRadius = 4
        return view
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.attributedText = Self.makeBannerAttributedText()
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ILMetrics.radiusCardSmall
        backgroundColor = ILColors.gold.withAlphaComponent(0.10)
        layer.borderWidth = 1
        layer.borderColor = ILColors.gold.withAlphaComponent(0.30).cgColor
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        addSubview(dotView)
        addSubview(bodyLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dotView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            dotView.widthAnchor.constraint(equalToConstant: 8),
            dotView.heightAnchor.constraint(equalToConstant: 8),

            bodyLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bodyLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            bodyLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15)
        ])
    }

    /// Tô riêng cụm "nhận mã qua cuộc gọi thoại" bằng `goldDeep` để gợi ý phần này bấm được —
    /// toàn bộ banner nhận tap, không chỉ đúng cụm chữ đó (đơn giản hơn dò vị trí tap trong
    /// `NSAttributedString`, không có link-tap system nào khác trong codebase).
    private static func makeBannerAttributedText() -> NSAttributedString {
        let linkPhrase = "otp.banner.linkPhrase".localized
        let fullText = String(format: "otp.banner.body".localized, linkPhrase)

        let attributed = NSMutableAttributedString(
            attributedString: ILTypography.makeAttributedString(
                text: fullText,
                font: ILTypography.subhead,
                color: ILColors.inkDim,
                lineSpacing: 3
            )
        )

        if let range = fullText.range(of: linkPhrase) {
            attributed.addAttribute(.foregroundColor, value: ILColors.goldDeep, range: NSRange(range, in: fullText))
        }

        return attributed
    }

    // MARK: - Actions
    @objc private func handleTap() {
        onTap?()
    }
}
