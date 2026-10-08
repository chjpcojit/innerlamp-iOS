//
//  ILHomeDeityCarouselView.swift
//  InnerLamp
//

import UIKit

/// Carousel "Thư viện Phật & Bồ Tát" ở Trang chủ: cuộn ngang các thẻ dọc cố định 124pt (ảnh
/// placeholder + badge loại + danh xưng + ngày vía). Riêng cho Trang chủ nên ở `Scenes/Home`
/// (khác màn chi tiết `Deity`).
final class ILHomeDeityCarouselView: UIView {

    // MARK: - Layout constants
    /// Kích thước thẻ khớp design handoff (`flex: 0 0 124px`, ảnh cao 164px).
    fileprivate static let cardWidth: CGFloat = 124
    fileprivate static let imageHeight: CGFloat = 164
    private static let cardSpacing: CGFloat = 12

    // MARK: - Properties
    var deities: [ILHomeDeityModel] = [] {
        // Every Home state update re-assigns this; only rebuild (and reset the scroll position) when
        // the content actually changed.
        didSet { if deities != oldValue { rebuildCards() } }
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

    var onDeityTap: ((ILHomeDeityModel) -> Void)?

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let cardsStack = UIStackView()
    private let emptyLabel = UILabel()
    /// Only active while the placeholder is visible, so the carousel takes the label's height
    /// instead of collapsing to zero with no cards.
    private lazy var emptyLabelBottomConstraint = emptyLabel.bottomAnchor.constraint(equalTo: bottomAnchor)

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

    private func rebuildCards() {
        cardsStack.arrangedSubviews.forEach {
            cardsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        scrollView.setContentOffset(.zero, animated: false)

        let showsSkeleton = isLoading && deities.isEmpty
        scrollView.isScrollEnabled = !showsSkeleton
        if showsSkeleton {
            for index in 0..<ILHomeSkeletonCards.carouselCount {
                let card = ILHomeSkeletonCards.deityCard(index: index, imageHeight: Self.imageHeight)
                card.widthAnchor.constraint(equalToConstant: Self.cardWidth).isActive = true
                cardsStack.addArrangedSubview(card)
            }
        }

        for deity in deities {
            let card = ILHomeDeityCardView(deity: deity)
            card.onTap = { [weak self] in self?.onDeityTap?(deity) }
            cardsStack.addArrangedSubview(card)
        }
        updateEmptyState()
    }

    private func updateEmptyState() {
        let showsPlaceholder = deities.isEmpty && !emptyText.isEmpty
        emptyLabel.text = emptyText
        emptyLabel.isHidden = !showsPlaceholder
        emptyLabelBottomConstraint.isActive = showsPlaceholder
    }
}

// MARK: - UIScrollViewDelegate
extension ILHomeDeityCarouselView: UIScrollViewDelegate {
    /// Snap mép trái về đầu thẻ gần nhất (`scroll-snap-align: start` trong prototype).
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let stride = Self.cardWidth + Self.cardSpacing
        let maxOffset = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        let page = (targetContentOffset.pointee.x / stride).rounded()
        targetContentOffset.pointee.x = min(max(page * stride, 0), maxOffset)
    }
}

/// 1 thẻ Phật / Bồ Tát trong `ILHomeDeityCarouselView` — ảnh placeholder + badge loại, danh xưng
/// và dòng ngày vía bên dưới.
private final class ILHomeDeityCardView: UIControl {

    var onTap: (() -> Void)?

    private let deity: ILHomeDeityModel
    private let imageArea = ILRemoteImageView(frame: .zero)

    init(deity: ILHomeDeityModel) {
        self.deity = deity
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        // Ảnh thumbnail từ server (nền `tint` làm placeholder khi chưa có / lỗi) + badge loại.
        imageArea.backgroundColor = ILColors.tint
        imageArea.layer.cornerRadius = ILMetrics.radiusCardSmall
        imageArea.layer.borderWidth = 1
        imageArea.layer.borderColor = ILColors.border.cgColor
        imageArea.clipsToBounds = true
        imageArea.isUserInteractionEnabled = false
        imageArea.setImage(urlString: deity.thumbnailURL)
        imageArea.translatesAutoresizingMaskIntoConstraints = false

        // Badge pill: nền scrim 60% + padding 3/8 (khớp `padding: 3px 8px` trong prototype).
        let kindBadge = UIView()
        kindBadge.backgroundColor = ILColors.scrim.withAlphaComponent(0.6)
        kindBadge.layer.cornerRadius = ILMetrics.radiusPill
        kindBadge.clipsToBounds = true
        kindBadge.translatesAutoresizingMaskIntoConstraints = false
        imageArea.addSubview(kindBadge)

        let kindLabel = UILabel()
        kindLabel.font = ILTypography.captionSmall
        kindLabel.textColor = ILColors.inkOnDark
        kindLabel.text = deity.kindLabel
        kindLabel.translatesAutoresizingMaskIntoConstraints = false
        kindBadge.addSubview(kindLabel)

        let nameLabel = UILabel()
        nameLabel.font = ILTypography.scriptureDescription
        nameLabel.textColor = ILColors.ink
        nameLabel.text = deity.name
        nameLabel.numberOfLines = 2

        let memorialLabel = UILabel()
        memorialLabel.font = ILTypography.caption
        memorialLabel.textColor = ILColors.inkSubtle
        memorialLabel.text = deity.memorialText
        memorialLabel.isHidden = deity.memorialText.isEmpty

        let textStack = UIStackView(arrangedSubviews: [nameLabel, memorialLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageArea)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: ILHomeDeityCarouselView.cardWidth),

            imageArea.topAnchor.constraint(equalTo: topAnchor),
            imageArea.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageArea.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageArea.heightAnchor.constraint(equalToConstant: ILHomeDeityCarouselView.imageHeight),

            kindBadge.leadingAnchor.constraint(equalTo: imageArea.leadingAnchor, constant: ILMetrics.spaceSmall),
            kindBadge.topAnchor.constraint(equalTo: imageArea.topAnchor, constant: ILMetrics.spaceSmall),

            kindLabel.topAnchor.constraint(equalTo: kindBadge.topAnchor, constant: 3),
            kindLabel.bottomAnchor.constraint(equalTo: kindBadge.bottomAnchor, constant: -3),
            kindLabel.leadingAnchor.constraint(equalTo: kindBadge.leadingAnchor, constant: ILMetrics.spaceSmall),
            kindLabel.trailingAnchor.constraint(equalTo: kindBadge.trailingAnchor, constant: -ILMetrics.spaceSmall),

            textStack.topAnchor.constraint(equalTo: imageArea.bottomAnchor, constant: ILMetrics.spaceSmall),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILHomeDeityCardView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyColorAppearanceChange() {
        imageArea.layer.borderColor = ILColors.border.cgColor
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
