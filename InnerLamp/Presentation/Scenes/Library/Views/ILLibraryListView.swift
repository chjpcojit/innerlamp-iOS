//
//  ILLibraryListView.swift
//  InnerLamp
//

import UIKit

/// Mục danh sách của Thư viện: tiêu đề mục + các hàng nội dung (`ILRow`), hoặc trạng thái
/// rỗng dùng chung khi nhóm đang chọn không có nội dung. Biết `ILLibraryRowModel` nên thuộc
/// riêng màn Thư viện.
final class ILLibraryListView: UIView {

    // MARK: - Properties
    var onItemTapped: ((String) -> Void)?
    var onViewAllTapped: (() -> Void)?

    // MARK: - UI Elements
    private let sectionHeader = ILSectionHeaderView(title: "")
    private let rowsStack = UIStackView()

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
        sectionHeader.translatesAutoresizingMaskIntoConstraints = false
        sectionHeader.onTrailingTap = { [weak self] in self?.onViewAllTapped?() }

        rowsStack.axis = .vertical
        rowsStack.spacing = ILMetrics.rowSpacing
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(sectionHeader)
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            sectionHeader.topAnchor.constraint(equalTo: topAnchor),
            sectionHeader.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionHeader.trailingAnchor.constraint(equalTo: trailingAnchor),

            rowsStack.topAnchor.constraint(equalTo: sectionHeader.bottomAnchor, constant: ILMetrics.spaceMedium - 2),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure
    func configure(with model: ILLibraryStateModel) {
        sectionHeader.title = model.sutrasSectionTitle
        sectionHeader.trailingText = model.sutrasViewAllText

        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard !model.isListEmpty else {
            rowsStack.addArrangedSubview(ILStateView(kind: .empty, title: model.emptyTitle, message: model.emptyMessage))
            return
        }

        for row in model.rows {
            let rowView = ILRow(
                title: row.title,
                subtitle: row.subtitle,
                trailingText: row.durationText,
                tone: Self.mapTone(row.tone),
                glyph: .book
            )
            rowView.onTap = { [weak self] in self?.onItemTapped?(row.id) }
            rowsStack.addArrangedSubview(rowView)
        }
    }

    private static func mapTone(_ tone: ILLibraryTone) -> ILColors.Tone {
        switch tone {
        case .gold: return .gold
        case .green: return .green
        case .rose: return .rose
        case .ink: return .ink
        }
    }
}
