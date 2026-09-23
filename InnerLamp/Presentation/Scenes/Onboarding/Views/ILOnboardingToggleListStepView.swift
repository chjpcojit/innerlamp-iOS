//
//  ILOnboardingToggleListStepView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Hình dạng step "tiêu đề + phụ đề + danh sách bật/tắt" — tái dùng cho MỌI step onboarding
/// kiểu này. Thêm 1 step bật/tắt mới chỉ cần thêm data (`ILOnboardingStepContent.toggleList`),
/// không cần file mới.
final class ILOnboardingToggleListStepView: UIView {

    // MARK: - Properties
    /// Index của item được toggle trong danh sách items đã `configure`.
    var onToggleItem: ((Int) -> Void)?

    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.inkTertiary
        return label
    }()

    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerStack, rowsStack])
        stack.axis = .vertical
        stack.spacing = 26
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Configure
    func configure(title: String, subtitle: String, items: [(title: String, sub: String, isOn: Bool)]) {
        titleLabel.attributedText = ILTypography.makeAttributedString(
            text: title,
            font: ILTypography.stepTitle,
            color: ILColors.ink,
            lineHeightMultiple: 1.2
        )
        subtitleLabel.text = subtitle

        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        items.enumerated().forEach { index, item in
            let row = ILToggleCardRow(title: item.title, subtitle: item.sub, isOn: item.isOn)
            row.onToggle = { [weak self] _ in
                self?.onToggleItem?(index)
            }
            rowsStack.addArrangedSubview(row)
        }
    }
}
