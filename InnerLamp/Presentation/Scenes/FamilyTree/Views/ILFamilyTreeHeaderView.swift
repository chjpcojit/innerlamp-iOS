//
//  ILFamilyTreeHeaderView.swift
//  InnerLamp
//

import UIKit

/// Header of the tree screen: back chevron, red 譜 seal (opens the clan chronicle), serif clan name
/// with the subtitle below (opens the book switcher; a ▾ shows when there is something to switch),
/// a round search button and a round "+" button. No divider underneath.
final class ILFamilyTreeHeaderView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    // MARK: - Properties
    var onBack: (() -> Void)?
    var onSearch: (() -> Void)?
    var onAdd: (() -> Void)?
    var onSeal: (() -> Void)?
    var onTitle: (() -> Void)?

    /// "+" is hidden in the merged view (no single book to add a person to).
    var showsAdd: Bool = true {
        didSet { addButton.isHidden = !showsActions || !showsAdd }
    }

    /// Shows the ▾ next to the clan name.
    var showsSwitcher: Bool = false {
        didSet { chevronView.isHidden = !showsSwitcher }
    }

    var title: String = "" {
        didSet { titleLabel.text = title }
    }

    var subtitle: String = "" {
        didSet { subtitleLabel.text = subtitle }
    }

    /// Search and "+" are hidden while there is no tree.
    var showsActions: Bool = true {
        didSet {
            searchButton.isHidden = !showsActions
            addButton.isHidden = !showsActions || !showsAdd
        }
    }

    /// Search button gets a soft fill while the search field is open.
    var isSearchActive: Bool = false {
        didSet { searchButton.backgroundColor = isSearchActive ? Tree.searchButtonActive : .clear }
    }

    // MARK: - UI Elements
    private lazy var backButton: IconButton = {
        let button = IconButton(kind: .back)
        button.accessibilityIdentifier = "familyTree.header.back"
        button.accessibilityLabel = "familyTree.header.back".localized
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()

    private lazy var sealView = ILFamilyTreeSealView(
        glyph: "familyTree.empty.seal".localized,
        font: ILTypography.treeHeaderSeal,
        size: Metrics.headerSealSize,
        cornerRadius: Metrics.headerSealRadius,
        ringInset: 2,
        rotation: Metrics.headerSealRotation
    )

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.treeHeaderTitle
        label.textColor = Tree.heading
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var chevronView: UIImageView = {
        let view = UIImageView(image: ILIcons.chevronDown)
        view.tintColor = Tree.brown
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Metrics.headerChevronSize),
            view.heightAnchor.constraint(equalToConstant: Metrics.headerChevronSize)
        ])
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = Tree.inkSecondary
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var searchButton: IconButton = {
        let button = IconButton(kind: .search)
        button.accessibilityIdentifier = "familyTree.header.search"
        button.accessibilityLabel = "familyTree.header.search".localized
        button.addTarget(self, action: #selector(handleSearch), for: .touchUpInside)
        return button
    }()

    private lazy var addButton: IconButton = {
        let button = IconButton(kind: .add)
        button.accessibilityIdentifier = "familyTree.header.add"
        button.accessibilityLabel = "familyTree.header.add".localized
        button.addTarget(self, action: #selector(handleAdd), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        sealView.pinSize()
        sealView.isUserInteractionEnabled = true
        sealView.accessibilityIdentifier = "familyTree.header.seal"
        sealView.accessibilityTraits = .button
        sealView.accessibilityLabel = "familyTree.header.seal".localized
        sealView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSeal)))

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, chevronView, UIView()])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = Metrics.headerTitleGap
        let textStack = UIStackView(arrangedSubviews: [titleRow, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.setContentHuggingPriority(UILayoutPriority(200), for: .horizontal)
        textStack.isUserInteractionEnabled = true
        textStack.accessibilityIdentifier = "familyTree.header.title"
        textStack.accessibilityTraits = .button
        textStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTitle)))

        let row = UIStackView(arrangedSubviews: [backButton, sealView, textStack, searchButton, addButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Metrics.headerGap
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.headerLeadingInset),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.headerInset)
        ])
    }

    @objc private func handleBack() { onBack?() }
    @objc private func handleSearch() { onSearch?() }
    @objc private func handleAdd() { onAdd?() }
    @objc private func handleSeal() { onSeal?() }
    @objc private func handleTitle() { onTitle?() }
}

