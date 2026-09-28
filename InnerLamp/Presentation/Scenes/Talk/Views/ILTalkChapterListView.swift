//
//  ILTalkChapterListView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit

/// Danh sách "Các phần" của màn Pháp thoại — thẻ bo góc 20, mỗi hàng: mốc thời gian + tiêu đề
/// phần, ngăn cách bằng hairline. Mốc đang nghe (hiện là mốc đầu) được tô nền vàng nhạt và chữ
/// màu nhấn (khớp `talk` trong design handoff). Chỉ hiển thị, không chạm để tua.
final class ILTalkChapterListView: UIView {

    // MARK: - Properties
    var chapters: [ILTalkChapterModel] = [] {
        didSet { rebuildRows() }
    }

    // MARK: - UI Elements
    private let rowsStack = UIStackView()

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
        layer.cornerRadius = ILMetrics.radiusCardRegular
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor
        clipsToBounds = true

        rowsStack.axis = .vertical
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILTalkChapterListView, _) in
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
            rowsStack.addArrangedSubview(
                ILTalkChapterRowView(chapter: chapter, isLast: index == chapters.count - 1)
            )
        }
    }
}

/// 1 mốc trong `ILTalkChapterListView`.
private final class ILTalkChapterRowView: UIView {

    private let chapter: ILTalkChapterModel
    private let isLast: Bool

    init(chapter: ILTalkChapterModel, isLast: Bool) {
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

        let timestampLabel = UILabel()
        timestampLabel.font = chapter.isCurrent ? ILTypography.subheadMedium : ILTypography.subhead
        timestampLabel.textColor = chapter.isCurrent ? ILColors.link : ILColors.inkSubtle
        timestampLabel.text = chapter.timestampText
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.font = chapter.isCurrent ? ILTypography.sectionTitle : ILTypography.bodyCompact
        titleLabel.textColor = ILColors.ink
        titleLabel.text = chapter.title
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let hairline = UIView()
        hairline.backgroundColor = ILColors.border
        hairline.isHidden = isLast
        hairline.translatesAutoresizingMaskIntoConstraints = false

        addSubview(timestampLabel)
        addSubview(titleLabel)
        addSubview(hairline)

        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            timestampLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            timestampLabel.widthAnchor.constraint(equalToConstant: 42),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: timestampLabel.trailingAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: hairline.topAnchor, constant: -ILMetrics.spaceMedium),

            hairline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
