//
//  ILStrengthMeterView.swift
//  InnerLamp
//

import UIKit

/// Thanh đo N mức (vd. độ mạnh mật khẩu) + nhãn text — chỉ phụ thuộc số lượng segment,
/// số segment đã fill, màu và nhãn, không có nội dung riêng của feature nào nên đặt ở
/// Design System, không phải `Scenes/<Feature>/Views/`.
public final class ILStrengthMeterView: UIView {

    // MARK: - Properties
    public let numberOfSegments: Int

    /// Số segment tô màu (0...numberOfSegments).
    public var filledSegments: Int = 0 {
        didSet { updateBars() }
    }

    public var activeColor: UIColor = ILColors.gold {
        didSet { updateBars() }
    }

    public var label: String = "" {
        didSet {
            labelView.text = label
            labelView.isHidden = label.isEmpty
        }
    }

    // MARK: - UI Elements
    private let barsStack = UIStackView()
    private let labelView = UILabel()
    private var barViews: [UIView] = []

    // MARK: - Initializer
    public init(numberOfSegments: Int = 3) {
        self.numberOfSegments = max(numberOfSegments, 1)
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        barsStack.axis = .horizontal
        barsStack.spacing = 6
        barsStack.alignment = .fill
        barsStack.distribution = .fillEqually
        barsStack.translatesAutoresizingMaskIntoConstraints = false

        barViews = (0..<numberOfSegments).map { _ in
            let bar = UIView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.layer.cornerRadius = 1.5
            bar.heightAnchor.constraint(equalToConstant: 3).isActive = true
            barsStack.addArrangedSubview(bar)
            return bar
        }

        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.font = ILTypography.label
        labelView.isHidden = label.isEmpty
        labelView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(barsStack)
        addSubview(labelView)

        NSLayoutConstraint.activate([
            barsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            barsStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            labelView.leadingAnchor.constraint(equalTo: barsStack.trailingAnchor, constant: 6),
            labelView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelView.topAnchor.constraint(equalTo: topAnchor),
            labelView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updateBars()
    }

    private func updateBars() {
        for (index, bar) in barViews.enumerated() {
            bar.backgroundColor = index < filledSegments ? activeColor : ILColors.border
        }
        labelView.textColor = activeColor
    }
}
