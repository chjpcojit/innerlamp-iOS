//
//  ILArticlesListView.swift
//  InnerLamp
//

import UIKit

/// The "All articles" list body — a vertical stack of `ILArticleCardView` rows followed by the
/// shared load-more/end-of-list footer. Feature-scoped: it's a screen-specific composition of
/// shared primitives, not a reusable primitive itself. The footer lives in a stack so it collapses
/// cleanly while hidden (`ILLoadMoreFooterView` is designed to sit in a `UIStackView`).
final class ILArticlesListView: UIView {

    // MARK: - Properties
    var articles: [ILArticlesArticleModel] = [] {
        didSet { rebuildCards() }
    }

    var footerState: ILLoadMoreFooterView.State = .hidden {
        didSet { footerView.state = footerState }
    }

    var onArticleTap: ((ILArticlesArticleModel) -> Void)?

    // MARK: - UI Elements
    private let outerStack = UIStackView()
    private let cardsStack = UIStackView()
    private let footerView = ILLoadMoreFooterView(
        loadingText: "articles.loadingMore".localized,
        endText: "articles.end".localized
    )

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
        translatesAutoresizingMaskIntoConstraints = false

        cardsStack.axis = .vertical
        cardsStack.spacing = ILMetrics.rowSpacing

        outerStack.axis = .vertical
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.addArrangedSubview(cardsStack)
        outerStack.addArrangedSubview(footerView)
        addSubview(outerStack)

        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: topAnchor),
            outerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func rebuildCards() {
        cardsStack.arrangedSubviews.forEach {
            cardsStack.removeArrangedSubview($0)
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
            cardsStack.addArrangedSubview(card)
        }
    }
}
