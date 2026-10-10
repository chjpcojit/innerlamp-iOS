//
//  ILProfileCompactBarView.swift
//  InnerLamp
//

import UIKit

/// Thanh tên gọn ghim đỉnh màn Tôi (khớp `pfBarOp` trong design handoff): nền canvas, tên Cormorant
/// ở giữa, đường kẻ chân; không nhận chạm. Màn chủ điều khiển độ mờ theo `contentOffset.y` qua
/// `update(contentOffsetY:)` — ẩn hẳn khi ảnh bìa còn trên màn hình.
final class ILProfileCompactBarView: UIView {

    // MARK: - Constants
    private enum Layout {
        /// Offset at which the bar starts to appear / is fully visible (prototype: `(sc - 150) / 50`).
        static let fadeStart: CGFloat = 150
        static let fadeDistance: CGFloat = 50
        static let bottomInset: CGFloat = 10
    }

    // MARK: - UI Elements
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureTitle
        label.textColor = ILColors.ink
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let dividerView = UIView()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        backgroundColor = ILColors.canvas
        dividerView.backgroundColor = ILColors.border
        isUserInteractionEnabled = false
        alpha = 0
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        [nameLabel, dividerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomInset),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.screenHorizontal),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ILMetrics.screenHorizontal),

            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // MARK: - Configure
    func configure(name: String) {
        nameLabel.text = name
    }

    /// `alpha = clamp((offset − 150) / 50, 0, 1)`.
    func update(contentOffsetY offsetY: CGFloat) {
        alpha = min(max((offsetY - Layout.fadeStart) / Layout.fadeDistance, 0), 1)
    }
}
