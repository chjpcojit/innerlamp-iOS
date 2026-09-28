//
//  ILTalkMeditateCardView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Thẻ "Nghe xong, ngồi thiền 10 phút" cuối màn Pháp thoại — nền `--il-feat-bg` (đổi theo
/// light/dark), ngọn đèn vàng trong vòng tròn viền, tiêu đề + phụ đề + mũi tên. Cả thẻ là 1 vùng
/// chạm để mở màn Chuẩn bị thiền.
final class ILTalkMeditateCardView: UIControl {

    // MARK: - Properties
    var title: String = "" { didSet { titleLabel.text = title } }
    var subtitle: String = "" { didSet { subtitleLabel.text = subtitle } }

    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    private let flameRing = UIView()
    private let flame = ILFlameView(height: 14, topColor: ILColors.goldBright)

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.templeHeaderInk
        label.numberOfLines = 1
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.templeHeaderSub
        label.numberOfLines = 1
        return label
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.isUserInteractionEnabled = false
        return stack
    }()

    private lazy var chevronLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.chevron
        label.textColor = ILColors.templeHeaderSub
        label.text = "›"
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.featBorder.cgColor
        clipsToBounds = true

        // Nền `--il-feat-bg` (hai chặng gradient, đổi theo light/dark).
        gradientLayer.colors = [ILColors.featBackgroundStart.cgColor, ILColors.featBackgroundEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        // Vòng tròn viền vàng chứa ngọn đèn.
        flameRing.layer.cornerRadius = 19
        flameRing.layer.borderWidth = 1
        flameRing.layer.borderColor = ILColors.goldBright.withAlphaComponent(0.5).cgColor
        flameRing.translatesAutoresizingMaskIntoConstraints = false
        flame.translatesAutoresizingMaskIntoConstraints = false
        flameRing.addSubview(flame)
        NSLayoutConstraint.activate([
            flameRing.widthAnchor.constraint(equalToConstant: 38),
            flameRing.heightAnchor.constraint(equalToConstant: 38),
            flame.centerXAnchor.constraint(equalTo: flameRing.centerXAnchor),
            flame.centerYAnchor.constraint(equalTo: flameRing.centerYAnchor),
            flame.heightAnchor.constraint(equalToConstant: 14)
        ])

        [flameRing, textStack, chevronLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            flameRing.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            flameRing.centerYAnchor.constraint(equalTo: centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: flameRing.trailingAnchor, constant: ILMetrics.spaceMedium),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            chevronLabel.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 12),
            chevronLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            chevronLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTalkMeditateCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func applyColorAppearanceChange() {
        gradientLayer.colors = [
            ILColors.featBackgroundStart.resolvedColor(with: traitCollection).cgColor,
            ILColors.featBackgroundEnd.resolvedColor(with: traitCollection).cgColor
        ]
        layer.borderColor = ILColors.featBorder.resolvedColor(with: traitCollection).cgColor
    }

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
