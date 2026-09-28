//
//  ILDeityViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn chi tiết Phật / Bồ Tát — khớp `isBuddha` trong design handoff: hero ảnh 420pt nằm dưới
/// header trong suốt (header chuyển sang nền `canvas` + hiện danh xưng khi cuộn qua hero), thẻ
/// ngày vía, tiểu sử thu gọn, đại nguyện đánh số, thẻ thần chú & danh hiệu, kinh liên quan.
final class ILDeityViewController: BaseViewController {

    private enum Layout {
        /// Chiều cao tối đa của tiểu sử khi thu gọn (design `max-height:152px`).
        static let collapsedBiographyHeight: CGFloat = 152
        static let sectionSpacing: CGFloat = 26
        static let headerBottomInset: CGFloat = 10
    }

    // MARK: - Properties
    private let viewModel: ILDeityViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let biographyToggledSubject = PassthroughSubject<Void, Never>()
    private let vowsToggledSubject = PassthroughSubject<Void, Never>()
    private let festivalsTappedSubject = PassthroughSubject<Void, Never>()
    private let chantTappedSubject = PassthroughSubject<Int, Never>()
    private let shareTappedSubject = PassthroughSubject<Int, Never>()
    private let sutraTappedSubject = PassthroughSubject<Int, Never>()

    private var headerTitle = ""
    private var isHeaderSolid = false
    private var isBiographyExpanded = false

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    /// Dải header dán cố định — trong suốt trên hero, chuyển nền `canvas` khi cuộn qua hero.
    private let headerBand = UIView()
    private let navBar = ILNavBar(showBack: true)

    private let heroView = ILDeityHeroView()
    private let bodyStack = UIStackView()

    private let memorialDayCard = ILDeityMemorialDayCardView()
    private let roleLabel = UILabel()

    private let biographyEyebrow = ILSectionEyebrowView()
    private let biographyLabel = UILabel()
    private let biographyToggle = UIButton(type: .system)
    private lazy var biographyCollapsedConstraint = biographyLabel.heightAnchor.constraint(
        lessThanOrEqualToConstant: Layout.collapsedBiographyHeight
    )

    private let vowsHeaderRow = UIStackView()
    private let vowsEyebrow = ILSectionEyebrowView()
    private let vowsCountLabel = UILabel()
    private let vowsStack = UIStackView()
    private let vowsToggle = UIButton(type: .system)

    private let mantrasEyebrow = ILSectionEyebrowView()
    private let mantrasStack = UIStackView()

    private let sutrasEyebrow = ILSectionEyebrowView()
    private let sutrasStack = UIStackView()

    private let footnoteLabel = UILabel()

