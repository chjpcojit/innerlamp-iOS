//
//  ILTempleFinderCells.swift
//  InnerLamp
//

import UIKit

/// Nền thẻ của danh sách: các cell liền nhau tạo thành 1 thẻ bo 20 viền hairline — cell đầu bo 2
/// góc trên, cell cuối bo 2 góc dưới, các cell giữa chồng viền 1pt lên nhau thành đường kẻ.
class ILTempleFinderCardCell: UITableViewCell {

    private lazy var cardView: UIView = {
        let v = UIView()
        v.backgroundColor = ILColors.surface
        v.layer.cornerRadius = ILMetrics.radiusCardRegular
        v.layer.borderWidth = 1
        v.layer.borderColor = ILColors.border.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var topConstraint: NSLayoutConstraint?
    private(set) lazy var contentContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)

        cardView.addSubview(contentContainer)

        let top = cardView.topAnchor.constraint(equalTo: contentView.topAnchor)
        topConstraint = top
        NSLayoutConstraint.activate([
            top,
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentContainer.topAnchor.constraint(equalTo: cardView.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)
        ])

        // `layer.borderColor` là CGColor tĩnh — refresh thủ công khi đổi light/dark.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.cardView.layer.borderColor = ILColors.border.cgColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyPosition(isFirst: Bool, isLast: Bool) {
        var corners: CACornerMask = []
        if isFirst { corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast { corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        cardView.layer.maskedCorners = corners
        // Chồng viền 1pt lên cell phía trên để hai viền thành 1 đường kẻ.
        topConstraint?.constant = isFirst ? 0 : -1
    }
}

/// 1 hàng chùa: tên + địa chỉ, bên phải là nhãn "Chùa của bạn" hoặc nút "Chọn".
final class ILTempleFinderRowCell: ILTempleFinderCardCell {

    static let reuseIdentifier = "ILTempleFinderRowCell"

    var onPick: (() -> Void)?

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.rowTitle
        label.textColor = ILColors.ink
        label.numberOfLines = 2
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 2
        return label
    }()

    private lazy var mineLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textColor = ILColors.link
        label.text = "templeFinder.row.mine".localized
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var pickButton: ILSanghaPillButton = {
        let button = ILSanghaPillButton()
        button.configure(title: "templeFinder.row.pick".localized, style: .off)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        pickButton.addTarget(self, action: #selector(handlePick), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let row = UIStackView(arrangedSubviews: [textStack, mineLabel, pickButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium - 2
        row.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: ILMetrics.spaceMedium - 2),
            row.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -(ILMetrics.spaceMedium - 2)),
            row.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: ILMetrics.spaceMedium),
            row.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -ILMetrics.spaceMedium)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: ILTempleFinderRowModel) {
        nameLabel.text = model.name
        subtitleLabel.text = model.subtitle
        mineLabel.isHidden = !model.isMine
        pickButton.isHidden = model.isMine
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPick = nil
    }

    @objc private func handlePick() {
        onPick?()
    }
}

/// Dòng cuối danh sách: "Không thấy chùa bạn tìm?" + dấu cộng.
final class ILTempleFinderAddCell: ILTempleFinderCardCell {

    static let reuseIdentifier = "ILTempleFinderAddCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let title = UILabel()
        title.font = ILTypography.headerTitle
        title.textColor = ILColors.link
        title.text = "templeFinder.add.title".localized
        let subtitle = UILabel()
        subtitle.font = ILTypography.subhead
        subtitle.textColor = ILColors.inkTertiary
        subtitle.text = "templeFinder.add.subtitle".localized
        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 3

        let plus = UIImageView(image: UIImage(systemName: "plus"))
        plus.tintColor = ILColors.link
        plus.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [textStack, plus])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceMedium - 2
        row.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: ILMetrics.spaceMedium),
            row.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -ILMetrics.spaceMedium),
            row.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: ILMetrics.spaceStandard),
            row.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Dòng báo "không có chùa nào khớp" — nằm trong cùng thẻ, phía trên dòng "thêm chùa".
final class ILTempleFinderEmptyCell: ILTempleFinderCardCell {

    static let reuseIdentifier = "ILTempleFinderEmptyCell"

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentContainer.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: ILMetrics.spaceStandard + 2),
            label.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -(ILMetrics.spaceStandard + 2)),
            label.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: ILMetrics.spaceStandard),
            label.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -ILMetrics.spaceStandard)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String) {
        label.attributedText = ILTypography.makeAttributedString(
            text: text, font: ILTypography.bodyCompact, color: ILColors.inkTertiary, lineHeightMultiple: 1.6
        )
    }
}

/// Banner xanh "Đã gửi đề xuất …" đầu danh sách.
final class ILTempleFinderSentCell: UITableViewCell {

    static let reuseIdentifier = "ILTempleFinderSentCell"

    private lazy var banner: ILInlineBannerView = {
        let v = ILInlineBannerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: contentView.topAnchor),
            banner.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceMedium),
            banner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            banner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ILMetrics.screenHorizontal)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String) {
        banner.message = message
    }
}
