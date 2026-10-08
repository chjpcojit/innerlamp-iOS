//
//  ILFamilyTreeCreateHeaderCardView.swift
//  InnerLamp
//

import UIKit

/// Card at the top of the "Tạo gia phả" form: a small gold hexagon seal, the clan name ("Họ …")
/// and a "quê gốc · thủy tổ" line that both follow what the user types.
final class ILFamilyTreeCreateHeaderCardView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let sealSize = CGSize(width: 18, height: 20)
        static let verticalPadding: CGFloat = 22
        static let horizontalPadding: CGFloat = 16
        static let sealTitleGap: CGFloat = 4
    }

    // MARK: - UI Elements
    private let sealLayer = CAShapeLayer()
    private let sealView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = Tree.cream
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = Tree.borderSoft.cgColor

        sealLayer.path = ILFamilyTreeMedallionView.hexagon(in: CGRect(origin: .zero, size: Layout.sealSize)).cgPath
        sealLayer.fillColor = Tree.gold.cgColor
        sealView.layer.addSublayer(sealLayer)

        titleLabel.font = ILTypography.treeCreateTitle
        titleLabel.textColor = Tree.heading
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = Tree.inkTertiary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [sealView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 6
        stack.setCustomSpacing(Layout.sealTitleGap, after: sealView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        // The seal is centred in its own row; the stack stretches the row to full width.
        sealView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sealView.heightAnchor.constraint(equalToConstant: Layout.sealSize.height),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeCreateHeaderCardView, _) in
            view.layer.borderColor = Tree.borderSoft.cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Centre the fixed-size seal inside its full-width row.
        sealLayer.frame = CGRect(
            x: (sealView.bounds.width - Layout.sealSize.width) / 2,
            y: 0,
            width: Layout.sealSize.width,
            height: Layout.sealSize.height
        )
    }
}
