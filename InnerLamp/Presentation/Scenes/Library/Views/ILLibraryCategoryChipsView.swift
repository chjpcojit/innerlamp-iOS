//
//  ILLibraryCategoryChipsView.swift
//  InnerLamp
//

import UIKit

/// Hàng chip lọc nhóm nội dung của Thư viện: dựng lại danh sách `ILChip` mỗi khi model đổi
/// (chỉ 4 chip) và báo nhóm được chọn. Biết `ILLibraryCategory` nên thuộc riêng màn Thư viện.
final class ILLibraryCategoryChipsView: UIView {

    // MARK: - Properties
    var onCategorySelected: ((ILLibraryCategory) -> Void)?

    // MARK: - UI Elements
    private let flowView = ILChipFlowView(rowSpacing: ILMetrics.spaceSmall, itemSpacing: ILMetrics.spaceSmall)

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        flowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(flowView)
        NSLayoutConstraint.activate([
            flowView.topAnchor.constraint(equalTo: topAnchor),
            flowView.bottomAnchor.constraint(equalTo: bottomAnchor),
            flowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            flowView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(chips: [ILLibraryChipModel]) {
        let chipViews = chips.map { model -> ILChip in
            let chip = ILChip(label: model.title, state: model.isSelected ? .selected : .normal)
            chip.onTap = { [weak self] in self?.onCategorySelected?(model.category) }
            return chip
        }
        flowView.setItems(chipViews)
    }
}
