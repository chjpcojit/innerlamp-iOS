//
//  ILPhotosMasonryGridView.swift
//  InnerLamp
//

import UIKit

/// Lưới 2 cột kiểu masonry cho gallery "Ảnh chùa đẹp" (khớp `columns:2` trong design handoff). Xếp
/// ảnh vào cột đang thấp hơn để hai cột cân bằng; hiện mọi ô cùng tỉ lệ 4:3 nên 2 cột xen kẽ đều.
/// Có footer load-more/end-of-list dưới lưới. Riêng cho màn `photos` nên ở `Scenes/Photos`, không
/// phải component dùng chung.
final class ILPhotosMasonryGridView: UIView {

    // MARK: - Layout constants
    /// Khoảng cách giữa 2 cột (design handoff `column-gap:10px`).
    static let columnGap: CGFloat = ILMetrics.rowSpacing
    /// Khoảng cách dọc giữa các thẻ (design handoff `margin-bottom:14px`).
    static let itemGap: CGFloat = 14
    /// Chiều cao phần chú thích (tiêu đề tối đa 2 dòng + địa điểm + khoảng cách) ước lượng cho
    /// masonry — ô ảnh chiếm phần lớn chiều cao nên sai số 1 dòng không ảnh hưởng cân bằng cột.
    static let captionHeight: CGFloat = 60

    /// Khoảng cách tới đáy nội dung để kích hoạt tải trang tiếp (design handoff: <120px).
    private static let loadMoreThreshold: CGFloat = 120

    /// Crossfade between two photo sets (category change).
    private static let crossfadeDuration: TimeInterval = 0.25

    private static let cellReuseID = "ILPhotosPhotoCell"

    // MARK: - Properties
    var photos: [ILPhotosPhotoModel] = [] {
        didSet {
            guard photos != oldValue else { return }
            layout.itemCount = photos.count
            // Load more only appends: insert just the new cells so the existing ones (and their
            // images) are not rebuilt. Any other change (e.g. a new category) reloads.
            if !oldValue.isEmpty, photos.count > oldValue.count, photos.starts(with: oldValue) {
                let inserted = (oldValue.count..<photos.count).map { IndexPath(item: $0, section: 0) }
                UIView.performWithoutAnimation {
                    collectionView.performBatchUpdates { collectionView.insertItems(at: inserted) }
                }
            } else {
                reloadWithCrossfade(animated: !oldValue.isEmpty && window != nil)
            }
        }
    }

    var footerState: ILLoadMoreFooterView.State = .hidden {
        didSet { footerView.state = footerState }
    }

    /// Fired from scrolling when the grid is within `loadMoreThreshold` of the bottom. May fire
    /// repeatedly; the consumer guards against duplicate requests.
    var onLoadMore: (() -> Void)?

    /// Fired with the photo id when a tile is tapped.
    var onPhotoTap: ((String) -> Void)?

    // MARK: - UI Elements
    private let layout = ILPhotosMasonryLayout()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = true
        view.dataSource = self
        view.delegate = self
        view.register(ILPhotosPhotoCell.self, forCellWithReuseIdentifier: Self.cellReuseID)
        return view
    }()

    private lazy var footerView: ILLoadMoreFooterView = {
        let view = ILLoadMoreFooterView(
            loadingText: "photos.loadingMore".localized,
            endText: "photos.end".localized
        )
        return view
    }()

    /// Replaces every cell. With `animated` the old grid dissolves into the new one and the list
    /// returns to the top (a new category starts from its first photo).
    private func reloadWithCrossfade(animated: Bool) {
        let reload = { [collectionView] in
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            collectionView.contentOffset = CGPoint(x: 0, y: -collectionView.adjustedContentInset.top)
        }
        guard animated else {
            reload()
            return
        }
        UIView.transition(
            with: collectionView,
            duration: Self.crossfadeDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: reload
        )
    }

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        // The footer sits in a stack so it collapses while hidden (`ILLoadMoreFooterView` is
        // designed for a `UIStackView`).
        let stack = UIStackView(arrangedSubviews: [collectionView, footerView])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UICollectionViewDataSource
extension ILPhotosMasonryGridView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellReuseID, for: indexPath)
        if let photoCell = cell as? ILPhotosPhotoCell {
            let photo = photos[indexPath.item]
            photoCell.configure(
                title: photo.title,
                place: photo.place,
                thumbnailURL: photo.thumbnailURL,
                heroID: ILPhotoViewerHeroID.make(photoID: photo.id)
            )
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate (scroll callbacks)
extension ILPhotosMasonryGridView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard photos.indices.contains(indexPath.item) else { return }
        onPhotoTap?(photos[indexPath.item].id)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let distanceToBottom = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.height)
        if distanceToBottom < Self.loadMoreThreshold {
            onLoadMore?()
        }
    }
}

// MARK: - Masonry layout
/// Layout 2 cột tự cân bằng: mỗi ô được đặt vào cột có chiều cao hiện tại thấp hơn. Chiều cao mỗi
/// ô = ô ảnh 4:3 theo bề rộng cột + phần chú thích.
private final class ILPhotosMasonryLayout: UICollectionViewLayout {

    var itemCount = 0
    var columnGap: CGFloat = ILPhotosMasonryGridView.columnGap
    var itemGap: CGFloat = ILPhotosMasonryGridView.itemGap
    var sectionInset = UIEdgeInsets(
        top: ILMetrics.spaceStandard,
        left: ILMetrics.screenHorizontal,
        bottom: ILMetrics.screenPadding.bottom,
        right: ILMetrics.screenHorizontal
    )

    private var cachedAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    override var collectionViewContentSize: CGSize {
        CGSize(width: collectionView?.bounds.width ?? 0, height: contentHeight)
    }

    override func prepare() {
        guard let collectionView, collectionView.bounds.width > 0 else {
            cachedAttributes = []
            contentHeight = 0
            return
        }

        let availableWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right
        let columnWidth = (availableWidth - columnGap) / 2
        let columnX: [CGFloat] = [
            sectionInset.left,
            sectionInset.left + columnWidth + columnGap
        ]
        var columnY: [CGFloat] = [sectionInset.top, sectionInset.top]

        let itemHeight = columnWidth * ILPhotosPhotoCardView.imageAspectRatio + ILPhotosMasonryGridView.captionHeight

        cachedAttributes = []
        for index in 0..<itemCount {
            let column = columnY[0] <= columnY[1] ? 0 : 1
            let indexPath = IndexPath(item: index, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(
                x: columnX[column],
                y: columnY[column],
                width: columnWidth,
                height: itemHeight
            )
            cachedAttributes.append(attributes)
            columnY[column] += itemHeight + itemGap
        }

        contentHeight = (columnY.max() ?? sectionInset.top) - itemGap + sectionInset.bottom
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cachedAttributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard cachedAttributes.indices.contains(indexPath.item) else { return nil }
        return cachedAttributes[indexPath.item]
    }
}

// MARK: - Cell
private final class ILPhotosPhotoCell: UICollectionViewCell {

    private lazy var cardView: ILPhotosPhotoCardView = {
        let view = ILPhotosPhotoCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
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

    func configure(title: String, place: String, thumbnailURL: String?, heroID: String) {
        cardView.configure(title: title, place: place, thumbnailURL: thumbnailURL, heroID: heroID)
    }
}
