//
//  ILFestivalDetailKindRowView.swift
//  InnerLamp
//

import UIKit

/// EN: Festival kind row — event icon followed by the uppercase kind/group eyebrow.
/// VI: Hàng loại ngày lễ — icon sự kiện kèm nhãn eyebrow viết hoa của nhóm/loại lễ.
final class ILFestivalDetailKindRowView: UIStackView {

    // MARK: - UI Elements
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = ILIcons.homeEvent
        view.tintColor = ILColors.link
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var kindLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(kindText: String) {
        kindLabel.attributedText = ILTypography.makeEyebrow(text: kindText, color: ILColors.link)
    }

    // MARK: - Setup
    private func setupViews() {
        axis = .horizontal
        alignment = .center
        spacing = ILMetrics.spaceSmall
        [iconView, kindLabel].forEach { addArrangedSubview($0) }
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: ILMetrics.sectionIconSize),
            iconView.heightAnchor.constraint(equalToConstant: ILMetrics.sectionIconSize)
        ])
    }
}
