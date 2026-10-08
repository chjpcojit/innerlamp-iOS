//
//  ILMenuFieldView.swift
//  InnerLamp
//

import UIKit

/// Labelled pull-down field (design handoff date selects): a small caption above a card showing
/// the current choice and a chevron; tapping opens a system menu of `options`. Generic over plain
/// ids and titles — the owner supplies the options and handles `onSelect`.
public final class ILMenuFieldView: UIView {

    public struct Option: Equatable {
        public let id: Int
        public let title: String

        public init(id: Int, title: String) {
            self.id = id
            self.title = title
        }
    }

    // MARK: - Properties
    public var options: [Option] = [] {
        didSet { if options != oldValue { updateMenu() } }
    }

    public var selectedID: Int = 0 {
        didSet { if selectedID != oldValue { updateMenu() } }
    }

    public var onSelect: ((Int) -> Void)?

    // MARK: - UI Elements
    private let captionLabel = UILabel()
    private let button = UIButton(type: .system)

    // MARK: - Initializer
    public init(caption: String) {
        super.init(frame: .zero)
        captionLabel.text = caption
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        captionLabel.font = ILTypography.label
        captionLabel.textColor = ILColors.inkSubtle

        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = ILColors.ink
        configuration.image = ILIcons.chevronDown
        configuration.imagePlacement = .trailing
        configuration.imagePadding = ILMetrics.spaceSmall
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12)
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.backgroundColor = ILColors.surface
        button.layer.cornerRadius = ILMetrics.radiusInput
        button.layer.borderWidth = 1
        button.layer.borderColor = ILColors.border.cgColor
        button.showsMenuAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [captionLabel, button])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILMenuFieldView, _) in
            view.button.layer.borderColor = ILColors.border.cgColor
        }
        updateMenu()
    }

    private func updateMenu() {
        var configuration = button.configuration ?? .plain()
        var title = AttributedString(options.first { $0.id == selectedID }?.title ?? "")
        title.font = ILTypography.bodyLarge
        configuration.attributedTitle = title
        button.configuration = configuration

        button.menu = UIMenu(children: options.map { option in
            UIAction(title: option.title, state: option.id == selectedID ? .on : .off) { [weak self] _ in
                self?.onSelect?(option.id)
            }
        })
    }
}
