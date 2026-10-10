//
//  ILSignUpLegalSheetViewController.swift
//  InnerLamp
//

import UIKit

/// Bottom sheet "Điều khoản & quyền riêng tư" của màn Đăng ký (`lgOpen` trong design handoff):
/// hai tab (Điều khoản / Quyền riêng tư), nội dung cuộn, chân sheet có "Đóng" và "Tôi đồng ý".
///
/// Nội dung là văn bản tĩnh lấy từ localization (`legal.*`), không có UseCase hay luồng điều hướng
/// riêng nên trình bày qua `present(_:)` trực tiếp, cùng cách `ILCountryPickerViewController`.
final class ILSignUpLegalSheetViewController: BaseViewController {

    enum Document: Int, CaseIterable {
        case terms
        case privacy

        var keyPrefix: String { self == .terms ? "legal.terms" : "legal.privacy" }
        var sectionCount: Int { self == .terms ? 6 : 5 }
        var tabTitle: String { (self == .terms ? "legal.tab.terms" : "legal.tab.privacy").localized }
        var title: String { "\(keyPrefix).title".localized }
        var contactText: String { "legal.contact.\(self == .terms ? "terms" : "privacy")".localized }
    }

    /// Gọi khi người dùng bấm "Tôi đồng ý" — sheet đã tự đóng lại.
    var onAgree: (() -> Void)?

    private var document: Document

    private let segmentedView = ILSegmentedToggleView(titles: Document.allCases.map(\.tabTitle))
    private let topDivider = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let effectiveLabel = UILabel()
    private let sectionsStack = UIStackView()
    private let contactLabel = UILabel()
    private let footerDivider = UIView()
    private let closeButton = ILButton(title: "legal.close".localized, variant: .ghost)
    private let agreeButton = ILButton(title: "legal.agree".localized, variant: .primary)

    init(document: Document) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            // `max-height: 84%` của design.
            sheet.detents = [.custom { context in context.maximumDetentValue * 0.84 }]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = ILMetrics.radiusCardLarge
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.surface

        segmentedView.translatesAutoresizingMaskIntoConstraints = false
        segmentedView.selectedIndex = document.rawValue
        segmentedView.onSelect = { [weak self] index in
            guard let self, let selected = Document(rawValue: index) else { return }
            document = selected
            render()
            scrollView.setContentOffset(.zero, animated: false)
        }
        view.addSubview(segmentedView)

        [topDivider, footerDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = ILColors.ink.withAlphaComponent(0.07)
            view.addSubview($0)
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        titleLabel.font = ILTypography.signUpTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.numberOfLines = 0

        effectiveLabel.font = ILTypography.note
        effectiveLabel.textColor = ILColors.inkMuted
        effectiveLabel.text = "legal.effective".localized

        sectionsStack.axis = .vertical
        sectionsStack.spacing = ILMetrics.groupSpacing

        contactLabel.font = ILTypography.note
        contactLabel.textColor = ILColors.inkMuted
        contactLabel.numberOfLines = 0

        contentStack.addArrangedSubview(titleLabel)
        contentStack.setCustomSpacing(6, after: titleLabel)
        contentStack.addArrangedSubview(effectiveLabel)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: effectiveLabel)
        contentStack.addArrangedSubview(sectionsStack)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: sectionsStack)
        contentStack.addArrangedSubview(contactLabel)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.onTap = { [weak self] in self?.dismiss(animated: true) }
        agreeButton.translatesAutoresizingMaskIntoConstraints = false
        agreeButton.onTap = { [weak self] in
            self?.dismiss(animated: true) { self?.onAgree?() }
        }
        view.addSubview(closeButton)
        view.addSubview(agreeButton)

        render()
    }

    override func setupConstraints() {
        super.setupConstraints()
        let side = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            segmentedView.topAnchor.constraint(equalTo: view.topAnchor, constant: ILMetrics.spaceLarge),
            segmentedView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            segmentedView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),

            topDivider.topAnchor.constraint(equalTo: segmentedView.bottomAnchor, constant: ILMetrics.spaceMedium),
            topDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: topDivider.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerDivider.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: ILMetrics.groupSpacing),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: side),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -side),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -side * 2),

            footerDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerDivider.heightAnchor.constraint(equalToConstant: 1),
            footerDivider.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -ILMetrics.spaceMedium),

            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall),
            closeButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),

            agreeButton.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: ILMetrics.rowSpacing),
            agreeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            agreeButton.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor),
            agreeButton.heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),
            // `flex:1` / `flex:2` của design.
            agreeButton.widthAnchor.constraint(equalTo: closeButton.widthAnchor, multiplier: 2.0)
        ])
    }

    // MARK: - Render
    private func render() {
        titleLabel.text = document.title
        contactLabel.text = document.contactText

        sectionsStack.arrangedSubviews.forEach {
            sectionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for index in 1...document.sectionCount {
            sectionsStack.addArrangedSubview(makeSection(
                heading: "\(document.keyPrefix).section\(index).heading".localized,
                body: "\(document.keyPrefix).section\(index).body".localized
            ))
        }
    }

    private func makeSection(heading: String, body: String) -> UIView {
        let headingLabel = UILabel()
        headingLabel.font = ILTypography.beVietnamPro(size: 14, weight: .semibold)
        headingLabel.textColor = ILColors.ink
        headingLabel.numberOfLines = 0
        headingLabel.text = heading

        // Design: 14px / line-height 1.7, ink 0.72.
        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.attributedText = ILTypography.makeAttributedString(
            text: body,
            font: ILTypography.scriptureDescription,
            color: ILColors.ink.withAlphaComponent(0.72),
            lineHeightMultiple: 1.7
        )

        let stack = UIStackView(arrangedSubviews: [headingLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }
}
