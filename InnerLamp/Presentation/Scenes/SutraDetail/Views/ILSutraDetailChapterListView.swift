//
//  ILSutraDetailChapterListView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit

/// Danh sách "Mục lục" (các phẩm) của màn Chi tiết bài kinh — thẻ bo góc 20, mỗi hàng: số La Mã +
/// tên phẩm + dòng phụ ("Kệ 1 – 20 · đang tụng") + thời lượng, ngăn cách bằng hairline. Phẩm đang
/// tụng được tô nền vàng nhạt và số La Mã màu nhấn (khớp `chapters` trong design handoff).
final class ILSutraDetailChapterListView: UIView {

    // MARK: - Properties
    var chapters: [ILSutraDetailChapterModel] = [] {
        didSet { rebuildRows() }
    }

    var onChapterTap: (() -> Void)?

    // MARK: - UI Elements
    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSutraDetailChapterListView, _) in
            view.applyColorAppearanceChange()
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }

    private func rebuildRows() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (index, chapter) in chapters.enumerated() {
            let row = ILSutraDetailChapterRowView(
                chapter: chapter,
                isLast: index == chapters.count - 1
            )
            row.onTap = { [weak self] in self?.onChapterTap?() }
            rowsStack.addArrangedSubview(row)
        }
    }
}

/// 1 hàng phẩm trong `ILSutraDetailChapterListView`.
private final class ILSutraDetailChapterRowView: UIControl {

    var onTap: (() -> Void)?

    private let chapter: ILSutraDetailChapterModel
    private let isLast: Bool

    init(chapter: ILSutraDetailChapterModel, isLast: Bool) {
        self.chapter = chapter
        self.isLast = isLast
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = chapter.isCurrent ? ILColors.gold.withAlphaComponent(0.08) : .clear

        let numberLabel = UILabel()
        numberLabel.font = ILTypography.subheadMedium
        numberLabel.textColor = chapter.isCurrent ? ILColors.link : ILColors.inkSubtle
        numberLabel.text = chapter.number
        numberLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.sectionTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.text = chapter.title
        titleLabel.numberOfLines = 1

        let subtitleLabel = UILabel()
        subtitleLabel.font = ILTypography.caption
        subtitleLabel.textColor = ILColors.inkSubtle
        subtitleLabel.text = chapter.subtitle
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let durationLabel = UILabel()
        durationLabel.font = ILTypography.label
        durationLabel.textColor = ILColors.inkMuted
        durationLabel.text = chapter.durationText
        durationLabel.setContentHuggingPriority(.required, for: .horizontal)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        let hairline = UIView()
        hairline.backgroundColor = ILColors.border
        hairline.isHidden = isLast
        hairline.translatesAutoresizingMaskIntoConstraints = false

        addSubview(numberLabel)
        addSubview(textStack)
        addSubview(durationLabel)
        addSubview(hairline)

        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            numberLabel.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 26),

            textStack.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            textStack.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: ILMetrics.spaceMedium),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: durationLabel.leadingAnchor, constant: -ILMetrics.spaceSmall),
            textStack.bottomAnchor.constraint(equalTo: hairline.topAnchor, constant: -ILMetrics.spaceMedium),

            durationLabel.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            hairline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.99, y: 0.99)
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
