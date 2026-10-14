//
//  ILTempleHeroView.swift
//  InnerLamp
//

import UIKit

/// Hero Trang chùa — khớp `isTemple` trong design handoff: nền gradient `--il-th-bg` (đổi theo
/// light/dark, tan dần vào `canvas`), quầng sáng vàng ở đỉnh, 2 chip (cấp di tích · hệ phái), tên
/// chùa Lora, dòng "Còn gọi: …" (ẩn nếu không có tên dân gian) và dòng địa điểm.
///
/// Ảnh chùa ghim trên cùng, co giãn khi kéo xuống và mờ dần khi cuộn lên — do
/// `ILStretchyHeaderView` đảm nhiệm; gradient + quầng sáng nằm ở `backgroundView` (dưới ảnh).
///
/// Header (nút ‹) không nằm ở đây mà là `ILNavBar` trong suốt đè lên trên — xem
/// `ILTempleViewController`.
final class ILTempleHeroView: ILStretchyHeaderView {

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let bottomInset: CGFloat = 36
        static let topInset: CGFloat = 110
        static let photoHeight: CGFloat = 220
        static let imageToContentSpacing: CGFloat = 16
        static let glowDiameter: CGFloat = 340
        static let glowTopInset: CGFloat = 20
        static let chipHeight: CGFloat = 21
        static let chipHorizontalInset: CGFloat = 10
    }

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    /// Temple photo = `imageView` of `ILStretchyHeaderView`: full width, `Layout.photoHeight` tall,
    /// filled edge to edge. `imageHeight` is 0 when the temple has no photo, so the hero is unchanged then.
    private var contentTopConstraint: NSLayoutConstraint?

    private lazy var rankChipLabel = ILTempleHeroChipLabel(textColor: ILColors.templeHeaderInk)
    private lazy var sectChipLabel = ILTempleHeroChipLabel(textColor: ILColors.templeHeaderSub)
    private lazy var chipsRow: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 6
        v.alignment = .center
        v.isUserInteractionEnabled = false
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.talkTitle
        v.textColor = ILColors.templeHeaderInk
        v.numberOfLines = 2
        return v
    }()
    private lazy var aliasLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.heroSubtitleItalic
        v.textColor = ILColors.templeHeaderSub
        v.numberOfLines = 1
        return v
    }()
    private lazy var placeLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.note
        v.textColor = ILColors.templeHeaderSub
        v.numberOfLines = 1
        return v
    }()
    private lazy var contentStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 6
        v.alignment = .leading
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(
        rankChip: String, sectChip: String, name: String,
        hasAlias: Bool, aliasLine: String, placeLine: String, imageURL: String?
    ) {
        let hasImage = imageURL?.isEmpty == false
        imageView.setImage(urlString: hasImage ? imageURL : nil)
        imageHeight = hasImage ? Layout.photoHeight : 0
        contentTopConstraint?.constant = hasImage
            ? Layout.photoHeight + Layout.imageToContentSpacing
            : Layout.topInset
        rankChipLabel.text = rankChip
        sectChipLabel.text = sectChip
        titleLabel.text = name
        aliasLabel.text = aliasLine
        aliasLabel.isHidden = !hasAlias
        placeLabel.text = placeLine
    }

    // MARK: - Setup
    private func setupViews() {
        // Nền `--il-th-bg`: 3 chặng gradient tan dần vào `canvas` — không có đường cắt với nội
        // dung bên dưới.
        gradientLayer.colors = [
            ILColors.templeHeaderTop.cgColor,
            ILColors.templeHeaderMid.cgColor,
            ILColors.canvas.cgColor
        ]
        gradientLayer.locations = [0.0, 0.58, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)

        // Quầng sáng vàng ở đỉnh hero (`--il-th-glow`).
        glowLayer.type = .radial
        glowLayer.colors = [ILColors.templeHeaderGlow.cgColor, ILColors.goldGlowClear.cgColor]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        glowLayer.cornerRadius = Layout.glowDiameter / 2
        backgroundView.layer.insertSublayer(glowLayer, above: gradientLayer)

        // Không thêm UIView() đệm ở cuối: `contentStack` dùng `alignment = .leading` (không
        // `.fill`) nên `chipsRow` chỉ nhận đúng kích thước intrinsic của nó — một UIView() đệm co
        // giãn (không có intrinsic size) bên trong sẽ khiến UIStackView báo intrinsicContentSize
        // mơ hồ và tự co cả `chipsRow` về 0 width (lỗi UIStackView kinh điển khi lồng stack chứa
        // spacer bên trong 1 stack không `.fill`).
        chipsRow.addArrangedSubview(rankChipLabel)
        chipsRow.addArrangedSubview(sectChipLabel)

        contentStack.addArrangedSubview(chipsRow)
        contentStack.setCustomSpacing(14, after: chipsRow)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(aliasLabel)
        contentStack.addArrangedSubview(placeLabel)

        contentView.addSubview(contentStack)

        // Text starts below the photo (or `topInset` from the top when there is none).
        let contentTop = contentStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: Layout.topInset)
        contentTopConstraint = contentTop

        NSLayoutConstraint.activate([
            contentTop,
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.bottomInset)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTempleHeroView, _) in
            view.applyColorAppearanceChange()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: bounds.midX - Layout.glowDiameter / 2,
            y: Layout.glowTopInset,
            width: Layout.glowDiameter,
            height: Layout.glowDiameter
        )
    }

    // `CAGradientLayer` màu là CGColor tĩnh, không tự đảo theo trait — resolve lại khi hệ thống
    // đổi light/dark (bộ `--il-th-*` có hai biến thể).
    private func applyColorAppearanceChange() {
        gradientLayer.colors = [
            ILColors.templeHeaderTop.resolvedColor(with: traitCollection).cgColor,
            ILColors.templeHeaderMid.resolvedColor(with: traitCollection).cgColor,
            ILColors.canvas.resolvedColor(with: traitCollection).cgColor
        ]
        glowLayer.colors = [
            ILColors.templeHeaderGlow.resolvedColor(with: traitCollection).cgColor,
            ILColors.goldGlowClear.cgColor
        ]
    }
}

/// Chip viền mỏng, nền trong suốt trên hero tối (cấp di tích / hệ phái) — khớp design handoff
/// (`padding:4px 10px`, viền `--il-hero-acc2`, không nền).
private final class ILTempleHeroChipLabel: UILabel {

    init(textColor: UIColor) {
        super.init(frame: .zero)
        self.textColor = textColor
        font = ILTypography.beVietnamPro(size: 10.5, weight: .medium)
        layer.borderWidth = 1
        layer.borderColor = ILColors.gold.withAlphaComponent(0.5).cgColor
        clipsToBounds = true
        textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 20, height: max(size.height + 8, 21))
    }

    // Bo tròn bằng đúng nửa chiều cao thật (không dùng hằng số quá khổ như 999/2): với
    // `clipsToBounds = true`, một `cornerRadius` lớn hơn nhiều lần kích thước view khiến
    // CoreAnimation tính sai mask ở lần layout đầu (bounds còn `.zero`) và ẩn mất toàn bộ nội
    // dung — không tự phục hồi sau khi bounds đã đúng.
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
