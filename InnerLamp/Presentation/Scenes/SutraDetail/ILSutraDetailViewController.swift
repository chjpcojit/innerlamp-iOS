//
//  ILSutraDetailViewController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import UIKit
import Combine

final class ILSutraDetailViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILSutraDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let downloadTappedSubject = PassthroughSubject<Void, Never>()
    private let chantTappedSubject = PassthroughSubject<Void, Never>()
    private let playTappedSubject = PassthroughSubject<Void, Never>()
    private let chapterTappedSubject = PassthroughSubject<Void, Never>()
    private let linkTappedSubject = PassthroughSubject<URL, Never>()


    // MARK: - UI Elements
    /// Dải header ghim — nền `th-top` liền màu với đỉnh hero, không có đường kẻ; nội dung cuộn
    /// chui xuống dưới và mờ dần qua lớp kính.
    private lazy var headerBand = ILStickyHeaderBand(tintColor: ILColors.templeHeaderTop)
    private lazy var navBar = ILNavBar(showBack: true)

    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        v.alwaysBounceVertical = true
        v.contentInsetAdjustmentBehavior = .never
        return v
    }()
    private lazy var contentView = UIView()

    private lazy var heroView = ILSutraDetailHeroView()

    private lazy var progressCard: UIView = {
        let card = UIView()
        card.backgroundColor = ILColors.surface
        card.layer.cornerRadius = ILMetrics.radiusCardSmall
        card.layer.borderWidth = 1
        card.layer.borderColor = ILColors.border.cgColor
        return card
    }()

    private lazy var progressTitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmallMedium
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        return label
    }()

    private lazy var progressPercentLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        label.numberOfLines = 1
        return label
    }()

    private lazy var progressBar = ILLinearProgressBarView()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var infoView = ILSutraDetailInfoView()

    private lazy var tocTitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.headerTitle
        label.textColor = ILColors.ink
        return label
    }()

    private lazy var tocCountLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkSubtle
        return label
    }()

    private lazy var tocHeaderRow = UIView()

    private lazy var chapterListView = ILSutraDetailChapterListView()

    /// Thân trang dưới hero: thẻ tiến trình → mô tả → các khối thông tin (giới thiệu, thông tin, bản dịch
    /// & giấy phép, lưu ý) → Mục lục.
    private lazy var bodyStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            progressCard, descriptionLabel, infoView, tocHeaderRow, chapterListView
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.setCustomSpacing(18, after: progressCard)
        stack.setCustomSpacing(20, after: descriptionLabel)
        stack.setCustomSpacing(24, after: infoView)
        stack.setCustomSpacing(12, after: tocHeaderRow)
        return stack
    }()

    private lazy var footerBar: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.canvas
        return view
    }()

    private lazy var footerTopDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private lazy var chantButton = ILButton(title: "sutraDetail.chant".localized, variant: .primary)

    private lazy var playButton = ILSutraDetailPlayButton()

    private lazy var footerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [chantButton, playButton])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.rowSpacing
        stack.alignment = .center
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILSutraDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyHeaderInset()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        navBar.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        navBar.onAction = { [weak self] in self?.downloadTappedSubject.send(()) }

        headerBand.bind(to: scrollView)

        chantButton.onTap = { [weak self] in self?.chantTappedSubject.send(()) }
        playButton.onTap = { [weak self] in self?.playTappedSubject.send(()) }
        chapterListView.onChapterTap = { [weak self] in self?.chapterTappedSubject.send(()) }
        infoView.onLinkTap = { [weak self] url in self?.linkTappedSubject.send(url) }

        progressCard.addSubview(progressTitleLabel)
        progressCard.addSubview(progressPercentLabel)
        progressCard.addSubview(progressBar)

        footerBar.addSubview(footerTopDivider)
        footerBar.addSubview(footerStack)

        tocHeaderRow.addSubview(tocTitleLabel)
        tocHeaderRow.addSubview(tocCountLabel)

        headerBand.addSubview(navBar)

        scrollView.addSubview(contentView)
        contentView.addSubview(heroView)
        contentView.addSubview(bodyStack)

        view.addSubview(scrollView)
        view.addSubview(headerBand)
        view.addSubview(footerBar)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            navBar, scrollView, contentView, heroView, bodyStack, progressCard,
            progressTitleLabel, progressPercentLabel, progressBar, tocTitleLabel, tocCountLabel,
            footerBar, footerTopDivider, footerStack, chantButton, playButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            navBar.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            navBar.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),
            navBar.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -10),

            footerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            footerTopDivider.topAnchor.constraint(equalTo: footerBar.topAnchor),
            footerTopDivider.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor),
            footerTopDivider.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor),
            footerTopDivider.heightAnchor.constraint(equalToConstant: 1),

            footerStack.topAnchor.constraint(equalTo: footerBar.topAnchor, constant: ILMetrics.spaceMedium),
            footerStack.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor, constant: horizontal),
            footerStack.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor, constant: -horizontal),
            footerStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceSmall),

            // Scroll view chạy dưới header để nội dung mờ xuyên qua kính; chiều cao header được
            // áp thành top content inset trong `viewDidLayoutSubviews`.
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerBar.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            heroView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bodyStack.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: horizontal),
            bodyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            bodyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),
            bodyStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceStandard),

            progressTitleLabel.topAnchor.constraint(equalTo: progressCard.topAnchor, constant: ILMetrics.spaceStandard),
            progressTitleLabel.leadingAnchor.constraint(equalTo: progressCard.leadingAnchor, constant: 18),
            progressTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: progressPercentLabel.leadingAnchor, constant: -ILMetrics.spaceSmall),

            progressPercentLabel.centerYAnchor.constraint(equalTo: progressTitleLabel.centerYAnchor),
            progressPercentLabel.trailingAnchor.constraint(equalTo: progressCard.trailingAnchor, constant: -18),

            progressBar.topAnchor.constraint(equalTo: progressTitleLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: progressCard.leadingAnchor, constant: 18),
            progressBar.trailingAnchor.constraint(equalTo: progressCard.trailingAnchor, constant: -18),
            progressBar.bottomAnchor.constraint(equalTo: progressCard.bottomAnchor, constant: -ILMetrics.spaceStandard),

            tocTitleLabel.topAnchor.constraint(equalTo: tocHeaderRow.topAnchor),
            tocTitleLabel.leadingAnchor.constraint(equalTo: tocHeaderRow.leadingAnchor),
            tocTitleLabel.bottomAnchor.constraint(equalTo: tocHeaderRow.bottomAnchor),

            tocCountLabel.centerYAnchor.constraint(equalTo: tocTitleLabel.centerYAnchor),
            tocCountLabel.trailingAnchor.constraint(equalTo: tocHeaderRow.trailingAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILSutraDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            downloadTapped: downloadTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            playTapped: playTappedSubject.eraseToAnyPublisher(),
            chapterTapped: chapterTappedSubject.eraseToAnyPublisher(),
            linkTapped: linkTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILSutraDetailStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILSutraDetailStateModel) {
        navBar.rightActionTitle = model.downloadButtonTitle

        heroView.configure(
            kicker: model.kicker,
            title: model.title,
            originalName: model.originalName,
            metaText: model.metaText,
            tags: model.tags
        )

        progressCard.isHidden = !model.hasProgress
        progressTitleLabel.text = model.progressTitle
        progressPercentLabel.text = model.progressPercentText
        progressBar.progress = model.progressValue

        descriptionLabel.isHidden = model.descriptionText.isEmpty
        descriptionLabel.attributedText = ILTypography.makeParagraph(
            text: model.descriptionText,
            font: ILTypography.scriptureDescription,
            color: ILColors.inkSecondary,
            cssLineHeight: 1.75
        )

        infoView.sections = model.infoSections
        infoView.isHidden = model.infoSections.isEmpty

        tocTitleLabel.text = model.tocTitle
        tocCountLabel.text = model.tocCountText
        chapterListView.chapters = model.chapters
        // Most sutras have no table of contents (`sections: []`) — hide the whole block then.
        tocHeaderRow.isHidden = model.chapters.isEmpty
        chapterListView.isHidden = model.chapters.isEmpty

        chantButton.title = model.chantButtonTitle
        playButton.isHidden = !model.hasAudio
    }

    /// Đẩy nội dung xuống dưới header; lần layout đầu thì đặt offset ở đỉnh nội dung thay vì dưới header.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }
}


