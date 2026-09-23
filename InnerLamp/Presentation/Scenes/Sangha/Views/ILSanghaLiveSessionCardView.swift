//
//  ILSanghaLiveSessionCardView.swift
//  InnerLamp
//

import UIKit

/// Thẻ "Đang cùng ngồi thiền" của Đạo tràng: chấm sáng + tiêu đề, số người lớn, câu phụ, hàng
/// avatar chồng + nút "Ngồi cùng". Biết `ILSanghaLiveSessionModel` nên thuộc riêng màn Đạo tràng.
final class ILSanghaLiveSessionCardView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let padding: CGFloat = 20
        static let dotSize: CGFloat = 10
        static let avatarSize: CGFloat = 28
        static let avatarOverlap: CGFloat = 9
        static let avatarBorderWidth: CGFloat = 1.5
    }

    // MARK: - Properties
    var onSitTogetherTapped: (() -> Void)?

    // MARK: - UI Elements
    private lazy var dotView: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.goldBright
        view.layer.cornerRadius = Layout.dotSize / 2
        view.layer.shadowColor = ILColors.goldBright.cgColor
        view.layer.shadowOpacity = 0.9
        view.layer.shadowRadius = 6
        view.layer.shadowOffset = .zero
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.headerTitle
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.statNumber
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var avatarStack: UIView = {
        let container = UIView()
        let tints = [ILColors.tint, ILColors.tint2, ILColors.tint3]
        for (index, tint) in tints.enumerated() {
            let avatar = UIView()
            avatar.backgroundColor = tint
            avatar.layer.cornerRadius = Layout.avatarSize / 2
            avatar.layer.borderWidth = Layout.avatarBorderWidth
            avatar.layer.borderColor = ILColors.surface.cgColor
            avatar.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(avatar)
            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
                avatar.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
                avatar.topAnchor.constraint(equalTo: container.topAnchor),
                avatar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                avatar.leadingAnchor.constraint(
                    equalTo: container.leadingAnchor,
                    constant: CGFloat(index) * (Layout.avatarSize - Layout.avatarOverlap)
                )
            ])
        }
        let totalWidth = Layout.avatarSize + 2 * (Layout.avatarSize - Layout.avatarOverlap)
        container.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true
        container.setContentHuggingPriority(.required, for: .horizontal)
        return container
    }()

    private lazy var ctaButton: ILButton = {
        let button = ILButton(title: "", variant: .primary)
        button.onTap = { [weak self] in self?.onSitTogetherTapped?() }
        return button
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
        registerForAppearanceChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardLarge - 2
        layer.borderWidth = 1
        layer.borderColor = ILColors.goldCardBorder.cgColor

        let headerRow = UIStackView(arrangedSubviews: [dotView, titleLabel])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = ILMetrics.spaceMedium - 2
        dotView.widthAnchor.constraint(equalToConstant: Layout.dotSize).isActive = true
        dotView.heightAnchor.constraint(equalToConstant: Layout.dotSize).isActive = true

        let bottomRow = UIStackView(arrangedSubviews: [avatarStack, ctaButton])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.spacing = ILMetrics.rowSpacing

        let contentStack = UIStackView(arrangedSubviews: [headerRow, countLabel, captionLabel, bottomRow])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 2, after: headerRow)
        contentStack.setCustomSpacing(6, after: countLabel)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium + 2, after: captionLabel)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.padding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.padding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILSanghaLiveSessionModel) {
        titleLabel.text = model.title
        countLabel.text = model.countText
        captionLabel.text = model.captionText
        ctaButton.title = model.ctaTitle
    }

    // `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi đổi
    // light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.layer.borderColor = ILColors.goldCardBorder.cgColor
            self.avatarStack.subviews.forEach { $0.layer.borderColor = ILColors.surface.cgColor }
        }
    }
}
