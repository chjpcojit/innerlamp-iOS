//
//  ILHomeTempleCarouselView.swift
//  InnerLamp
//

import UIKit

/// Carousel "Chùa Việt Nam" ở Trang chủ: cuộn ngang từng thẻ chùa (ảnh + badge vùng miền + tên +
/// địa chỉ + ghi chú), snap từng thẻ và lộ mép thẻ kế bên. Riêng cho Trang chủ nên ở `Scenes/Home`
/// (khác màn `temple` — trang chi tiết 1 chùa, chưa build).
final class ILHomeTempleCarouselView: UIView {

    // MARK: - Layout constants
    /// Card rộng 62% khung carousel để lộ ~1.5 thẻ (peek), khớp design handoff.
    private static let cardWidthRatio: CGFloat = 0.62
    private static let cardSpacing: CGFloat = 12
    /// Release velocity (points/ms) above which a swipe counts as a flick and pages in its direction.
    private static let flickVelocityThreshold: CGFloat = 0.2

    // MARK: - Properties
    var temples: [ILHomeTempleModel] = [] {
        // Every Home state update re-assigns this; only rebuild (and reset the scroll position) when
        // the content actually changed.
        didSet { if temples != oldValue { rebuildCards() } }
    }

    /// Placeholder shown instead of the cards when there is no data ("Đang cập nhật"). Empty string
    /// hides it (still loading, or cards are present).
    var emptyText: String = "" {
        didSet { if emptyText != oldValue { updateEmptyState() } }
    }

    /// `true` while the first load is in flight and there are no cards yet: shows skeleton cards.
    var isLoading: Bool = false {
        didSet { if isLoading != oldValue { rebuildCards() } }
    }

    var onTempleTap: ((ILHomeTempleModel) -> Void)?

    private var cardWidth: CGFloat { (bounds.width * Self.cardWidthRatio).rounded(.down) }
    private var pageStride: CGFloat { cardWidth + Self.cardSpacing }

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let cardsStack = UIStackView()
    private let emptyLabel = UILabel()
    /// Only active while the placeholder is visible, so the carousel takes the label's height
    /// instead of collapsing to zero with no cards.
    private lazy var emptyLabelBottomConstraint = emptyLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
    private var cardWidthConstraints: [NSLayoutConstraint] = []
    /// Page the carousel is resting on / snapping to; the base for the next swipe's target.
    private var currentPage = 0

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
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        cardsStack.axis = .horizontal
        cardsStack.spacing = Self.cardSpacing
        cardsStack.alignment = .top
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(cardsStack)

        addSubview(scrollView)

        emptyLabel.font = ILTypography.caption
        emptyLabel.textColor = ILColors.inkSubtle
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyLabel.topAnchor.constraint(equalTo: topAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            cardsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            cardsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            cardsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            cardsStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = cardWidth
        guard width > 0 else { return }
        scrollView.contentInset.right = max(0, bounds.width - width)
        for constraint in cardWidthConstraints where constraint.constant != width {
            constraint.constant = width
        }
    }

