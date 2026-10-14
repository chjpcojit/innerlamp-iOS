//
//  ILFamilyTreeChronicleHeadPickerView.swift
//  InnerLamp
//

import UIKit

/// "Chọn tộc trưởng mới" bottom sheet over a scrim: a title, the rule of thumb, and the living
/// men who may take the role. The current head carries a red "Hiện tại" tag and cannot be picked.
final class ILFamilyTreeChronicleHeadPickerView: UIView {

    private typealias Tree = ILColors.FamilyTree

    private enum Layout {
        static let maxHeightRatio: CGFloat = 0.78
        static let sheetRadius: CGFloat = 20
        static let grabberSize = CGSize(width: 40, height: 4)
        static let headerInsets = UIEdgeInsets(top: 10, left: 20, bottom: 12, right: 20)
        static let listInsets = UIEdgeInsets(top: 4, left: 20, bottom: 28, right: 20)
        static let titleGap: CGFloat = 12
        static let subtitleGap: CGFloat = 3
        static let rowMinHeight: CGFloat = 56
        static let rowGap: CGFloat = 12
        static let tagPaddingH: CGFloat = 9
        static let tagPaddingV: CGFloat = 3
        static let animationDuration: TimeInterval = 0.25
    }

    // MARK: - Properties
    var onPick: ((String) -> Void)?
    var onDismiss: (() -> Void)?

    private lazy var scrimView: UIControl = {
        let v = UIControl()
        v.backgroundColor = ILColors.scrimSheet
        v.accessibilityLabel = "common.close".localized
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var sheetView: UIView = {
        let v = UIView()
        v.backgroundColor = Tree.paper
        v.layer.cornerRadius = Layout.sheetRadius
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var listStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func setOpen(_ isOpen: Bool, rows: [ILFamilyTreeChronicleCandidateRow]) {
        if isOpen { rebuild(rows: rows) }
        guard isOpen == isHidden else { return }
        if isOpen {
            isHidden = false
            alpha = 0
            UIView.animate(withDuration: Layout.animationDuration) { self.alpha = 1 }
        } else {
            UIView.animate(withDuration: Layout.animationDuration, animations: { self.alpha = 0 }, completion: { _ in
                self.isHidden = true
            })
        }
    }

    private func rebuild(rows: [ILFamilyTreeChronicleCandidateRow]) {
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if rows.isEmpty {
            let empty = UILabel()
            empty.text = "familyTreeChronicle.head.empty".localized
            empty.font = ILTypography.bodySmall
            empty.textColor = Tree.inkSecondary
            empty.numberOfLines = 0
            listStack.addArrangedSubview(empty)
        }
        rows.forEach { listStack.addArrangedSubview(makeRow($0)) }
    }

    // MARK: - Setup
    private func setupViews() {
        scrimView.addTarget(self, action: #selector(handleScrimTap), for: .touchUpInside)

        let grabber = UIView()
        grabber.backgroundColor = Tree.grabber
        grabber.layer.cornerRadius = Layout.grabberSize.height / 2
        let titleLabel = UILabel()
        titleLabel.text = "familyTreeChronicle.head.title".localized
        titleLabel.font = ILTypography.treeMemorialTitle
        titleLabel.textColor = Tree.heading
        titleLabel.numberOfLines = 0
        let subtitleLabel = UILabel()
        subtitleLabel.text = "familyTreeChronicle.head.subtitle".localized
        subtitleLabel.font = ILTypography.subhead
        subtitleLabel.textColor = Tree.inkSecondary
        subtitleLabel.numberOfLines = 0

        let grabberWrap = UIView()
        grabber.translatesAutoresizingMaskIntoConstraints = false
        grabberWrap.addSubview(grabber)
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: grabberWrap.topAnchor),
            grabber.bottomAnchor.constraint(equalTo: grabberWrap.bottomAnchor),
            grabber.centerXAnchor.constraint(equalTo: grabberWrap.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: Layout.grabberSize.width),
            grabber.heightAnchor.constraint(equalToConstant: Layout.grabberSize.height)
        ])

        let header = UIStackView(arrangedSubviews: [grabberWrap, titleLabel, subtitleLabel])
        header.axis = .vertical
        header.setCustomSpacing(Layout.titleGap, after: grabberWrap)
        header.setCustomSpacing(Layout.subtitleGap, after: titleLabel)
        let headerDivider = UIView()
        headerDivider.backgroundColor = Tree.borderSoft

        [scrimView, sheetView].forEach { addSubview($0) }
        [header, headerDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        [header, headerDivider, scrollView].forEach { sheetView.addSubview($0) }
        scrollView.addSubview(listStack)

        // The sheet hugs its content (list height = content height) up to 78% of the screen.
        let contentHeight = scrollView.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
        contentHeight.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scrimView.topAnchor.constraint(equalTo: topAnchor),
            scrimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: trailingAnchor),

            sheetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sheetView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: Layout.maxHeightRatio),