    // MARK: - Initializer
    init(viewModel: ILDeityViewModel) {
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
        updateBiographyToggleVisibility()
        updateHeaderAppearance()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        navBar.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerBand.backgroundColor = ILColors.canvas.withAlphaComponent(0)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.addSubview(contentView)

        memorialDayCard.onFestivalsTap = { [weak self] in self?.festivalsTappedSubject.send(()) }

        roleLabel.numberOfLines = 0

        biographyLabel.numberOfLines = 0
        biographyLabel.clipsToBounds = true
        styleLinkButton(biographyToggle)
        biographyToggle.addTarget(self, action: #selector(handleBiographyToggle), for: .touchUpInside)

        vowsCountLabel.font = ILTypography.label
        vowsCountLabel.textColor = ILColors.inkSubtle
        vowsCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        vowsHeaderRow.axis = .horizontal
        vowsHeaderRow.alignment = .lastBaseline
        vowsHeaderRow.addArrangedSubview(vowsEyebrow)
        vowsHeaderRow.addArrangedSubview(vowsCountLabel)

        vowsStack.axis = .vertical
        vowsStack.spacing = ILMetrics.spaceSmall
        styleLinkButton(vowsToggle)
        vowsToggle.addTarget(self, action: #selector(handleVowsToggle), for: .touchUpInside)

        mantrasStack.axis = .vertical
        mantrasStack.spacing = ILMetrics.rowSpacing

        sutrasStack.axis = .vertical
        sutrasStack.spacing = ILMetrics.rowSpacing

        footnoteLabel.numberOfLines = 0

        bodyStack.axis = .vertical
        bodyStack.alignment = .fill
        [
            memorialDayCard, roleLabel,
            biographyEyebrow, biographyLabel, biographyToggle,
            vowsHeaderRow, vowsStack, vowsToggle,
            mantrasEyebrow, mantrasStack,
            sutrasEyebrow, sutrasStack,
            footnoteLabel
        ].forEach { bodyStack.addArrangedSubview($0) }
        bodyStack.setCustomSpacing(ILMetrics.rowSpacing, after: memorialDayCard)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: roleLabel)
        bodyStack.setCustomSpacing(ILMetrics.rowSpacing, after: biographyEyebrow)
        bodyStack.setCustomSpacing(6, after: biographyLabel)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: biographyToggle)
        bodyStack.setCustomSpacing(12, after: vowsHeaderRow)
        bodyStack.setCustomSpacing(ILMetrics.spaceSmall, after: vowsStack)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: vowsToggle)
        bodyStack.setCustomSpacing(ILMetrics.rowSpacing, after: mantrasEyebrow)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: mantrasStack)
        bodyStack.setCustomSpacing(ILMetrics.rowSpacing, after: sutrasEyebrow)
        bodyStack.setCustomSpacing(ILMetrics.groupSpacing, after: sutrasStack)

        contentView.addSubview(heroView)
        contentView.addSubview(bodyStack)

        headerBand.addSubview(navBar)
        view.addSubview(scrollView)
        view.addSubview(headerBand)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [scrollView, contentView, headerBand, navBar, heroView, bodyStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header dán cố định, đè lên hero.
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            navBar.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: horizontal),
            navBar.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -horizontal),
            navBar.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -Layout.headerBottomInset),

            // Hero full-bleed trên cùng nội dung cuộn, nằm dưới header.
            heroView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bodyStack.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: ILMetrics.spaceStandard),
            bodyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            bodyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),
            bodyStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -34)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILDeityViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            biographyToggled: biographyToggledSubject.eraseToAnyPublisher(),
            vowsToggled: vowsToggledSubject.eraseToAnyPublisher(),
            festivalsTapped: festivalsTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher(),
            sutraTapped: sutraTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILDeityStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILDeityStateModel) {
        headerTitle = model.headerTitle
        navBar.title = isHeaderSolid ? headerTitle : ""

        heroView.configure(
            kindLabel: model.kindLabel,
            realm: model.realmLabel,
            name: model.name,
            sanskrit: model.sanskritName,
            watermark: model.watermark
        )

        if let memorialDay = model.memorialDay {
            memorialDayCard.configure(with: memorialDay, festivalsTitle: model.festivalsLinkTitle)
        }
        memorialDayCard.isHidden = model.memorialDay == nil

        roleLabel.attributedText = ILTypography.makeParagraph(
            text: model.roleText,
            font: ILTypography.bodyCompact,
            color: ILColors.inkSecondary,
            cssLineHeight: 1.6
        )
        roleLabel.isHidden = model.roleText.isEmpty

        biographyEyebrow.title = model.biographyTitle
        biographyLabel.attributedText = ILTypography.makeParagraph(
            text: model.biography,
            font: ILTypography.postBody,
            color: ILColors.inkSecondary,
            cssLineHeight: 1.75
        )
        isBiographyExpanded = model.isBiographyExpanded
        biographyCollapsedConstraint.isActive = !model.isBiographyExpanded
        biographyToggle.setTitle(model.biographyToggleTitle, for: .normal)

        vowsEyebrow.title = model.vowsTitle
        vowsCountLabel.text = model.vowsCountText
        renderVows(model.vows)
        vowsToggle.setTitle(model.vowsToggleTitle, for: .normal)
        vowsToggle.isHidden = model.vowsToggleTitle == nil
        let hasVows = !model.vows.isEmpty
        [vowsHeaderRow, vowsStack].forEach { $0.isHidden = !hasVows }

        mantrasEyebrow.title = model.mantrasTitle
        renderMantras(model.mantras, chantTitle: model.chantTitle, shareTitle: model.shareTitle)
        [mantrasEyebrow, mantrasStack].forEach { $0.isHidden = model.mantras.isEmpty }

        sutrasEyebrow.title = model.sutrasTitle
        renderSutras(model.sutras)
        [sutrasEyebrow, sutrasStack].forEach { $0.isHidden = model.sutras.isEmpty }

        footnoteLabel.attributedText = ILTypography.makeParagraph(
            text: model.footnote,
            font: ILTypography.label,
            color: ILColors.inkSubtle,
            cssLineHeight: 1.6,
            alignment: .center
        )

        view.setNeedsLayout()
    }

    private func renderVows(_ vows: [ILDeityVowModel]) {
        clear(vowsStack)
        vows.forEach { vowsStack.addArrangedSubview(ILDeityVowRowView(model: $0)) }
    }

    private func renderMantras(_ mantras: [ILDeityMantraModel], chantTitle: String, shareTitle: String) {
        clear(mantrasStack)
        for (index, mantra) in mantras.enumerated() {
            let card = ILDeityMantraCardView(model: mantra, chantTitle: chantTitle, shareTitle: shareTitle)
            card.onChantTap = { [weak self] in self?.chantTappedSubject.send(index) }
            card.onShareTap = { [weak self] in self?.shareTappedSubject.send(index) }
            mantrasStack.addArrangedSubview(card)
        }
    }

    private func renderSutras(_ sutras: [ILDeitySutraModel]) {
        clear(sutrasStack)
        for (index, sutra) in sutras.enumerated() {
            let row = ILRow(
                title: sutra.title,
                subtitle: sutra.subtitle,
                trailingText: sutra.trailingText,
                tone: .gold,
                glyph: .book
            )
            if sutra.sutraID != nil {
                row.onTap = { [weak self] in self?.sutraTappedSubject.send(index) }
            } else {
                row.isUserInteractionEnabled = false
            }
            sutrasStack.addArrangedSubview(row)
        }
    }

    private func clear(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func styleLinkButton(_ button: UIButton) {
        button.titleLabel?.font = ILTypography.chip
        button.setTitleColor(ILColors.link, for: .normal)
        button.contentHorizontalAlignment = .leading
    }

    // MARK: - Layout-driven UI
    /// "Đọc thêm" chỉ hiện khi tiểu sử thực sự dài hơn chiều cao thu gọn; khi đang mở rộng thì
    /// luôn hiện "Thu gọn".
    private func updateBiographyToggleVisibility() {
        let width = biographyLabel.bounds.width
        guard width > 0 else { return }
        let fullHeight = biographyLabel.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
        let shouldHide = !isBiographyExpanded && fullHeight <= Layout.collapsedBiographyHeight
        if biographyToggle.isHidden != shouldHide {
            biographyToggle.isHidden = shouldHide
        }
    }

    /// Header chuyển sang nền đặc + hiện danh xưng khi đáy hero đã cuộn lên sát header
    /// (design `hdrSolid`).
    private func updateHeaderAppearance() {
        let threshold = heroView.frame.maxY - headerBand.frame.height
        let shouldBeSolid = threshold > 0 && scrollView.contentOffset.y >= threshold
        guard shouldBeSolid != isHeaderSolid else { return }
        isHeaderSolid = shouldBeSolid
        UIView.animate(withDuration: 0.2) {
            self.headerBand.backgroundColor = shouldBeSolid
                ? ILColors.canvas
                : ILColors.canvas.withAlphaComponent(0)
        }
        navBar.title = shouldBeSolid ? headerTitle : ""
    }

    // MARK: - Actions
    @objc private func handleBiographyToggle() {
        biographyToggledSubject.send(())
    }

    @objc private func handleVowsToggle() {
        vowsToggledSubject.send(())
    }
}

// MARK: - UIScrollViewDelegate
extension ILDeityViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderAppearance()
    }
}
