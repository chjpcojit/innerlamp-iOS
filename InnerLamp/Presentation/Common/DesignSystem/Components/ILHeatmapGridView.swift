//
//  ILHeatmapGridView.swift
//  InnerLamp
//

import UIKit

/// Lưới ô vuông kiểu heatmap: mỗi ô là 1 mức đậm (alpha 0...1) của màu vàng nhấn, điền theo hàng
/// từ trái sang phải. Chỉ nhận danh sách alpha nên dùng chung được cho mọi màn cần biểu đồ mật độ
/// theo ngày.
public final class ILHeatmapGridView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let cellSpacing: CGFloat = 4
        static let cellCornerRadius: CGFloat = 3
    }

    // MARK: - Properties
    public let columns: Int

    // MARK: - UI Elements
    private lazy var rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = Layout.cellSpacing
        return stack
    }()

    // MARK: - Initializer
    public init(columns: Int = 21) {
        self.columns = max(columns, 1)
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - Configure
    /// `intensities[i]` là alpha (0...1) của ô thứ i; hàng cuối thiếu ô được chèn ô trống để cột
    /// luôn thẳng hàng.
    public func configure(intensities: [CGFloat]) {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for rowStart in stride(from: 0, to: intensities.count, by: columns) {
            let rowSlice = intensities[rowStart..<min(rowStart + columns, intensities.count)]
            var cells = rowSlice.map(makeCell(alpha:))
            while cells.count < columns { cells.append(UIView()) }

            let row = UIStackView(arrangedSubviews: cells)
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = Layout.cellSpacing
            // Ô đầu hàng vuông → chiều cao hàng = chiều rộng ô, các ô còn lại bằng nhau nên cũng vuông.
            cells[0].heightAnchor.constraint(equalTo: cells[0].widthAnchor).isActive = true
            rowsStack.addArrangedSubview(row)
        }
    }

    private func makeCell(alpha: CGFloat) -> UIView {
        let cell = UIView()
        cell.backgroundColor = ILColors.gold.withAlphaComponent(min(max(alpha, 0), 1))
        cell.layer.cornerRadius = Layout.cellCornerRadius
        return cell
    }
}
