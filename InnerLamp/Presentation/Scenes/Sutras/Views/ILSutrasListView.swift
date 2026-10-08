//
//  ILSutrasListView.swift
//  InnerLamp
//

import UIKit

/// Danh sách dọc cuộn được của màn "Kinh sách": dòng đếm kết quả ("3 bản kinh phù hợp") rồi các
/// thẻ `ILSutrasCardView`. Riêng cho màn `Sutras`.
final class ILSutrasListView: UIView {

    // MARK: - Properties
    var countText: String = "" {
        didSet { countLabel.text = countText }
    }

    var items: [ILSutrasItemModel] = [] {
        didSet {
            guard items != oldValue else { return }
            updateCards(from: oldValue)
        }
    }

    var footerState: ILLoadMoreFooterView.State = .hidden {
        didSet { footerView.state = footerState }
    }

    var onItemTap: ((ILSutrasItemModel) -> Void)?
    /// Fired when the scroll view nears the bottom of the list.
    var onLoadMore: (() -> Void)?

    /// Distance from the bottom of the scroll content at which a load-more is triggered.
    private static let loadMoreThreshold: CGFloat = 120

    // MARK: - UI Elements
    /// Exposed so the screen can inset it under the sticky header and bind `ILStickyHeaderBand` to it.
    let scrollView = UIScrollView()
    private let countLabel = UILabel()
    private let cardsStack = UIStackView()
    private let footerView = ILLoadMoreFooterView(
        loadingText: "sutras.loadingMore".localized,
        endText: "sutras.end".localized
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .onDrag
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        countLabel.font = ILTypography.subhead
        countLabel.textColor = ILColors.inkSubtle

        cardsStack.axis = .vertical
        cardsStack.spacing = ILMetrics.rowSpacing

        let content = UIStackView(arrangedSubviews: [countLabel, cardsStack, footerView])
        content.axis = .vertical
        content.spacing = ILMetrics.rowSpacing
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        let horizontal = ILMetrics.screenHorizontal
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceLarge),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * horizontal)
        ])
    }

    // MARK: - Cards
    /// Diffs against the previous list so a load-more only appends the new cards. Rebuilding every
    /// card on each state emission re-creates N views, which stalls the main thread while the user
    /// is scrolling.
    private func updateCards(from oldItems: [ILSutrasItemModel]) {
        let isAppendOnly = items.count >= oldItems.count
            && Array(items.prefix(oldItems.count)) == oldItems
        guard isAppendOnly else {
            cardsStack.arrangedSubviews.forEach {
                cardsStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            items.forEach(appendCard)
            return
        }
        items.dropFirst(oldItems.count).forEach(appendCard)
    }

    private func appendCard(for item: ILSutrasItemModel) {
        let card = ILSutrasCardView()
        card.configure(with: item)
        card.onTap = { [weak self] in self?.onItemTap?(item) }
        cardsStack.addArrangedSubview(card)
    }
}

// MARK: - UIScrollViewDelegate
extension ILSutrasListView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let distanceToBottom = scrollView.contentSize.height
            - (scrollView.contentOffset.y + scrollView.bounds.height)
        if distanceToBottom < Self.loadMoreThreshold {
            onLoadMore?()
        }
    }
}
