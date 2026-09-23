//
//  ILProfileBadgesRowView.swift
//  InnerLamp
//

import UIKit

/// Hàng dấu ấn gần đây (các thẻ chia đều chiều ngang). Cả hàng là 1 vùng chạm (mở Dấu ấn tu
/// tập). Biết `ILProfileBadgeModel` nên thuộc riêng màn Tôi.
final class ILProfileBadgesRowView: UIControl {

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var rowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.rowSpacing
        stack.isUserInteractionEnabled = false
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

    // MARK: - Setup
    private func setupViews() {
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    // MARK: - Configure
    func configure(badges: [ILProfileBadgeModel]) {
        rowStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for badge in badges {
            let card = ILProfileBadgeCardView()
            card.configure(with: badge)
            rowStack.addArrangedSubview(card)
        }
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
