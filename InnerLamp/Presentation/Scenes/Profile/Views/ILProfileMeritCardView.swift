//
//  ILProfileMeritCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Công đức đã hồi hướng": nền tối luôn tối ở cả light/dark (theo design handoff), vòng tròn
/// viền vàng chứa ngọn lửa, tiêu đề + tóm tắt số lần cúng dường / đèn Vu Lan, mũi tên. Cả thẻ là
/// 1 vùng chạm (mở Cúng dường). Nội dung riêng màn Tôi.
final class ILProfileMeritCardView: UIControl {

    // MARK: - Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 18
        static let ringSize: CGFloat = 40
        static let flameHeight: CGFloat = 16
    }

    // MARK: - Properties
    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    private lazy var ringView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.ringSize / 2
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.goldBorderOnDark.cgColor
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false

        let flame = ILFlameView(height: Layout.flameHeight, topColor: ILColors.goldLight)
        view.addSubview(flame)
        NSLayoutConstraint.activate([
            flame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            flame.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.headerTitle
        label.textColor = ILColors.inkOnDark
        return label
    }()

    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkOnDarkSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var chevronLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chevron
        label.textColor = ILColors.inkOnDarkTertiary
        label.text = "›"
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        clipsToBounds = true

        gradientLayer.colors = [ILColors.darkBackgroundTop.cgColor, ILColors.darkBackground.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let contentStack = UIStackView(arrangedSubviews: [ringView, textStack, chevronLabel])
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = ILMetrics.spaceMedium
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            ringView.widthAnchor.constraint(equalToConstant: Layout.ringSize),
            ringView.heightAnchor.constraint(equalToConstant: Layout.ringSize),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(summary: String) {
        summaryLabel.text = summary
    }

    // MARK: - Touch
    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
