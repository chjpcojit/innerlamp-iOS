//
//  ILLanguageFontSizeCardView.swift
//  InnerLamp
//

import UIKit

/// Sutra font-size card: a live preview sentence plus 4 size chips. Composition specific to the
/// Language screen.
final class ILLanguageFontSizeCardView: UIView {

    // MARK: - Properties
    var onSelect: ((ILScriptureFontSize) -> Void)?

    private var chips: [ILChip] = []
    private var options: [ILLanguageStateModel.FontSizeOption] = []

    // MARK: - UI Elements
    private let previewLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let chipStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .leading
        return stack
    }()

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
        layer.cornerRadius = ILMetrics.radiusCardMedium
        layer.borderWidth = 1
        applyDynamicColors()

        let stack = UIStackView(arrangedSubviews: [previewLabel, chipStack])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLanguageFontSizeCardView, _) in
            view.applyDynamicColors()
        }
    }

    // MARK: - Configure
    func configure(options: [ILLanguageStateModel.FontSizeOption], previewText: String, previewFontIndex: Int) {
        previewLabel.attributedText = makePreview(text: previewText, fontIndex: previewFontIndex)

        // Rebuild the chips only when the option set changes; a selection change just restyles them.
        if options.map(\.fontSize) != self.options.map(\.fontSize) {
            chips.forEach { $0.removeFromSuperview() }
            chips = options.map { option in
                let chip = ILChip(label: option.title)
                chip.onTap = { [weak self] in self?.onSelect?(option.fontSize) }
                chipStack.addArrangedSubview(chip)
                return chip
            }
        }
        self.options = options
        zip(chips, options).forEach { chip, option in
            chip.label = option.title
            chip.chipState = option.isSelected ? .selected : .normal
        }
    }

    private func makePreview(text: String, fontIndex: Int) -> NSAttributedString {
        let fonts = ILTypography.languagePreviewFonts
        let font = fonts[min(max(fontIndex, 0), fonts.count - 1)]
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.5
        return NSAttributedString(
            string: text,
            attributes: [.font: font, .foregroundColor: ILColors.ink, .paragraphStyle: style]
        )
    }

    private func applyDynamicColors() {
        backgroundColor = ILColors.surface
        layer.borderColor = ILColors.border.cgColor
    }
}
