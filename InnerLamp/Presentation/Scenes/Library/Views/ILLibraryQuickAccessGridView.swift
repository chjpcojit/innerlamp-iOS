//
//  ILLibraryQuickAccessGridView.swift
//  InnerLamp
//

import UIKit

/// Lưới 2 cột x 2 hàng ở đầu màn Thư viện (Kinh sách / Thiền định / Pháp thoại / Phật & Bồ Tát)
/// — mỗi ô mở 1 màn danh sách/hub riêng. Khớp `libTiles` trong design handoff (`isLib`,
/// `grid-template-columns:repeat(2,1fr)`). Biết `ILLibraryQuickAccessModel` nên thuộc riêng màn
/// Thư viện, không phải component dùng chung.
final class ILLibraryQuickAccessGridView: UIView {

    // MARK: - Properties
    var onTileTapped: ((ILLibraryQuickAccessKind) -> Void)?

    // MARK: - UI Elements
    private lazy var columnsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.rowSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
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
        addSubview(columnsStack)

        NSLayoutConstraint.activate([
            columnsStack.topAnchor.constraint(equalTo: topAnchor),
            columnsStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            columnsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            columnsStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - Configure
    func configure(tiles: [ILLibraryQuickAccessModel]) {
        columnsStack.arrangedSubviews.forEach {
            columnsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for rowTiles in stride(from: 0, to: tiles.count, by: 2).map({ Array(tiles[$0..<min($0 + 2, tiles.count)]) }) {
            let row = UIStackView(arrangedSubviews: rowTiles.map(makeTile))
            row.axis = .horizontal
            row.spacing = ILMetrics.rowSpacing
            row.distribution = .fillEqually
            row.alignment = .fill
            columnsStack.addArrangedSubview(row)
        }
    }

    private func makeTile(_ model: ILLibraryQuickAccessModel) -> UIView {
        let tile = ILLibraryQuickAccessTileView(model: model)
        tile.onTap = { [weak self] in self?.onTileTapped?(model.kind) }
        return tile
    }
}

/// 1 ô của `ILLibraryQuickAccessGridView`: glyph Hán tự trong vòng tròn tông màu + nhãn + phụ đề.
private final class ILLibraryQuickAccessTileView: UIControl {

    var onTap: (() -> Void)?

    private let model: ILLibraryQuickAccessModel
    private lazy var glyphTile: UIView = {
        let view = UIView()
        view.backgroundColor = Self.mapTone(model.tone).tintBackground
        view.layer.cornerRadius = Self.glyphTileSize / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(model: ILLibraryQuickAccessModel) {
        self.model = model
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusCardSmall
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let tone = Self.mapTone(model.tone)

        let glyphLabel = UILabel()
        glyphLabel.font = ILTypography.directionGlyph
        glyphLabel.textColor = tone.accentColor
        glyphLabel.text = model.glyph
        glyphLabel.textAlignment = .center
        glyphLabel.translatesAutoresizingMaskIntoConstraints = false
        glyphTile.addSubview(glyphLabel)

        let titleLabel = UILabel()
        titleLabel.font = ILTypography.quickAccessTileTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.text = model.label

        let subtitleLabel = UILabel()
        subtitleLabel.font = ILTypography.label
        subtitleLabel.textColor = ILColors.inkSubtle
        subtitleLabel.text = model.subtitle
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(glyphTile)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            glyphTile.topAnchor.constraint(equalTo: topAnchor, constant: ILMetrics.spaceMedium),
            glyphTile.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            glyphTile.widthAnchor.constraint(equalToConstant: Self.glyphTileSize),
            glyphTile.heightAnchor.constraint(equalToConstant: Self.glyphTileSize),

            glyphLabel.centerXAnchor.constraint(equalTo: glyphTile.centerXAnchor),
            glyphLabel.centerYAnchor.constraint(equalTo: glyphTile.centerYAnchor),

            textStack.topAnchor.constraint(equalTo: glyphTile.bottomAnchor, constant: ILMetrics.spaceMedium - 4),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ILMetrics.spaceStandard),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -ILMetrics.spaceStandard),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ILMetrics.spaceMedium)
        ])

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addTarget(self, action: #selector(handleTapAction), for: .touchUpInside)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILLibraryQuickAccessTileView, _) in
            view.applyColorAppearanceChange()
        }
    }

    /// 30x30 — khớp `libTiles` trong design handoff (`width:30px;height:30px;border-radius:50%`).
    private static let glyphTileSize: CGFloat = 30

    private static func mapTone(_ tone: ILLibraryTone) -> ILColors.Tone {
        switch tone {
        case .gold: return .gold
        case .green: return .green
        case .rose: return .rose
        case .ink: return .ink
        }
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.border.cgColor
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }

    @objc private func handleTouchUp() {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }

    @objc private func handleTapAction() {
        onTap?()
    }
}
