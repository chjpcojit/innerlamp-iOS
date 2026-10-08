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
    private let largeTile = UIControl()
    private let smallTileTop = UIControl()
    private let smallTileBottom = UIControl()

    private let largeImage = ILRemoteImageView(frame: .zero)
    private let smallTopImage = ILRemoteImageView(frame: .zero)
    private let smallBottomImage = ILRemoteImageView(frame: .zero)
    /// In tile order (large, small top, small bottom) — matches `photos` indices.
    private var tileImageViews: [ILRemoteImageView] { [largeImage, smallTopImage, smallBottomImage] }

    private let moreOverlay = UIView()
    private let moreLabel = UILabel()
    private let moreUnitLabel = UILabel()

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
        configureTile(largeTile, radius: ILMetrics.radiusCardSmall + 2)
        configureTile(smallTileTop, radius: ILMetrics.radiusInput + 2)
        configureTile(smallTileBottom, radius: ILMetrics.radiusInput + 2)

        moreOverlay.isHidden = true
        for (tile, image) in [(largeTile, largeImage), (smallTileTop, smallTopImage), (smallTileBottom, smallBottomImage)] {
            image.isUserInteractionEnabled = false
            image.translatesAutoresizingMaskIntoConstraints = false
            tile.addSubview(image)
            NSLayoutConstraint.activate([
                image.topAnchor.constraint(equalTo: tile.topAnchor),
                image.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
                image.trailingAnchor.constraint(equalTo: tile.trailingAnchor),
                image.bottomAnchor.constraint(equalTo: tile.bottomAnchor)
            ])
        }

        moreOverlay.backgroundColor = ILColors.scrim.withAlphaComponent(0.52)
        moreOverlay.isUserInteractionEnabled = false
        moreOverlay.translatesAutoresizingMaskIntoConstraints = false

        moreLabel.font = ILTypography.scriptureTitle
        moreLabel.textColor = ILColors.inkOnDark
        moreLabel.textAlignment = .center
        moreLabel.numberOfLines = 1

        moreUnitLabel.font = ILTypography.label
        moreUnitLabel.textColor = ILColors.inkOnDarkSecondary
        moreUnitLabel.textAlignment = .center
        moreUnitLabel.numberOfLines = 1

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

    private func configureTile(_ tile: UIControl, radius: CGFloat) {
        tile.translatesAutoresizingMaskIntoConstraints = false
        tile.backgroundColor = ILColors.tint
        tile.layer.cornerRadius = radius
        tile.clipsToBounds = true
        tile.addTarget(self, action: #selector(handleTileTap), for: .touchUpInside)
    }

    @objc private func handleTileTap() {
        onTap?()
    }
}
