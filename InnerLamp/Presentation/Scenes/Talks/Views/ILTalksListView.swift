//
//  ILTalksListView.swift
//  InnerLamp
//

import UIKit

/// Danh sách dọc cuộn được của màn "Pháp thoại" (danh sách): các thẻ `ILTalksCardView`. Riêng
/// cho màn `Talks`.
final class ILTalksListView: UIView {

    // MARK: - Properties
    var items: [ILTalksItemModel] = [] {
        didSet {
            guard items != oldValue else { return }
            rebuild()
        }
    }

    var onItemTap: ((ILTalksItemModel) -> Void)?

    // MARK: - UI Elements
    /// Exposed so the screen can inset it under the sticky header and bind `ILStickyHeaderBand` to it.
    let scrollView = UIScrollView()
    private let cardsStack = UIStackView()

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
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        cardsStack.axis = .vertical
        cardsStack.spacing = ILMetrics.rowSpacing
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(cardsStack)

        let horizontal = ILMetrics.screenHorizontal
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            cardsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            cardsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            cardsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceLarge),
            cardsStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * horizontal)
        ])
    }

    // MARK: - Rebuild
    private func rebuild() {
        cardsStack.arrangedSubviews.forEach {
            cardsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in items {
            let card = ILTalksCardView()
            card.configure(with: item)
            card.onTap = { [weak self] in self?.onItemTap?(item) }
            cardsStack.addArrangedSubview(card)
        }
    }
}
