//
//  ILHomeArticleListView.swift
//  InnerLamp
//

import UIKit

/// "Bài viết Phật pháp hay" list on Home — a vertical stack of shared `ILArticleCardView` cards.
/// Home-scoped because it binds Home's `ILHomeArticleModel`; the card itself is the shared
/// `ILArticleCardView` primitive.
final class ILHomeArticleListView: UIView {

    // MARK: - Properties
    var articles: [ILHomeArticleModel] = [] {
        didSet { rebuildRows() }
    }

    var onArticleTap: ((ILHomeArticleModel) -> Void)?

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
        rowsStack.spacing = ILMetrics.rowSpacing
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
            let card = ILArticleCardView()
            card.configure(
                category: article.category,
                title: article.title,
                author: article.author,
                readText: article.readText
            )
            card.onTap = { [weak self] in self?.onArticleTap?(article) }
            rowsStack.addArrangedSubview(card)
        }
    }
}