// MARK: - Round play button (footer)

/// Nút tròn phát (52px theo design handoff) trong thanh CTA đáy — nền `surface`, viền `ink-18`,
/// tam giác phát màu `ink`; khác `ILPlayPauseButton` (nền `ink`, glyph vàng) dùng cho thanh phát.
private final class ILSutraDetailPlayButton: UIControl {

    var onTap: (() -> Void)?

    private let glyphLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.buttonHeight / 2
        layer.borderWidth = 1
        layer.borderColor = ILColors.borderStrong.cgColor

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "sutraDetail.play".localized

        glyphLayer.fillColor = ILColors.ink.cgColor
        layer.addSublayer(glyphLayer)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: ILMetrics.buttonHeight),
            heightAnchor.constraint(equalToConstant: ILMetrics.buttonHeight)
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ILSutraDetailPlayButton, _) in
            view.applyColorAppearanceChange()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glyphLayer.frame = bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let halfWidth: CGFloat = 5.5
        let halfHeight: CGFloat = 7.5
        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x - halfWidth + 1.5, y: center.y - halfHeight))
        path.addLine(to: CGPoint(x: center.x + halfWidth + 1.5, y: center.y))
        path.addLine(to: CGPoint(x: center.x - halfWidth + 1.5, y: center.y + halfHeight))
        path.close()
        glyphLayer.path = path.cgPath
    }

    private func applyColorAppearanceChange() {
        layer.borderColor = ILColors.borderStrong.cgColor
        glyphLayer.fillColor = ILColors.ink.cgColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}
