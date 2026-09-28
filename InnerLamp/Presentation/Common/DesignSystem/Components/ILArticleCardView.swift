//
//  ILArticleCardView.swift
//  InnerLamp
//

import UIKit

/// Reusable article list card (design handoff "arts"/"Bài viết Phật pháp hay"): an 84×84
/// thumbnail on the left, then a category eyebrow, a two-line title, and an "author · read time"
/// meta line. Generic over plain display strings so any list (Home, All articles) can feed it.
public final class ILArticleCardView: UIControl {

    // MARK: - Properties
    public var onTap: (() -> Void)?

    // MARK: - UI Elements
    private let thumbnailView = UIView()
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()

    // MARK: - Initializer
    public init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
    public func configure(category: String, title: String, author: String, readText: String) {
        categoryLabel.attributedText = ILTypography.makeEyebrow(text: category, color: ILColors.link)
        titleLabel.text = title
        metaLabel.text = "\(author) · \(readText)"
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        // Thumbnail placeholder — real imagery comes from the product side later.
        thumbnailView.backgroundColor = ILColors.sunk2
        thumbnailView.layer.cornerRadius = ILMetrics.radiusInput
        thumbnailView.clipsToBounds = true
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        categoryLabel.numberOfLines = 1

        titleLabel.font = ILTypography.scriptureBodySmall
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        metaLabel.font = ILTypography.label
        metaLabel.textColor = ILColors.inkSubtle
        metaLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [categoryLabel, titleLabel, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.setCustomSpacing(6, after: titleLabel)
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = UIStackView(arrangedSubviews: [thumbnailView, textStack])
        contentStack.axis = .horizontal
        contentStack.spacing = ILMetrics.spaceMedium
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            thumbnailView.widthAnchor.constraint(equalToConstant: 84),
            thumbnailView.heightAnchor.constraint(equalToConstant: 84),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILArticleCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }

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
