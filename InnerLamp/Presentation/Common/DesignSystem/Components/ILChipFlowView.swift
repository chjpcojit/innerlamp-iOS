//
//  ILChipFlowView.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Xếp các view con (thường là `ILChip`) trái→phải, tự xuống hàng khi tràn — mirror `flex-wrap`,
/// dùng cho mọi màn cần chọn nhiều item dạng chip với số lượng/label động (onboarding, filter, ...).
public final class ILChipFlowView: UIView {

    private let rowSpacing: CGFloat
    private let itemSpacing: CGFloat

    private var items: [UIView] = []
    private var lastLayoutWidth: CGFloat = 0

    public init(rowSpacing: CGFloat = 10, itemSpacing: CGFloat = 10) {
        self.rowSpacing = rowSpacing
        self.itemSpacing = itemSpacing
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setItems(_ items: [UIView]) {
        self.items.forEach { $0.removeFromSuperview() }
        self.items = items
        items.forEach { addSubview($0) }
        lastLayoutWidth = 0
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutItems(width: bounds.width)
        if bounds.width != lastLayoutWidth {
            lastLayoutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        let width = bounds.width > 0 ? bounds.width : UIView.layoutFittingCompressedSize.width
        let height = layoutItems(width: width, apply: false)
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    @discardableResult
    private func layoutItems(width: CGFloat, apply: Bool = true) -> CGFloat {
        guard width > 0, !items.isEmpty else { return 0 }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for item in items {
            let size = item.systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width, height: UIView.layoutFittingCompressedSize.height)
            )

            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            if apply {
                item.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            }

            x += size.width + itemSpacing
            rowHeight = max(rowHeight, size.height)
        }

        return y + rowHeight
    }
}
