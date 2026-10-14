//
//  ILTemplesRowCell.swift
//  InnerLamp
//

import UIKit

/// 1 thẻ chùa của màn "Tất cả chùa": ảnh thumbnail 84×84 bên trái; tên, tỉnh thành và ghi chú bên
/// phải (khớp thẻ `temples` trong design handoff).
final class ILTemplesRowCell: UITableViewCell {

    static let reuseIdentifier = "ILTemplesRowCell"

    private static let thumbSize: CGFloat = 84
    private static let thumbRadius: CGFloat = 14
    private static let cardPadding: CGFloat = 12

    private lazy var cardView: UIView = {
        let v = UIView()
        v.backgroundColor = ILColors.surface
        v.layer.cornerRadius = ILMetrics.radiusCardRegular
        v.layer.borderWidth = 1
        v.layer.borderColor = ILColors.border.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var thumbView: ILRemoteImageView = {
        let v = ILRemoteImageView(frame: .zero)
        v.backgroundColor = ILColors.tint
        v.layer.cornerRadius = Self.thumbRadius
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodySmall
        label.textColor = ILColors.ink
        label.numberOfLines = 2
        return label
    }()

    private lazy var placeLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 1
        return label
    }()

    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkSubtle
        label.numberOfLines = 2
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(cardView)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        let textStack = UIStackView(arrangedSubviews: [nameLabel, placeLabel, spacer, noteLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.setCustomSpacing(6, after: spacer)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(thumbView)
        cardView.addSubview(textStack)

        let pad = Self.cardPadding
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceSmall / 2 + 1),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(ILMetrics.spaceSmall / 2 + 1)),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            thumbView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad),
            thumbView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: pad),
            thumbView.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -pad),
            thumbView.widthAnchor.constraint(equalToConstant: Self.thumbSize),
            thumbView.heightAnchor.constraint(equalToConstant: Self.thumbSize),

            textStack.leadingAnchor.constraint(equalTo: thumbView.trailingAnchor, constant: ILMetrics.spaceMedium),
            textStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad),
            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: pad),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -pad),
            textStack.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.thumbSize)
        ])

        // `layer.borderColor` là CGColor tĩnh — refresh thủ công khi đổi light/dark.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.cardView.layer.borderColor = ILColors.border.cgColor
        }
    }

    func configure(with model: ILTemplesRowModel) {
        nameLabel.text = model.name
        placeLabel.text = model.place
        noteLabel.text = model.note
        noteLabel.isHidden = model.note.isEmpty
        thumbView.setImage(urlString: model.thumbnailURL)
    }
}
