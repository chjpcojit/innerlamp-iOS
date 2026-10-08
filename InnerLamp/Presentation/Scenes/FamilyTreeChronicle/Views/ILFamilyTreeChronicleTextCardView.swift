//
//  ILFamilyTreeChronicleTextCardView.swift
//  InnerLamp
//

import UIKit

/// A block of written text (origin story, teachings) in the serif italic on a soft card — or, when
/// nothing is written yet, a dashed "Chưa có … Bấm để …" placeholder that is tappable (it opens
/// the edit mode, which is how a first entry is added).
final class ILFamilyTreeChronicleTextCardView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let insets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        static let placeholderInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        static let dashPattern: [NSNumber] = [4, 3]
        static let lineHeightMultiple: CGFloat = 1.5
    }

    // MARK: - Properties
    /// Fires only while the placeholder is shown.
    var onPlaceholderTap: (() -> Void)?

    private let tapControl = ILFamilyTreeChronicleTapControl()
    private let textLabel = UILabel()
    private let dashLayer = CAShapeLayer()
    private var isPlaceholder = false
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = ILMetrics.FamilyTree.sheetCardRadius
        dashLayer.fillColor = nil
        dashLayer.lineDashPattern = Layout.dashPattern
        dashLayer.lineWidth = 1
        layer.addSublayer(dashLayer)

        textLabel.numberOfLines = 0
        textLabel.isUserInteractionEnabled = false
        tapControl.onTap = { [weak self] in
            guard let self, self.isPlaceholder else { return }
            self.onPlaceholderTap?()
        }
        [tapControl, textLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let top = textLabel.topAnchor.constraint(equalTo: topAnchor)
        let bottom = textLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        let leading = textLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = textLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        topConstraint = top
        bottomConstraint = bottom
        leadingConstraint = leading
        trailingConstraint = trailing
        NSLayoutConstraint.activate([
            top, bottom, leading, trailing,
            tapControl.topAnchor.constraint(equalTo: topAnchor),
            tapControl.bottomAnchor.constraint(equalTo: bottomAnchor),
            tapControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapControl.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILFamilyTreeChronicleTextCardView, _) in
            view.applyColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// `text` empty shows `placeholder` as a dashed, tappable card.
    func configure(text: String, placeholder: String) {
        isPlaceholder = text.isEmpty
        tapControl.isEnabled = isPlaceholder
        let insets = isPlaceholder ? Layout.placeholderInsets : Layout.insets
        topConstraint?.constant = insets.top
        bottomConstraint?.constant = -insets.bottom
        leadingConstraint?.constant = insets.left
        trailingConstraint?.constant = -insets.right
        if isPlaceholder {
            textLabel.attributedText = nil
            textLabel.font = ILTypography.bodySmall
            textLabel.textColor = Tree.inkSecondary
            textLabel.text = placeholder
            tapControl.accessibilityLabel = placeholder
        } else {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineHeightMultiple = Layout.lineHeightMultiple
            textLabel.attributedText = NSAttributedString(string: text, attributes: [
                .font: ILTypography.treeNote, .foregroundColor: Tree.ink, .paragraphStyle: paragraph
            ])
            tapControl.accessibilityLabel = nil
        }
        applyColors()
        setNeedsLayout()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        dashLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: ILMetrics.FamilyTree.sheetCardRadius
        ).cgPath
    }

    private func applyColors() {
        backgroundColor = isPlaceholder ? .clear : Tree.cardSurface
        layer.borderWidth = isPlaceholder ? 0 : 1
        layer.borderColor = Tree.cardRing.cgColor
        dashLayer.isHidden = !isPlaceholder
        dashLayer.strokeColor = Tree.border.cgColor
    }
}
