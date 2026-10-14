//
//  ILMeditationHubTabSelectorView.swift
//  InnerLamp
//

import UIKit

/// Segmented control 2 tab ("Thiền chuông" / "Thiền dẫn") nằm trong dải header dán của màn Thiền
/// định: track nền `sunk2` bo 14, mỗi tab cao 38 bo 10; tab đang chọn nền `surface` + bóng nhẹ, chữ
/// `ink`; tab còn lại chữ mờ. Feature-scoped vì đây là bố cục riêng của màn này (không phải `ILChip`
/// dạng pill, cũng không phải segmented trên nền immersive).
final class ILMeditationHubTabSelectorView: UIView {

    // MARK: - Constants
    private enum Layout {
        static let trackHeight: CGFloat = 46
        static let trackPadding: CGFloat = 4
        static let trackRadius: CGFloat = 14
        static let itemRadius: CGFloat = 10
        static let itemSpacing: CGFloat = 4
    }

    // MARK: - Properties
    var onSelect: ((ILMeditationHubTabKind) -> Void)?

    // MARK: - UI Elements
    private lazy var itemsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = Layout.itemSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private var items: [TabItem] = []

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(tabs: [ILMeditationHubTabModel]) {
        guard tabs.count == items.count else {
            rebuild(tabs: tabs)
            return
        }
        for (index, tab) in tabs.enumerated() {
            items[index].title = tab.title
            items[index].isSelected = tab.isSelected
        }
    }

    // MARK: - Setup
    private func setupViews() {
        layer.cornerRadius = Layout.trackRadius
        addSubview(itemsStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.trackHeight),
            itemsStack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.trackPadding),
            itemsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.trackPadding),
            itemsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.trackPadding),
            itemsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.trackPadding)
        ])

        updateAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMeditationHubTabSelectorView, _) in
            view.updateAppearance()
        }
    }

    private func rebuild(tabs: [ILMeditationHubTabModel]) {
        items.forEach {
            itemsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        items = tabs.enumerated().map { index, tab in
            let item = TabItem()
            item.title = tab.title
            item.isSelected = tab.isSelected
            item.onTap = { [weak self] in
                guard let self else { return }
                self.onSelect?(tabs[index].kind)
            }
            return item
        }
        items.forEach { itemsStack.addArrangedSubview($0) }
    }

    private func updateAppearance() {
        backgroundColor = ILColors.sunk2
    }

    // MARK: - Tab Item
    private final class TabItem: UIControl {

        var title: String = "" {
            didSet { titleLabel.text = title }
        }

        override var isSelected: Bool {
            didSet { updateAppearance() }
        }

        var onTap: (() -> Void)?

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = ILTypography.sectionTitle
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViews() {
            isAccessibilityElement = true
            accessibilityTraits = .button

            layer.cornerRadius = Layout.itemRadius

            addSubview(titleLabel)

            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])

            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            updateAppearance()
        }

        private func updateAppearance() {
            backgroundColor = isSelected ? ILColors.surface : .clear
            titleLabel.textColor = isSelected ? ILColors.ink : ILColors.inkTertiary
            accessibilityTraits = isSelected ? [.button, .selected] : .button

            if isSelected {
                ILMetrics.shadowSegmentSelected.apply(to: layer)
            } else {
                layer.shadowOpacity = 0
            }
        }

        @objc private func handleTap() {
            onTap?()
        }
    }
}
