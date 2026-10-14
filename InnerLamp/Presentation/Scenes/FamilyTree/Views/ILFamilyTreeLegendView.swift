//
//  ILFamilyTreeLegendView.swift
//  InnerLamp
//

import UIKit

/// Wrapping key to the tree's symbols: founder, "BẠN" (only when the viewer is in the tree), clan
/// head, living, spouse link, branch end.
final class ILFamilyTreeLegendView: UIView {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    private enum Symbol {
        case gradientHexagon([UIColor])
        case hexagon(UIColor)
        case square(UIColor)
        case dashedLine(UIColor)
        case solidLine(UIColor)
        case mePill
    }

    // MARK: - Properties
    private lazy var flow: ILChipFlowView = {
        let view = ILChipFlowView(rowSpacing: Metrics.legendGap, itemSpacing: Metrics.legendGap)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Shows or hides the "BẠN — Vị trí của bạn" item.
    var showsMe = false {
        didSet {
            guard showsMe != oldValue else { return }
            rebuildItems()
        }
    }

    /// The merged "Nội – ngoại" view only needs "BẠN" and "Còn sống": it has no founder, clan head,
    /// spouse links or branch ends.
    var isMerged = false {
        didSet {
            guard isMerged != oldValue else { return }
            rebuildItems()
        }
    }

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        rebuildItems()
        addSubview(flow)
        NSLayoutConstraint.activate([
            flow.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.legendTopSpacing),
            flow.bottomAnchor.constraint(equalTo: bottomAnchor),
            flow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.legendInset),
            flow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.legendInset)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Items
    private func rebuildItems() {
        if isMerged {
            var merged: [(Symbol, String)] = []
            if showsMe { merged.append((.mePill, "familyTree.legend.me".localized)) }
            merged.append((.hexagon(Tree.forest), "familyTree.legend.living".localized))
            flow.setItems(merged.map { makeItem(symbol: $0.0, title: $0.1) })
            return
        }
        var items: [(Symbol, String)] = [(.gradientHexagon(Tree.legendFounderStops), "familyTree.legend.founder".localized)]
        if showsMe { items.append((.mePill, "familyTree.legend.me".localized)) }
        items += [
            (.square(Tree.seal), "familyTree.legend.head".localized),
            (.hexagon(Tree.forest), "familyTree.legend.living".localized),
            (.dashedLine(Tree.brown), "familyTree.legend.spouse".localized),
            (.solidLine(Tree.brown), "familyTree.legend.ended".localized)
        ]
        flow.setItems(items.map { makeItem(symbol: $0.0, title: $0.1) })
    }

    private func makeItem(symbol: Symbol, title: String) -> UIView {
        let icon: UIView
        if case .mePill = symbol {
            icon = makeMeBadge()
        } else {
            icon = SymbolView(symbol: symbol)
        }
        let label = UILabel()
        label.font = ILTypography.caption
        label.textColor = Tree.inkSecondary
        label.text = title
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        return stack
    }

    /// Small gold "BẠN" badge, as on the node.
    private func makeMeBadge() -> UIView {
        let badge = PaddedLabel(horizontalPadding: Metrics.legendMePillPaddingH)
        badge.attributedText = NSAttributedString(
            string: "familyTree.me.pill".localized,
            attributes: [.font: ILTypography.treeMeLegend, .foregroundColor: Tree.inkOnMe, .kern: 0.56]
        )
        badge.backgroundColor = Tree.me
        badge.textAlignment = .center
        badge.layer.cornerRadius = Metrics.legendMePillHeight / 2
        badge.layer.masksToBounds = true
        badge.heightAnchor.constraint(equalToConstant: Metrics.legendMePillHeight).isActive = true
        return badge
    }

    private final class PaddedLabel: UILabel {
        private let horizontalPadding: CGFloat

        init(horizontalPadding: CGFloat) {
            self.horizontalPadding = horizontalPadding
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.insetBy(dx: horizontalPadding, dy: 0))
        }

        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width + horizontalPadding * 2, height: size.height)
        }
    }

    private final class SymbolView: UIView {
        private let symbol: Symbol

        init(symbol: Symbol) {
            self.symbol = symbol
            super.init(frame: .zero)
            backgroundColor = .clear
            translatesAutoresizingMaskIntoConstraints = false
            var size = CGSize(width: 10, height: 11)
            switch symbol {
            case .dashedLine: size = CGSize(width: 14, height: 11)
            case .solidLine: size = CGSize(width: 10, height: 11)
            default: break
            }
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            switch symbol {
            case .gradientHexagon(let colors):
                guard let context = UIGraphicsGetCurrentContext(),
                      let gradient = CGGradient(
                        colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: colors.map { $0.cgColor } as CFArray, locations: nil
                      ) else { return }
                context.saveGState()
                ILFamilyTreeMedallionView.hexagon(in: bounds).addClip()
                context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: bounds.maxX, y: bounds.maxY), options: [])
                context.restoreGState()
            case .hexagon(let color):
                color.setFill()
                ILFamilyTreeMedallionView.hexagon(in: bounds).fill()
            case .square(let color):
                color.setFill()
                UIBezierPath(roundedRect: bounds.insetBy(dx: 0, dy: 0.5), cornerRadius: 2).fill()
            case .solidLine(let color):
                color.setFill()
                UIBezierPath(rect: CGRect(x: 0, y: (bounds.height - 1.5) / 2, width: bounds.width, height: 1.5)).fill()
            case .mePill:
                break
            case .dashedLine(let color):
                color.setStroke()
                let line = UIBezierPath()
                line.move(to: CGPoint(x: 0, y: bounds.midY))
                line.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
                line.lineWidth = 1.5
                line.setLineDash([3, 2], count: 2, phase: 0)
                line.stroke()
            }
        }
    }
}
