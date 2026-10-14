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
        // Every Home state update re-assigns this; rebuilding re-creates every card and resets its
        // image, so only do it when the content actually changed.
        didSet { if articles != oldValue { rebuildRows() } }
    }

    /// Title of the shared empty block shown instead of the rows when there is no data
    /// ("Đang cập nhật"). Empty string hides it (still loading, or rows are present).
    var emptyText: String = "" {
        didSet { if emptyText != oldValue { updateEmptyState() } }
    }

    var emptyMessage: String = "" {
        didSet { emptyStateView.message = emptyMessage }
    }

    /// `true` while the first load is in flight and there are no rows yet: shows skeleton rows.
    var isLoading: Bool = false {
        didSet { if isLoading != oldValue { rebuildRows() } }
    }

    var onArticleTap: ((ILHomeArticleModel) -> Void)?

    // MARK: - UI Elements
    private lazy var rowsStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = ILMetrics.rowSpacing
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var emptyStateView: ILStateView = {
        let v = ILStateView(kind: .empty, title: "", message: "")
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    /// Only active while the empty block is visible, so the list takes its height instead of
    /// collapsing to zero with no rows.
    private lazy var emptyStateBottomConstraint = emptyStateView.bottomAnchor.constraint(equalTo: bottomAnchor)

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
        addSubview(rowsStack)

        addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: trailingAnchor),

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
        if isLoading && articles.isEmpty {
            for index in 0..<ILHomeSkeletonCards.articleRowCount {
                rowsStack.addArrangedSubview(ILHomeSkeletonCards.articleRow(index: index))
            }
        }
        for article in articles {
            let card = ILArticleCardView()
            card.configure(
                category: article.category,
                title: article.title,
                author: article.author,
                readText: article.readText,
                imageURL: article.thumbnailURL
            )
            card.onTap = { [weak self] in self?.onArticleTap?(article) }
            rowsStack.addArrangedSubview(card)
        }
        updateEmptyState()
    }

    private func updateEmptyState() {
        let showsPlaceholder = articles.isEmpty && !emptyText.isEmpty
        emptyStateView.title = emptyText
        emptyStateView.isHidden = !showsPlaceholder
        emptyStateBottomConstraint.isActive = showsPlaceholder
    }
}
