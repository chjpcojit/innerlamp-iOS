//
//  ILHomeGreetingHeaderView.swift
//  InnerLamp
//

import UIKit

/// Header đầu Trang chủ: lời chào + ngày âm lịch bên trái, chuông thông báo + avatar bên phải.
/// Bố cục này riêng cho Trang chủ (không màn nào khác cần đúng tổ hợp này) nên ở `Scenes/Home`,
/// còn các phần tử con (`ILNotificationBellButton`, `ILAvatarView`) là component dùng chung.
final class ILHomeGreetingHeaderView: UIView {

    // MARK: - Properties
    var greetingText: String = "" {
        didSet { greetingLabel.text = greetingText }
    }

    var dateText: String = "" {
        didSet { dateLabel.text = dateText }
    }

    var avatarInitial: String = "" {
        didSet { avatarView.initials = avatarInitial }
    }

    var hasUnreadNotification: Bool = false {
        didSet { bellButton.hasUnread = hasUnreadNotification }
    }

    var onNotificationTap: (() -> Void)? {
        didSet { bellButton.onTap = onNotificationTap }
    }

    var onAvatarTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var greetingLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.displayMedium
        v.textColor = ILColors.ink
        v.numberOfLines = 1
        return v
    }()
    private lazy var dateLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.bodySmall
        v.textColor = ILColors.inkTertiary
        v.numberOfLines = 1
        return v
    }()
    private lazy var bellButton: ILNotificationBellButton = ILNotificationBellButton()
    private lazy var avatarView: ILAvatarView = {
        let v = ILAvatarView(initials: "", tone: .gold, size: 38)
        v.isUserInteractionEnabled = false
        return v
    }()
    private lazy var avatarControl: UIControl = {
        let v = UIControl()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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
        let textStack = UIStackView(arrangedSubviews: [greetingLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = 5
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        avatarControl.addTarget(self, action: #selector(handleAvatarTap), for: .touchUpInside)
        avatarControl.addSubview(avatarView)

        let actionsStack = UIStackView(arrangedSubviews: [bellButton, avatarControl])
        actionsStack.axis = .horizontal
        actionsStack.spacing = 8
        actionsStack.alignment = .center
        actionsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textStack)
        addSubview(actionsStack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: avatarControl.leadingAnchor),
            avatarView.trailingAnchor.constraint(equalTo: avatarControl.trailingAnchor),
            avatarView.topAnchor.constraint(equalTo: avatarControl.topAnchor),
            avatarView.bottomAnchor.constraint(equalTo: avatarControl.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            actionsStack.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 12),
            actionsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionsStack.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    @objc private func handleAvatarTap() {
        onAvatarTap?()
    }
}
