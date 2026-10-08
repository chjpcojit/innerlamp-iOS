//
//  ILArticleNextArticleListView.swift
//  InnerLamp
//

import UIKit

/// Danh sách "Đọc tiếp" cuối màn Bài viết — mỗi hàng: danh mục (eyebrow chữ hoa) + tiêu đề Lora +
/// mũi tên "›", ngăn cách bằng hairline đáy (khớp `nextArts` trong design handoff).
final class ILArticleNextArticleListView: UIView {

    // MARK: - Properties
    var articles: [ILArticleNextArticleModel] = [] {
        didSet { if articles != oldValue { rebuildRows() } }
    }

    var onArticleTap: ((String) -> Void)?

    // MARK: - UI Elements
    private let rowsStack = UIStackView()

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
        rowsStack.axis = .vertical
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func rebuildRows() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for article in articles {
            let row = ILArticleNextArticleRowView(article: article)
            row.onTap = { [weak self] in self?.onArticleTap?(article.id) }
            rowsStack.addArrangedSubview(row)
        }
    }
}

/// 1 hàng trong `ILArticleNextArticleListView`.
private final class ILArticleNextArticleRowView: UIControl {

    var onTap: (() -> Void)?

    private let article: ILArticleNextArticleModel

    init(article: ILArticleNextArticleModel) {
        self.article = article
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        let categoryLabel = UILabel()
        categoryLabel.attributedText = ILTypography.makeAttributedString(
            text: article.categoryLabel.uppercased(),
            font: ILTypography.eyebrowSmall,
            color: ILColors.link,
            letterSpacingEm: 0.12
        )
        categoryLabel.numberOfLines = 1

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.scriptureBodySmall
        titleLabel.textColor = ILColors.ink
        titleLabel.text = article.title
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        let textStack = UIStackView(arrangedSubviews: [categoryLabel, titleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevronLabel = UILabel()
        chevronLabel.font = ILTypography.chevron
        chevronLabel.textColor = ILColors.inkFaint
        chevronLabel.text = "›"
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        let hairline = UIView()
        hairline.backgroundColor = ILColors.border
        hairline.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textStack)
        addSubview(chevronLabel)
        addSubview(hairline)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -ILMetrics.spaceSmall),
            textStack.bottomAnchor.constraint(equalTo: hairline.topAnchor, constant: -ILMetrics.spaceMedium),

            chevronLabel.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
            chevronLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
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
