//
//  ILArticleViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILArticleViewController: BaseViewController {

    // MARK: - Layout
    /// Đường kính avatar tác giả (32pt theo design handoff).
    private static let authorAvatarSize: CGFloat = 32

    // MARK: - Properties
    private let viewModel: ILArticleViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let saveTappedSubject = PassthroughSubject<Void, Never>()
    private let shareTappedSubject = PassthroughSubject<Void, Never>()
    private let nextArticleTappedSubject = PassthroughSubject<String, Never>()
    private let sourceTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: ILStickyHeaderBand = {
        let band = ILStickyHeaderBand()
        return band
    }()

    private lazy var headerView: ILNavBar = {
        let navBar = ILNavBar(showBack: true)
        return navBar
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var skeletonView: ILSkeletonLoadingView = {
        let view = ILSkeletonLoadingView()
        return view
    }()

    private lazy var heroImageView: ILArticleHeroImageView = {
        let view = ILArticleHeroImageView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var authorAvatar: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.gold.withAlphaComponent(0.18)
        view.layer.cornerRadius = Self.authorAvatarSize / 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var authorInitialsLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subheadMedium
        label.textColor = ILColors.link
        label.textAlignment = .center
        return label
    }()

    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.bodySmallMedium
        label.textColor = ILColors.ink
        label.numberOfLines = 1
        return label
    }()

    private lazy var dateReadLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkSubtle
        label.numberOfLines = 1
        return label
    }()

    private lazy var authorStack: UIStackView = {
        let nameStack = UIStackView(arrangedSubviews: [authorLabel, dateReadLabel])
        nameStack.axis = .vertical
        nameStack.spacing = 1
        nameStack.alignment = .leading

        let stack = UIStackView(arrangedSubviews: [authorAvatar, nameStack])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.rowSpacing
        stack.alignment = .center
        return stack
    }()

    private lazy var metaDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private lazy var bodyStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    private lazy var quoteView: ILArticleQuoteView = {
        let view = ILArticleQuoteView()
        return view
    }()

    /// "Nguồn: Báo Giác Ngộ" — the article is a summary of a press original; tapping opens
    /// `source_url` when the server provided a valid link.
    private lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkTertiary
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var saveButton: ILButton = {
        let button = ILButton(title: "article.save".localized, variant: .ghost)
        return button
    }()

    private lazy var shareButton: ILButton = {
        let button = ILButton(title: "article.share".localized, variant: .primary)
        return button
    }()

    private lazy var actionsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [saveButton, shareButton])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.rowSpacing
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var readMoreHeader: ILSectionHeaderView = {
        let header = ILSectionHeaderView(title: "article.readMore".localized)
        return header
    }()

    private lazy var nextArticlesList: ILArticleNextArticleListView = {
        let list = ILArticleNextArticleListView()
        return list
    }()

    // MARK: - Initializer
    init(viewModel: ILArticleViewModel) {
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

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }

        headerContainer.addSubview(headerView)
        headerContainer.bind(to: scrollView)


        saveButton.onTap = { [weak self] in self?.saveTappedSubject.send(()) }
        shareButton.onTap = { [weak self] in self?.shareTappedSubject.send(()) }

        nextArticlesList.onArticleTap = { [weak self] id in self?.handleNextArticleTapped(id) }

        sourceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSourceTapped)))

        authorAvatar.addSubview(authorInitialsLabel)

        scrollView.addSubview(contentView)

        [
            heroImageView, titleLabel, authorStack, metaDivider, bodyStack,
            quoteView, sourceLabel, actionsStack, readMoreHeader, nextArticlesList
        ].forEach { contentView.addSubview($0) }

        view.addSubview(scrollView)
        view.addSubview(skeletonView)
        view.addSubview(headerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            headerView, scrollView, contentView,
            heroImageView, titleLabel, authorStack, authorInitialsLabel, metaDivider,
            bodyStack, quoteView, sourceLabel, actionsStack, readMoreHeader, nextArticlesList
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -horizontal),

            headerView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -ILMetrics.rowSpacing),

            // The scroll view runs under the header so content can blur through it; the header
            // height is applied as a top content inset in `viewDidLayoutSubviews`.
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            skeletonView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: horizontal),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -horizontal),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -horizontal * 2),

            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ILMetrics.spaceStandard),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: ILMetrics.groupSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            authorStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ILMetrics.spaceMedium),
            authorStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            authorStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            authorAvatar.widthAnchor.constraint(equalToConstant: Self.authorAvatarSize),
            authorAvatar.heightAnchor.constraint(equalToConstant: Self.authorAvatarSize),

            authorInitialsLabel.centerXAnchor.constraint(equalTo: authorAvatar.centerXAnchor),
            authorInitialsLabel.centerYAnchor.constraint(equalTo: authorAvatar.centerYAnchor),

            metaDivider.topAnchor.constraint(equalTo: authorStack.bottomAnchor, constant: ILMetrics.spaceStandard),
            metaDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            metaDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            metaDivider.heightAnchor.constraint(equalToConstant: 1),

            bodyStack.topAnchor.constraint(equalTo: metaDivider.bottomAnchor, constant: ILMetrics.spaceStandard),
            bodyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            quoteView.topAnchor.constraint(equalTo: bodyStack.bottomAnchor, constant: ILMetrics.groupSpacing),
            quoteView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            quoteView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            sourceLabel.topAnchor.constraint(equalTo: quoteView.bottomAnchor, constant: ILMetrics.spaceMedium),
            sourceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sourceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            actionsStack.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: ILMetrics.spaceLarge),
            actionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            readMoreHeader.topAnchor.constraint(equalTo: actionsStack.bottomAnchor, constant: ILMetrics.spaceLarge),
            readMoreHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            readMoreHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            nextArticlesList.topAnchor.constraint(equalTo: readMoreHeader.bottomAnchor, constant: ILMetrics.spaceSmall),
            nextArticlesList.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nextArticlesList.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nextArticlesList.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ILMetrics.spaceLarge)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILArticleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher(),
            nextArticleTapped: nextArticleTappedSubject.eraseToAnyPublisher(),
            sourceTapped: sourceTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILArticleStateModel>) {
        switch state {
        case .idle:
            break
        case .loading:
            skeletonView.setLoading(true)
        case .success(let model):
            skeletonView.setLoading(false)
            updateUI(with: model)
        case .failure(let error):
            skeletonView.setLoading(false)
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILArticleStateModel) {
        headerView.title = model.headerCategory
        headerView.subtitle = model.headerReadText

        heroImageView.configure(category: model.headerCategory, imageURL: model.heroImageURL)

        titleLabel.attributedText = ILTypography.makeParagraph(
            text: model.title,
            font: ILTypography.displayMedium,
            color: ILColors.ink,
            cssLineHeight: 1.3
        )

        authorInitialsLabel.text = model.authorInitials
        authorLabel.text = model.author
        dateReadLabel.text = model.dateReadText

        rebuildBodyParagraphs(model.bodyParagraphs)

        quoteView.quote = model.quote
        quoteView.source = model.quoteSource

        sourceLabel.text = model.sourceText
        sourceLabel.isHidden = model.sourceText.isEmpty
        sourceLabel.textColor = model.sourceURL == nil ? ILColors.inkTertiary : ILColors.link
        sourceLabel.isUserInteractionEnabled = model.sourceURL != nil

        saveButton.title = model.saveButtonTitle
        shareButton.title = model.shareButtonTitle

        readMoreHeader.title = model.readMoreTitle
        nextArticlesList.articles = model.nextArticles
    }

    private func rebuildBodyParagraphs(_ paragraphs: [String]) {
        bodyStack.arrangedSubviews.forEach {
            bodyStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for paragraph in paragraphs {
            let label = UILabel()
            label.numberOfLines = 0
            label.attributedText = ILTypography.makeParagraph(
                text: paragraph,
                font: ILTypography.articleBody,
                color: ILColors.inkStrong,
                cssLineHeight: 1.85
            )
            bodyStack.addArrangedSubview(label)
        }
    }

    // MARK: - Header glass
    /// Pushes content below the header and, on first layout / inset change, parks the offset at
    /// the top of the content (just under the header) instead of beneath it.
    private func applyHeaderInset() {
        let top = headerContainer.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }

    // MARK: - Actions
    @objc private func handleSourceTapped() {
        sourceTappedSubject.send(())
    }

    private func handleNextArticleTapped(_ id: String) {
        nextArticleTappedSubject.send(id)
        // `PassthroughSubject.send` chạy đồng bộ nên state đã được render xong — cuộn về đầu
        // bài mới, khớp hành vi `scrollTop = 0` khi chuyển bài trong prototype.
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: false)
    }
}
