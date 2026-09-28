//
//  ILPhotosMasonryGridView.swift
//  InnerLamp
//

import UIKit

/// Lưới 2 cột kiểu masonry cho gallery "Ảnh chùa đẹp" — chiều cao mỗi ô theo ảnh (khớp `columns:2`
/// trong design handoff). Xếp ảnh vào cột đang thấp hơn để hai cột cân bằng. Riêng cho màn
/// `photos` nên ở `Scenes/Photos`, không phải component dùng chung.
final class ILPhotosMasonryGridView: UIView {

    // MARK: - Layout constants
    /// Khoảng cách giữa 2 cột (design handoff `column-gap:10px`).
    static let columnGap: CGFloat = ILMetrics.rowSpacing
    /// Khoảng cách dọc giữa các thẻ (design handoff `margin-bottom:14px`).
    static let itemGap: CGFloat = 14
    /// Chiều cao phần chú thích (tiêu đề tối đa 2 dòng + địa điểm + khoảng cách) ước lượng cho
    /// masonry — ô ảnh chiếm phần lớn chiều cao nên sai số 1 dòng không ảnh hưởng cân bằng cột.
    static let captionHeight: CGFloat = 60

    private static let cellReuseID = "ILPhotosPhotoCell"

    // MARK: - Properties
    var photos: [ILPhotosPhotoModel] = [] {
        didSet {
            guard photos != oldValue else { return }
            layout.itemHeights = photos.map { CGFloat($0.imageHeight) + Self.captionHeight }
            collectionView.reloadData()
        }
    }

    // MARK: - UI Elements
    private let layout = ILPhotosMasonryLayout()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = true
        view.dataSource = self
        view.register(ILPhotosPhotoCell.self, forCellWithReuseIdentifier: Self.cellReuseID)
        return view
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
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
                imageHeight: CGFloat(photo.imageHeight),
                categoryLabel: photo.categoryLabel
            )
        }
        return cell
    }
}

// MARK: - Masonry layout
/// Layout 2 cột tự cân bằng: mỗi ô được đặt vào cột có chiều cao hiện tại thấp hơn. Chiều cao
/// từng ô lấy từ `itemHeights` (do `ILPhotosMasonryGridView` tính sẵn).
private final class ILPhotosMasonryLayout: UICollectionViewLayout {

    var itemHeights: [CGFloat] = []
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

        cachedAttributes = []
        for index in 0..<itemHeights.count {
            let column = columnY[0] <= columnY[1] ? 0 : 1
            let indexPath = IndexPath(item: index, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(
                x: columnX[column],
                y: columnY[column],
                width: columnWidth,
                height: itemHeights[index]
            )
            cachedAttributes.append(attributes)
            columnY[column] += itemHeights[index] + itemGap
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

    private let cardView = ILPhotosPhotoCardView()

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

    func configure(title: String, place: String, imageHeight: CGFloat, categoryLabel: String) {
        cardView.configure(
            title: title,
            place: place,
            imageHeight: imageHeight,
            categoryLabel: categoryLabel
        )
    }
}
