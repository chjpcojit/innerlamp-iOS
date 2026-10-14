//
//  ILHomePhotoGridView.swift
//  InnerLamp
//

import UIKit

/// Khối "Ảnh chùa đẹp" ở Trang chủ: 1 ảnh lớn (trái, cao 2 hàng) + 2 ảnh nhỏ (phải), ảnh nhỏ
/// dưới cùng phủ nhãn "+N ảnh". Riêng cho Trang chủ (màn `photos` gallery khác bố cục) nên ở
/// `Scenes/Home`, không phải component dùng chung.
///
/// Ảnh tải qua `ILRemoteImageView` (3 ảnh đầu của `/v1/gallery/top`); nền tint ấm của nó là
/// placeholder khi chưa có ảnh hoặc ảnh lỗi.
final class ILHomePhotoGridView: UIView {

    // MARK: - Layout constants
    private static let rowHeight: CGFloat = 112
    private static let gap: CGFloat = 8

    // MARK: - Properties
    var photos: [ILHomePhotoModel] = [] {
        didSet {
            guard photos != oldValue else { return }
            for (index, tile) in tileImageViews.enumerated() {
                tile.setImage(urlString: photos.indices.contains(index) ? photos[index].thumbnailURL : nil)
            }
        }
    }

    /// Empty hides the "+N ảnh" overlay.
    var photosMoreText: String = "" {
        didSet {
            moreLabel.text = photosMoreText
            moreOverlay.isHidden = photosMoreText.isEmpty
        }
    }

    var photosMoreLabel: String = "" {
        didSet { moreUnitLabel.text = photosMoreLabel }
    }

    /// Chạm vào bất kỳ ô ảnh nào — cùng đi tới màn `photos` (chưa build, xem TODO ở ViewController).
    var onTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var largeTile: UIControl = {
        let v = UIControl()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ILColors.tint
        v.layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        v.clipsToBounds = true
        return v
    }()
    private lazy var smallTileTop: UIControl = {
        let v = UIControl()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ILColors.tint
        v.layer.cornerRadius = ILMetrics.radiusInput + 2
        v.clipsToBounds = true
        return v
    }()
    private lazy var smallTileBottom: UIControl = {
        let v = UIControl()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ILColors.tint
        v.layer.cornerRadius = ILMetrics.radiusInput + 2
        v.clipsToBounds = true
        return v
    }()

    private lazy var largeImage: ILRemoteImageView = {
        let v = ILRemoteImageView(frame: .zero)
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var smallTopImage: ILRemoteImageView = {
        let v = ILRemoteImageView(frame: .zero)
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var smallBottomImage: ILRemoteImageView = {
        let v = ILRemoteImageView(frame: .zero)
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    /// In tile order (large, small top, small bottom) — matches `photos` indices.
    private var tileImageViews: [ILRemoteImageView] { [largeImage, smallTopImage, smallBottomImage] }

    private lazy var moreOverlay: UIView = {
        let v = UIView()
        v.isHidden = true
        v.backgroundColor = ILColors.scrim.withAlphaComponent(0.52)
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var moreLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.scriptureTitle
        v.textColor = ILColors.inkOnDark
        v.textAlignment = .center
        v.numberOfLines = 1
        return v
    }()
    private lazy var moreUnitLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        v.textColor = ILColors.inkOnDarkSecondary
        v.textAlignment = .center
        v.numberOfLines = 1
        return v
    }()

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
        for tile in [largeTile, smallTileTop, smallTileBottom] {
            tile.addTarget(self, action: #selector(handleTileTap), for: .touchUpInside)
        }

        for (tile, image) in [(largeTile, largeImage), (smallTileTop, smallTopImage), (smallTileBottom, smallBottomImage)] {
            tile.addSubview(image)
            NSLayoutConstraint.activate([
                image.topAnchor.constraint(equalTo: tile.topAnchor),
                image.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
                image.trailingAnchor.constraint(equalTo: tile.trailingAnchor),
                image.bottomAnchor.constraint(equalTo: tile.bottomAnchor)
            ])
        }

        let overlayStack = UIStackView(arrangedSubviews: [moreLabel, moreUnitLabel])
        overlayStack.axis = .vertical
        overlayStack.spacing = 2
        overlayStack.alignment = .center
        overlayStack.translatesAutoresizingMaskIntoConstraints = false
        moreOverlay.addSubview(overlayStack)
        smallTileBottom.addSubview(moreOverlay)

        let rightColumn = UIStackView(arrangedSubviews: [smallTileTop, smallTileBottom])
        rightColumn.axis = .vertical
        rightColumn.spacing = Self.gap
        rightColumn.distribution = .fillEqually
        rightColumn.translatesAutoresizingMaskIntoConstraints = false

        addSubview(largeTile)
        addSubview(rightColumn)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.rowHeight * 2 + Self.gap),

            largeTile.topAnchor.constraint(equalTo: topAnchor),
            largeTile.leadingAnchor.constraint(equalTo: leadingAnchor),
            largeTile.bottomAnchor.constraint(equalTo: bottomAnchor),

            rightColumn.topAnchor.constraint(equalTo: topAnchor),
            rightColumn.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightColumn.bottomAnchor.constraint(equalTo: bottomAnchor),

            largeTile.trailingAnchor.constraint(equalTo: rightColumn.leadingAnchor, constant: -Self.gap),
            largeTile.widthAnchor.constraint(equalTo: rightColumn.widthAnchor, multiplier: 1.35),

            moreOverlay.leadingAnchor.constraint(equalTo: smallTileBottom.leadingAnchor),
            moreOverlay.trailingAnchor.constraint(equalTo: smallTileBottom.trailingAnchor),
            moreOverlay.topAnchor.constraint(equalTo: smallTileBottom.topAnchor),
            moreOverlay.bottomAnchor.constraint(equalTo: smallTileBottom.bottomAnchor),

            overlayStack.centerXAnchor.constraint(equalTo: moreOverlay.centerXAnchor),
            overlayStack.centerYAnchor.constraint(equalTo: moreOverlay.centerYAnchor)
        ])
    }

    @objc private func handleTileTap() {
        onTap?()
    }
}
