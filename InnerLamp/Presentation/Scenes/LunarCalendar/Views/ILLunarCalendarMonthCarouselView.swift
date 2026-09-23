//
//  ILLunarCalendarMonthCarouselView.swift
//  InnerLamp
//

import UIKit

/// Carousel ngang các tháng: thẻ rộng 86% màn hình, snap từng tháng, lộ mép tháng kế bên. Vuốt
/// tay báo `onPageChanged` trực tiếp (header đổi theo tháng đang xem); `scroll(toPage:)` do nút
/// ‹ › gọi và không báo lại trong lúc đang cuộn để tránh vòng lặp với ViewModel.
final class ILLunarCalendarMonthCarouselView: UIView {

    // MARK: - Layout constants
    private static let cardWidthRatio: CGFloat = 0.86
    private static let cardSpacing: CGFloat = 12
    private static let cellReuseID = "ILLunarCalendarMonthCell"

    // MARK: - Properties
    var months: [ILLunarCalendarMonthModel] = [] {
        didSet {
            guard months != oldValue else { return }
            collectionView.reloadData()
        }
    }

    var weekdayLabels: [String] = [] {
        didSet {
            guard weekdayLabels != oldValue else { return }
            collectionView.reloadData()
        }
    }

    var onDayTap: ((String) -> Void)?
    var onPageChanged: ((Int) -> Void)?

    private var lastReportedPage = 0
    private var isProgrammaticScroll = false
    private var lastLayoutWidth: CGFloat = 0

    private var cardWidth: CGFloat { bounds.width * Self.cardWidthRatio }
    private var pitch: CGFloat { cardWidth + Self.cardSpacing }

    // MARK: - UI Elements
    private let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = ILLunarCalendarMonthCarouselView.cardSpacing
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.decelerationRate = .fast
        view.dataSource = self
        view.delegate = self
        view.register(ILLunarCalendarMonthCell.self, forCellWithReuseIdentifier: Self.cellReuseID)
        return view
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: ILLunarCalendarMonthCardView.height(forWidth: cardWidth)
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.width != lastLayoutWidth else { return }
        lastLayoutWidth = bounds.width

        let sideInset = ILMetrics.screenHorizontal
        let itemHeight = ILLunarCalendarMonthCardView.height(forWidth: cardWidth)
        flowLayout.itemSize = CGSize(width: cardWidth, height: itemHeight)
        // Inset phải đủ lớn để tháng cuối cũng snap được về mép trái (offset tối đa = (n-1) * pitch).
        flowLayout.sectionInset = UIEdgeInsets(
            top: 0,
            left: sideInset,
            bottom: 0,
            right: max(sideInset, bounds.width - cardWidth - sideInset)
        )
        flowLayout.invalidateLayout()
        invalidateIntrinsicContentSize()

        collectionView.contentOffset.x = CGFloat(lastReportedPage) * pitch
    }

    // MARK: - Paging
    /// Cuộn tới `page`; không làm gì nếu carousel đã ở trang đó.
    func scroll(toPage page: Int, animated: Bool) {
        guard pitch > 0, months.indices.contains(page), page != lastReportedPage else { return }
        lastReportedPage = page
        isProgrammaticScroll = animated
        collectionView.setContentOffset(CGPoint(x: CGFloat(page) * pitch, y: 0), animated: animated)
    }

    private func page(forOffset offset: CGFloat) -> Int {
        guard pitch > 0, !months.isEmpty else { return 0 }
        let raw = Int((offset / pitch).rounded())
        return min(max(raw, 0), months.count - 1)
    }
}

// MARK: - UICollectionViewDataSource
extension ILLunarCalendarMonthCarouselView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        months.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellReuseID, for: indexPath)
        if let monthCell = cell as? ILLunarCalendarMonthCell {
            monthCell.configure(month: months[indexPath.item], weekdayLabels: weekdayLabels)
            monthCell.onDayTap = { [weak self] id in self?.onDayTap?(id) }
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ILLunarCalendarMonthCarouselView: UICollectionViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isProgrammaticScroll else { return }
        let page = page(forOffset: scrollView.contentOffset.x)
        guard page != lastReportedPage else { return }
        lastReportedPage = page
        onPageChanged?(page)
    }

    /// Snap từng tháng: tối đa 1 trang mỗi lần vuốt, dù vận tốc lớn.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard pitch > 0 else { return }
        let current = page(forOffset: scrollView.contentOffset.x)
        let projected = page(forOffset: targetContentOffset.pointee.x)
        let target = min(max(projected, current - 1), current + 1)
        targetContentOffset.pointee.x = CGFloat(min(max(target, 0), max(months.count - 1, 0))) * pitch
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }
}

// MARK: - Cell
private final class ILLunarCalendarMonthCell: UICollectionViewCell {

    var onDayTap: ((String) -> Void)? {
        didSet { cardView.onDayTap = onDayTap }
    }

    private let cardView = ILLunarCalendarMonthCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(month: ILLunarCalendarMonthModel, weekdayLabels: [String]) {
        cardView.configure(month: month, weekdayLabels: weekdayLabels)
    }
}