    private func rebuildCards() {
        cardsStack.arrangedSubviews.forEach {
            cardsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        cardWidthConstraints.removeAll()
        currentPage = 0
        scrollView.setContentOffset(.zero, animated: false)

        let width = max(cardWidth, 1)
        let showsSkeleton = isLoading && temples.isEmpty
        scrollView.isScrollEnabled = !showsSkeleton
        if showsSkeleton {
            for index in 0..<ILHomeSkeletonCards.carouselCount {
                let card = ILHomeSkeletonCards.templeCard(index: index)
                let widthConstraint = card.widthAnchor.constraint(equalToConstant: width)
                widthConstraint.isActive = true
                cardWidthConstraints.append(widthConstraint)
                cardsStack.addArrangedSubview(card)
            }
        }

        for temple in temples {
            let card = ILHomeTempleCardView(temple: temple)
            card.onTap = { [weak self] in self?.onTempleTap?(temple) }
            let widthConstraint = card.widthAnchor.constraint(equalToConstant: width)
            widthConstraint.isActive = true
            cardWidthConstraints.append(widthConstraint)
            cardsStack.addArrangedSubview(card)
        }
        updateEmptyState()
    }

    private func updateEmptyState() {
        let showsPlaceholder = temples.isEmpty && !emptyText.isEmpty
        emptyLabel.text = emptyText
        emptyLabel.isHidden = !showsPlaceholder
        emptyLabelBottomConstraint.isActive = showsPlaceholder
    }
}

// MARK: - UIScrollViewDelegate
extension ILHomeTempleCarouselView: UIScrollViewDelegate {
    /// Snap one card per swipe, decided by release velocity from `currentPage` so a short, fast
    /// flick always advances in the flick direction instead of snapping back (stutter).
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let stride = pageStride
        guard stride > 0, !temples.isEmpty else { return }
        let target: Int
        if velocity.x > Self.flickVelocityThreshold {
            target = currentPage + 1
        } else if velocity.x < -Self.flickVelocityThreshold {
            target = currentPage - 1
        } else {
            target = min(max(page(forOffset: scrollView.contentOffset.x), currentPage - 1), currentPage + 1)
        }
        currentPage = min(max(target, 0), temples.count - 1)
        targetContentOffset.pointee = CGPoint(x: CGFloat(currentPage) * stride, y: 0)
    }

    private func page(forOffset offset: CGFloat) -> Int {
        guard pageStride > 0, !temples.isEmpty else { return 0 }
        let raw = Int((offset / pageStride).rounded())
        return min(max(raw, 0), temples.count - 1)
    }
}

/// 1 thẻ chùa trong `ILHomeTempleCarouselView` — ảnh thumbnail + badge vùng miền + tên + địa
/// chỉ + ghi chú.
private final class ILHomeTempleCardView: UIControl {

    var onTap: (() -> Void)?

    private let temple: ILHomeTempleModel

    init(temple: ILHomeTempleModel) {
        self.temple = temple
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall + 2
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        // Ảnh thumbnail từ server (nền `tint` làm placeholder khi chưa có / lỗi) + badge vùng miền.
        let imageArea = ILRemoteImageView(frame: .zero)
        imageArea.backgroundColor = ILColors.tint
        imageArea.translatesAutoresizingMaskIntoConstraints = false
        // @ai: assumption — see Docs/Assumptions/Temple/AS-Temple-001-image-url-from-api.md
        imageArea.setImage(urlString: temple.thumbnailURL)

        let regionBadge = UILabel()
        regionBadge.font = ILTypography.captionMedium
        regionBadge.textColor = ILColors.inkOnDark
        regionBadge.text = temple.region
        regionBadge.textAlignment = .center
        regionBadge.backgroundColor = ILColors.scrim.withAlphaComponent(0.6)
        regionBadge.layer.cornerRadius = ILMetrics.radiusPill
        regionBadge.clipsToBounds = true
        regionBadge.translatesAutoresizingMaskIntoConstraints = false
        imageArea.addSubview(regionBadge)

        let nameLabel = UILabel()
        nameLabel.font = ILTypography.scriptureBodySmall
        nameLabel.textColor = ILColors.ink
        nameLabel.text = temple.name
        nameLabel.numberOfLines = 2

        let placeLabel = UILabel()
        placeLabel.font = ILTypography.subhead
        placeLabel.textColor = ILColors.inkTertiary
        placeLabel.text = temple.place
        placeLabel.numberOfLines = 1

        let noteLabel = UILabel()
        noteLabel.font = ILTypography.label
        noteLabel.textColor = ILColors.inkSubtle
        noteLabel.text = temple.note
        noteLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [nameLabel, placeLabel, noteLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.setCustomSpacing(8, after: placeLabel)
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageArea)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            imageArea.topAnchor.constraint(equalTo: topAnchor),
            imageArea.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageArea.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageArea.heightAnchor.constraint(equalToConstant: 150),

            regionBadge.leadingAnchor.constraint(equalTo: imageArea.leadingAnchor, constant: 10),
            regionBadge.topAnchor.constraint(equalTo: imageArea.topAnchor, constant: 10),

            textStack.topAnchor.constraint(equalTo: imageArea.bottomAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILHomeTempleCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
