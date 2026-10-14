//
//  ILLunarDayDetailAlmanacView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Thẻ "Ngày [Cát/Hung]" — khớp khối `al` trong design handoff: vòng tròn đánh giá + tiêu đề
/// "Ngày …" + phụ đề "Trực … · ngày hoàng đạo/hắc đạo", thang 5 bậc (Đại hung → Đại cát), hai
/// danh sách việc nên làm (NÊN) / kiêng cữ (KHÔNG NÊN), và dòng ghi chú bên dưới thẻ.
final class ILLunarDayDetailAlmanacView: UIView {

    // MARK: - UI Elements
    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.surface
        view.layer.cornerRadius = ILMetrics.radiusCardRegular
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var ratingCircle: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 31
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var ratingCircleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodySmall
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.scriptureBodyLarge
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        return label
    }()

    private lazy var subLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.note
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 1
        return label
    }()

    private lazy var scaleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        return stack
    }()

    private lazy var dosBox: UIView = {
        let view = UIView()
        view.layer.cornerRadius = ILMetrics.radiusCardSmall
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var dosHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.eyebrow
        label.text = "lunarDayDetail.almanac.dos".localized
        label.numberOfLines = 1
        return label
    }()

    private lazy var dosList: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()

    private lazy var dontsBox: UIView = {
        let view = UIView()
        view.layer.cornerRadius = ILMetrics.radiusCardSmall
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var dontsHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.eyebrow
        label.text = "lunarDayDetail.almanac.donts".localized
        label.numberOfLines = 1
        return label
    }()

    private lazy var dontsList: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()

    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var rating: ILLunarDayDetailDayRating = .binh

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(_ model: ILLunarDayDetailAlmanacModel) {
        rating = model.rating
        ratingCircleLabel.text = model.ratingLabel
        titleLabel.text = String(format: "lunarDayDetail.almanac.titleFormat".localized, model.ratingLabel)
        subLabel.text = model.ratingSub
        rebuildScale()
        rebuildList(dosList, items: model.dos, kind: .do)
        rebuildList(dontsList, items: model.donts, kind: .dont)
        noteLabel.attributedText = ILTypography.makeParagraph(
            text: "lunarDayDetail.almanac.note".localized,
            font: ILTypography.subhead,
            color: ILColors.inkTertiary,
            cssLineHeight: 1.55
        )
        applyColorAppearanceChange()
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        // Thẻ chính.
        addSubview(cardView)

        // Vòng tròn đánh giá 62pt.
        ratingCircle.addSubview(ratingCircleLabel)
        NSLayoutConstraint.activate([
            ratingCircle.widthAnchor.constraint(equalToConstant: 62),
            ratingCircle.heightAnchor.constraint(equalToConstant: 62),
            ratingCircleLabel.leadingAnchor.constraint(equalTo: ratingCircle.leadingAnchor, constant: 6),
            ratingCircleLabel.trailingAnchor.constraint(equalTo: ratingCircle.trailingAnchor, constant: -6),
            ratingCircleLabel.centerYAnchor.constraint(equalTo: ratingCircle.centerYAnchor)
        ])

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        titleStack.axis = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let headerRow = UIStackView(arrangedSubviews: [ratingCircle, titleStack])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 14

        configureBox(dosBox, header: dosHeaderLabel, list: dosList, kind: .do)
        configureBox(dontsBox, header: dontsHeaderLabel, list: dontsList, kind: .dont)

        let contentStack = UIStackView(arrangedSubviews: [headerRow, scaleStack, dosBox, dontsBox])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)

        addSubview(noteLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            noteLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 10),
            noteLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            noteLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            noteLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLunarDayDetailAlmanacView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// NÊN (xanh) / KHÔNG NÊN (đỏ) — khung nền nhạt + viền, header chữ hoa nhỏ.
    private func configureBox(_ box: UIView, header: UILabel, list: UIStackView, kind: ListKind) {
        let stack = UIStackView(arrangedSubviews: [header, list])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: box.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14)
        ])
    }

    // MARK: - Scale

    private func rebuildScale() {
        scaleStack.arrangedSubviews.forEach {
            scaleStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for level in ILLunarDayDetailDayRating.allCases {
            scaleStack.addArrangedSubview(makeScalePill(level))
        }
    }

    private func makeScalePill(_ level: ILLunarDayDetailDayRating) -> UIView {
        let label = UILabel()
        label.font = ILTypography.captionMedium
        label.textAlignment = .center
        label.text = level.localizedLabel
        label.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.layer.cornerRadius = 8
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(label)
        NSLayoutConstraint.activate([
            pill.heightAnchor.constraint(equalToConstant: 26),
            label.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: pill.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(lessThanOrEqualTo: pill.trailingAnchor, constant: -4)
        ])

        let isActive = level == rating
        pill.backgroundColor = isActive ? ratingColor : ILColors.ink.withAlphaComponent(0.08)
        label.textColor = isActive ? .white : ILColors.inkTertiary
        return pill
    }

    // MARK: - Lists

    private enum ListKind {
        case `do`
        case dont
    }

    private func rebuildList(_ stack: UIStackView, items: [String], kind: ListKind) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in items {
            stack.addArrangedSubview(makeRow(text: item, kind: kind))
        }
    }

    private func makeRow(text: String, kind: ListKind) -> UIView {
        let glyphLabel = UILabel()
        glyphLabel.font = ILTypography.bodySmallMedium
        glyphLabel.text = kind == .do ? "✓" : "✕"
        glyphLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textLabel = UILabel()
        textLabel.font = ILTypography.bodySmall
        textLabel.textColor = ILColors.inkSecondary
        textLabel.text = text
        textLabel.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [glyphLabel, textLabel])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        row.isUserInteractionEnabled = false
        return row
    }

    // MARK: - Colors

    private var ratingColor: UIColor {
        switch rating {
        case .daiCat: return ILColors.gold
        case .cat: return ILColors.auspicious
        case .binh: return ILColors.goldDeep
        case .hung: return ILColors.inauspicious
        case .daiHung: return ILColors.danger
        }
    }

    private func applyColorAppearanceChange() {
        cardView.layer.borderColor = ILColors.border.cgColor
        ratingCircle.backgroundColor = ratingColor

        dosBox.backgroundColor = ILColors.auspicious.withAlphaComponent(0.08)
        dosBox.layer.borderColor = ILColors.auspicious.withAlphaComponent(0.24).cgColor
        dosHeaderLabel.textColor = ILColors.auspicious

        dontsBox.backgroundColor = ILColors.inauspicious.withAlphaComponent(0.08)
        dontsBox.layer.borderColor = ILColors.inauspicious.withAlphaComponent(0.24).cgColor
        dontsHeaderLabel.textColor = ILColors.inauspicious

        for row in dosList.arrangedSubviews {
            tintRow(row, color: ILColors.auspicious)
        }
        for row in dontsList.arrangedSubviews {
            tintRow(row, color: ILColors.inauspicious)
        }
    }

    private func tintRow(_ row: UIView, color: UIColor) {
        guard let rowStack = row as? UIStackView, let glyph = rowStack.arrangedSubviews.first as? UILabel else { return }
        glyph.textColor = color
    }
}
