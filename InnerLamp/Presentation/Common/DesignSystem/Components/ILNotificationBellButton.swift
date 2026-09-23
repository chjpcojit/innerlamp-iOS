//
//  ILNotificationBellButton.swift
//  InnerLamp
//

import UIKit

/// Nút chuông tròn dùng ở header các màn chính, có thể bật/tắt chấm báo chưa đọc.
public final class ILNotificationBellButton: UIControl {

    // MARK: - Properties
    public var hasUnread: Bool = false {
        didSet { badgeView.isHidden = !hasUnread }
    }

    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let bellShape = UIView()
    private let badgeView = UIView()

    // MARK: - Initializer
    public init(hasUnread: Bool = false) {
        self.hasUnread = hasUnread
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = 19
        backgroundColor = ILColors.surface
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        bellShape.translatesAutoresizingMaskIntoConstraints = false
        bellShape.isUserInteractionEnabled = false
        bellShape.layer.cornerRadius = 6
        bellShape.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bellShape.layer.borderWidth = 1.5
        bellShape.layer.borderColor = ILColors.ink.withAlphaComponent(0.55).cgColor

        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isUserInteractionEnabled = false
        badgeView.layer.cornerRadius = 3.5
        badgeView.backgroundColor = ILColors.gold
        badgeView.layer.borderWidth = 1.5
        badgeView.layer.borderColor = ILColors.surface.cgColor
        badgeView.isHidden = !hasUnread

        addSubview(bellShape)
        addSubview(badgeView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 38),
            heightAnchor.constraint(equalToConstant: 38),

            bellShape.widthAnchor.constraint(equalToConstant: 13),
            bellShape.heightAnchor.constraint(equalToConstant: 15),
            bellShape.centerXAnchor.constraint(equalTo: centerXAnchor),
            bellShape.centerYAnchor.constraint(equalTo: centerYAnchor),

            badgeView.widthAnchor.constraint(equalToConstant: 7),
            badgeView.heightAnchor.constraint(equalToConstant: 7),
            badgeView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        layer.borderColor = ILColors.border.cgColor
        bellShape.layer.borderColor = ILColors.ink.withAlphaComponent(0.55).cgColor
        badgeView.layer.borderColor = ILColors.surface.cgColor
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
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
