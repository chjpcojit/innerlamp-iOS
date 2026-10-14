//
//  ILPhotoViewerInfoPanelView.swift
//  InnerLamp
//

import UIKit

/// Khối thông tin dưới ảnh: eyebrow danh mục, tiêu đề, địa điểm, 3 nút hành động và dòng toast.
final class ILPhotoViewerInfoPanelView: UIView {

    // MARK: - Layout constants
    private static let actionHeight: CGFloat = 48
    private static let toastHeight: CGFloat = 18

    // MARK: - Properties
    var onAction: ((ILPhotoViewerAction) -> Void)?

    // MARK: - UI Elements
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.eyebrow
        label.textColor = ILColors.goldOnDark
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureTitle
        label.textColor = ILColors.inkOnDark
        label.numberOfLines = 0
        return label
    }()

    private lazy var placeLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkOnDarkSecondary
        return label
    }()

    private lazy var toastLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.goldOnDark
        label.textAlignment = .center
        return label
    }()

    private lazy var actionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.spaceSmall
        return stack
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(item: ILPhotoViewerItemModel, toast: String) {
        categoryLabel.text = item.categoryLabel.uppercased()
        titleLabel.text = item.title
        placeLabel.text = item.place
        toastLabel.text = toast
    }

    // MARK: - Setup
    private func setupViews() {
        for action in ILPhotoViewerAction.allCases {
            actionsStack.addArrangedSubview(makeActionButton(for: action))
        }

        let stack = UIStackView(arrangedSubviews: [categoryLabel, titleLabel, placeLabel, actionsStack, toastLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.setCustomSpacing(6, after: categoryLabel)
        stack.setCustomSpacing(4, after: titleLabel)
        stack.setCustomSpacing(ILMetrics.groupSpacing, after: placeLabel)
        stack.setCustomSpacing(ILMetrics.rowSpacing, after: actionsStack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            actionsStack.heightAnchor.constraint(equalToConstant: Self.actionHeight),
            toastLabel.heightAnchor.constraint(equalToConstant: Self.toastHeight),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeActionButton(for action: ILPhotoViewerAction) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = Self.title(for: action)
        config.baseForegroundColor = ILColors.inkOnDark
        config.background.backgroundColor = ILColors.inkOnDark.withAlphaComponent(0.08)
        config.background.strokeColor = ILColors.inkOnDark.withAlphaComponent(0.14)
        config.background.strokeWidth = 1
        config.background.cornerRadius = ILMetrics.radiusInput
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = ILTypography.chip
            return attributes
        }
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in self?.onAction?(action) }, for: .touchUpInside)
        return button
    }

    private static func title(for action: ILPhotoViewerAction) -> String {
        switch action {
        case .save: return "photoViewer.action.save".localized
        case .setWallpaper: return "photoViewer.action.setWallpaper".localized
        case .share: return "photoViewer.action.share".localized
        }
    }
}