            header.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: Layout.headerInsets.top),
            header.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: Layout.headerInsets.left),
            header.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -Layout.headerInsets.right),
            headerDivider.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Layout.headerInsets.bottom),
            headerDivider.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: headerDivider.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor),
            contentHeight,

            listStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Layout.listInsets.top),
            listStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Layout.listInsets.bottom),
            listStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Layout.listInsets.left),
            listStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Layout.listInsets.right),
            listStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(Layout.listInsets.left + Layout.listInsets.right))
        ])
    }

    private func makeRow(_ row: ILFamilyTreeChronicleCandidateRow) -> UIView {
        let control = ILFamilyTreeChronicleTapControl()
        control.isEnabled = !row.isCurrent
        control.accessibilityLabel = row.name
        control.onTap = { [weak self] in self?.onPick?(row.memberID) }

        let nameLabel = UILabel()
        nameLabel.text = row.name
        nameLabel.font = ILTypography.treeRelationName
        nameLabel.textColor = Tree.heading
        let subtitleLabel = UILabel()
        subtitleLabel.text = row.subtitle
        subtitleLabel.font = ILTypography.caption
        subtitleLabel.textColor = Tree.inkTertiary
        subtitleLabel.numberOfLines = 0
        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical

        let content = UIStackView(arrangedSubviews: [textStack])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = Layout.rowGap
        content.isUserInteractionEnabled = false
        if row.isCurrent { content.addArrangedSubview(makeCurrentTag()) }

        let divider = UIView()
        divider.backgroundColor = Tree.divider
        [content, divider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            control.addSubview($0)
        }
        NSLayoutConstraint.activate([
            control.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.rowMinHeight),
            content.topAnchor.constraint(equalTo: control.topAnchor, constant: ILMetrics.spaceSmall),
            content.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -ILMetrics.spaceSmall),
            content.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            divider.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        return control
    }

    private func makeCurrentTag() -> UIView {
        let tag = UIView()
        tag.backgroundColor = Tree.seal
        tag.layer.cornerRadius = ILMetrics.radiusPill
        let label = UILabel()
        label.text = "familyTreeChronicle.head.current".localized
        label.font = ILTypography.subheadMedium
        label.textColor = Tree.cream
        label.translatesAutoresizingMaskIntoConstraints = false
        tag.addSubview(label)
        tag.setContentHuggingPriority(.required, for: .horizontal)
        tag.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: tag.topAnchor, constant: Layout.tagPaddingV),
            label.bottomAnchor.constraint(equalTo: tag.bottomAnchor, constant: -Layout.tagPaddingV),
            label.leadingAnchor.constraint(equalTo: tag.leadingAnchor, constant: Layout.tagPaddingH),
            label.trailingAnchor.constraint(equalTo: tag.trailingAnchor, constant: -Layout.tagPaddingH)
        ])
        return tag
    }

    @objc private func handleScrimTap() { onDismiss?() }
}
