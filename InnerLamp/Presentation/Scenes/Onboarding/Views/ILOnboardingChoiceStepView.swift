//
//  ILOnboardingChoiceStepView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Hình dạng step "tiêu đề + phụ đề + chọn nhiều từ danh sách chip" — tái dùng cho MỌI step
/// onboarding kiểu này (không riêng cho 1 step cố định). Thêm 1 step chọn-chip mới chỉ cần thêm
/// data (`ILOnboardingStepContent.chipChoice`), không cần file mới.
final class ILOnboardingChoiceStepView: UIView {

    // MARK: - Properties
    /// Index của item được bấm trong danh sách items đã `configure`.
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

    private lazy var chipsFlowView: ILChipFlowView = {
        let view = ILChipFlowView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        let stack = UIStackView(arrangedSubviews: [headerStack, chipsFlowView])
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
    func configure(title: String, subtitle: String, items: [(label: String, isSelected: Bool)]) {
        titleLabel.attributedText = ILTypography.makeAttributedString(
            text: title,
            font: ILTypography.stepTitle,
            color: ILColors.ink,
            lineHeightMultiple: 1.2
        )
        subtitleLabel.text = subtitle

        let chips: [ILChip] = items.enumerated().map { index, item in
            let chip = ILChip(label: item.label, state: item.isSelected ? .selected : .normal)
            chip.onTap = { [weak self] in
                self?.onToggleItem?(index)
            }
            return chip
        }
        chipsFlowView.setItems(chips)
    }
}