// MARK: - Icon button
private extension ILFamilyTreeHeaderView {

    /// Vector icon button: back chevron (plain), search (round, soft fill when active), "+" (green).
    final class IconButton: UIControl {

        enum Kind {
            case back
            case search
            case add
        }

        private let kind: Kind
        private let glyphLayer = CAShapeLayer()

        init(kind: Kind) {
            self.kind = kind
            super.init(frame: .zero)
            accessibilityTraits = .button
            translatesAutoresizingMaskIntoConstraints = false

            let size = kind == .back ? Metrics.headerBackSize : CGSize(width: Metrics.headerButtonSize, height: Metrics.headerButtonSize)
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: size.width),
                heightAnchor.constraint(equalToConstant: size.height)
            ])

            glyphLayer.fillColor = nil
            glyphLayer.lineCap = .round
            glyphLayer.lineJoin = .round
            layer.addSublayer(glyphLayer)

            switch kind {
            case .back:
                glyphLayer.strokeColor = Tree.ink.cgColor
                glyphLayer.lineWidth = 2
            case .search:
                layer.cornerRadius = Metrics.headerButtonSize / 2
                glyphLayer.strokeColor = Tree.ink.cgColor
                glyphLayer.lineWidth = 1.8
            case .add:
                layer.cornerRadius = Metrics.headerButtonSize / 2
                backgroundColor = Tree.forest
                layer.shadowColor = Tree.addButtonShadow.cgColor
                layer.shadowOpacity = 1
                layer.shadowRadius = 7
                layer.shadowOffset = CGSize(width: 0, height: 6)
                glyphLayer.strokeColor = Tree.cream.cgColor
                glyphLayer.lineWidth = 1.5
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.6 : 1 }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            glyphLayer.frame = bounds
            let mid = CGPoint(x: bounds.midX, y: bounds.midY)
            let path = UIBezierPath()
            switch kind {
            case .back:
                // 24-box path "M15 5 l-7 7 7 7" drawn at 20pt.
                let s: CGFloat = 20 / 24
                let origin = CGPoint(x: mid.x - 12 * s, y: mid.y - 12 * s)
                path.move(to: CGPoint(x: origin.x + 15 * s, y: origin.y + 5 * s))
                path.addLine(to: CGPoint(x: origin.x + 8 * s, y: origin.y + 12 * s))
                path.addLine(to: CGPoint(x: origin.x + 15 * s, y: origin.y + 19 * s))
            case .search:
                // 24-box: circle (11,11) r6.5 and tail 16,16 → 20,20, drawn at 19pt.
                let s: CGFloat = 19 / 24
                let origin = CGPoint(x: mid.x - 12 * s, y: mid.y - 12 * s)
                path.addArc(withCenter: CGPoint(x: origin.x + 11 * s, y: origin.y + 11 * s),
                            radius: 6.5 * s, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                path.move(to: CGPoint(x: origin.x + 16 * s, y: origin.y + 16 * s))
                path.addLine(to: CGPoint(x: origin.x + 20 * s, y: origin.y + 20 * s))
            case .add:
                path.move(to: CGPoint(x: mid.x - 6, y: mid.y))
                path.addLine(to: CGPoint(x: mid.x + 6, y: mid.y))
                path.move(to: CGPoint(x: mid.x, y: mid.y - 6))
                path.addLine(to: CGPoint(x: mid.x, y: mid.y + 6))
            }
            glyphLayer.path = path.cgPath
        }
    }
}
