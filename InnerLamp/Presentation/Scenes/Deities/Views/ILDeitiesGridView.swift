//
//  ILDeitiesGridView.swift
//  InnerLamp
//

import UIKit

/// Lưới 2 cột đều cho màn danh sách "Chư Phật & Bồ Tát" — mỗi ô là 1 thẻ `ILDeitiesCardView`, hàng
/// lẻ cuối được chèn ô trống để thẻ đơn không giãn hết chiều ngang. Tự cuộn dọc bên trong. Riêng
/// cho màn `Deities` nên ở `Scenes/Deities` (khớp `grid-template-columns:repeat(2,1fr);gap:12px`
/// trong design handoff).
final class ILDeitiesGridView: UIView {

    // MARK: - Layout constants
    private static let columnCount = 2
    private static let columnGap: CGFloat = ILMetrics.spaceMedium
    private static let rowGap: CGFloat = ILMetrics.spaceMedium

    // MARK: - Properties
    var items: [ILDeitiesItemModel] = [] {
        didSet {
            guard items != oldValue else { return }
            rebuild()
        }
    }

    var onItemTap: ((ILDeitiesItemModel) -> Void)?

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        rowsStack.axis = .vertical
        rowsStack.spacing = Self.rowGap
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(rowsStack)

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rowsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: ILMetrics.spaceStandard),
            rowsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            rowsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            rowsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            rowsStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(horizontal * 2))
        ])
    }

    // MARK: - Rebuild
    private func rebuild() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        scrollView.setContentOffset(.zero, animated: false)

        var index = 0
        while index < items.count {
            let row = makeRow()
            for offset in 0..<Self.columnCount {
                let itemIndex = index + offset
                guard itemIndex < items.count else {
                    // Ô trống giữ chỗ để thẻ lẻ cuối hàng không giãn hết chiều ngang.
                    row.addArrangedSubview(UIView())
                    continue
                }
                let item = items[itemIndex]
                let card = ILDeitiesCardView()
                card.configure(with: item)
                card.onTap = { [weak self] in self?.onItemTap?(item) }
                row.addArrangedSubview(card)
            }
            rowsStack.addArrangedSubview(row)
            index += Self.columnCount
        }
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = Self.columnGap
        row.distribution = .fillEqually
        row.alignment = .top
        return row
    }
}
