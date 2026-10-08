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
        didSet { updateCards(from: oldValue) }
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

    /// Diffs against the previous list so a load-more only appends the new cards. Rebuilding every
    /// card on each state emission re-creates N views and resets their images (a re-decode per card),
    /// which stalls the main thread right when the user is scrolling.
    private func updateCards(from oldArticles: [ILArticlesArticleModel]) {
        guard articles != oldArticles else { return }

        let isAppendOnly = articles.count >= oldArticles.count
            && Array(articles.prefix(oldArticles.count)) == oldArticles
        guard isAppendOnly else {
            cardsStack.arrangedSubviews.forEach {
                cardsStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            articles.forEach(appendCard)
            return
        }
        articles.dropFirst(oldArticles.count).forEach(appendCard)
    }

    private func appendCard(for article: ILArticlesArticleModel) {
        let card = ILArticleCardView()
        card.configure(
            category: article.category,
            title: article.title,
            author: article.author,
            readText: article.readText,
            imageURL: article.thumbnailURL
        )
        card.onTap = { [weak self] in self?.onArticleTap?(article) }
        cardsStack.addArrangedSubview(card)
    }
}
