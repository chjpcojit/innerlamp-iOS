//
//  ILPostComposerBarView.swift
//  InnerLamp
//

import UIKit

/// Thanh soạn bình luận ghim đáy màn Bài đăng đạo tràng: pill "Viết lời chia sẻ…" + nút gửi tròn
/// (khớp sticky composer của prototype). Hiện chỉ là UI — việc gửi bình luận cần API/repository,
/// chưa build (xem TODO ở `ILPostUseCaseImpl`).
final class ILPostComposerBarView: UIView {

    private enum Layout {
        static let sendButtonSize: CGFloat = 46
        /// Tam giác "gửi" 11×14 trỏ phải (khớp `border-left:11px / border-top+bottom:7px`).
        static let triangleSize = CGSize(width: 11, height: 14)
    }

    // MARK: - UI Elements
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodyCompact
        label.textColor = ILColors.inkMuted
        label.text = "post.composer.placeholder".localized
        return label
    }()

    private lazy var inputPill: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.surface
        view.layer.cornerRadius = ILMetrics.radiusPill
        view.layer.borderWidth = 1
        view.layer.borderColor = ILColors.borderStrong.cgColor

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -18),
            placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }()

    private lazy var sendButton: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.ink
        view.layer.cornerRadius = Layout.sendButtonSize / 2

        // Mũi tên tam giác trỏ phải, căn giữa nút gửi (lệch nhẹ sang phải như prototype).
        let triangle = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: Layout.triangleSize.height))
        path.addLine(to: CGPoint(x: Layout.triangleSize.width, y: Layout.triangleSize.height / 2))
        path.close()
        triangle.path = path.cgPath
        triangle.fillColor = ILColors.canvas.cgColor
        triangle.frame = CGRect(
            x: (Layout.sendButtonSize - Layout.triangleSize.width) / 2 + 3,
            y: (Layout.sendButtonSize - Layout.triangleSize.height) / 2,
            width: Layout.triangleSize.width,
            height: Layout.triangleSize.height
        )
        view.layer.addSublayer(triangle)
        return view
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
        backgroundColor = ILColors.canvas

        inputPill.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(inputPill)
        addSubview(sendButton)

        NSLayoutConstraint.activate([
            inputPill.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputPill.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            inputPill.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -ILMetrics.rowSpacing),
            inputPill.heightAnchor.constraint(equalToConstant: 46),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            sendButton.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.rowSpacing + 2),
            sendButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceSmall),
            sendButton.widthAnchor.constraint(equalToConstant: Layout.sendButtonSize),
            sendButton.heightAnchor.constraint(equalToConstant: Layout.sendButtonSize)
        ])
    }

    // `layer.borderColor`/`CAShapeLayer.fillColor` là CGColor tĩnh — refresh khi đổi light/dark.
    private func registerForAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.inputPill.layer.borderColor = ILColors.borderStrong.cgColor
            (self.sendButton.layer.sublayers?.first as? CAShapeLayer)?.fillColor = ILColors.canvas.cgColor
        }
    }
}
