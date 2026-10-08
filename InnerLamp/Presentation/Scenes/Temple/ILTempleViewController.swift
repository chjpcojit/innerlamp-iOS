//
//  ILTempleViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Trang chùa — hồ sơ đầy đủ của một ngôi chùa, khớp `isTemple` trong design handoff: hero trong
/// suốt (chuyển nền đặc + hiện tên chùa khi cuộn qua), 3 nút (Theo dõi/Chỉ đường/Cúng dường), thẻ
/// trạng thái mở cửa, lưới 4 ô niên đại/di tích/hệ phái/vùng miền, giới thiệu thu gọn, tổ chức &
/// truyền thừa, kiến trúc & di sản, tiện ích, lưu ý khi viếng thăm, sự kiện & khóa học, vị trí &
/// liên hệ, chân trang.
///
/// Data comes only from the server (`GET /v1/temples/{id}`). Every section is always shown; one
/// whose data the API does not send renders the "Đang cập nhật" placeholder. While loading / on
/// failure the whole screen shows a skeleton placeholder / an error + "Thử lại".
final class ILTempleViewController: BaseViewController {

    private enum Layout {
        /// Chiều cao tối đa của giới thiệu khi thu gọn (design `max-height:152px`).
        static let collapsedBiographyHeight: CGFloat = 152
        static let sectionSpacing: CGFloat = 26
        static let headerBottomInset: CGFloat = 10
        /// Opacity of the `canvas` tint over the blur once the header is "solid", low enough that
        /// the blurred content underneath stays visible.
        static let solidHeaderTintAlpha: CGFloat = 0.35
        static let gridSpacing: CGFloat = 8
    }

    private enum ScreenState {
        case loading
        case content
        case error
    }

    // MARK: - Properties
    private let viewModel: ILTempleViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let retryTappedSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let followTappedSubject = PassthroughSubject<Void, Never>()
    private let bioToggledSubject = PassthroughSubject<Void, Never>()
    private let googleMapsTappedSubject = PassthroughSubject<Void, Never>()
    private let appleMapsTappedSubject = PassthroughSubject<Void, Never>()
    private let offerTappedSubject = PassthroughSubject<Void, Never>()
    private let eventsTappedSubject = PassthroughSubject<Void, Never>()
    private let sessionTappedSubject = PassthroughSubject<String, Never>()
    private let contactTappedSubject = PassthroughSubject<String, Never>()

    private var headerTitle = ""
    private var isHeaderSolid = false
    private var hasHeroImage = false
    private var isBiographyExpanded = false

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    /// Dải header dán cố định — trong suốt trên hero, chuyển nền `canvas` khi cuộn qua hero.
    /// Blur only: the canvas tint is state-driven (`updateHeaderAppearance`), so the band's own tint stays off.
    private let headerBand = ILStickyHeaderBand(tintRestAlpha: 0, tintGlassAlpha: 0)
    private let navBar = ILNavBar(showBack: true)

    private let heroView = ILTempleHeroView()

    private lazy var followButton = ILButton(title: "", variant: .primary)
    private lazy var directionsButton = ILButton(title: "", variant: .ghost)
    private lazy var offerButton = ILButton(title: "", variant: .ghost)
    private let pillsStack = UIStackView()

    private let bodyStack = UIStackView()

    private let statusCard = ILTempleStatusCardView()
    private let factsGrid = UIView()

    private let introEyebrow = ILSectionEyebrowView()
    private let biographyLabel = UILabel()
    private let biographyToggle = UIButton(type: .system)
    private lazy var biographyCollapsedConstraint = biographyLabel.heightAnchor.constraint(
        lessThanOrEqualToConstant: Layout.collapsedBiographyHeight
    )

    private let orgEyebrow = ILSectionEyebrowView()
    private let orgCard = UIView()
    private let orgStack = UIStackView()

    private let architectureEyebrow = ILSectionEyebrowView()
    private let architectureLabel = UILabel()
    private let highlightsStack = UIStackView()

    private let amenitiesEyebrow = ILSectionEyebrowView()
    private let amenitiesGrid = UIView()

    private let rulesEyebrow = ILSectionEyebrowView()
    private let rulesCard = UIView()
    private let rulesStack = UIStackView()

    private let eventsHeaderRow = UIStackView()
    private let eventsEyebrow = ILSectionEyebrowView()
    private let eventsViewAllButton = UIButton(type: .system)
    private let eventsEmptyView = UIView()
    private let eventsEmptyLabel = UILabel()
    private let sessionsStack = UIStackView()

    private let locationEyebrow = ILSectionEyebrowView()
    private let mapCard = UIView()
    private let mapPlaceholder = UIView()
    private let addressLabel = UILabel()
    private let regionLabel = UILabel()
    private let coordinateLabel = UILabel()
    private lazy var googleMapsButton = ILButton(title: "", variant: .ghost)
    private lazy var appleMapsButton = ILButton(title: "", variant: .ghost)
    private let contactsCard = UIView()
    private let contactsStack = UIStackView()

    private let footerStack = UIStackView()
    private let updatedLabel = UILabel()
    private let footerDotLabel = UILabel()
    private let reportIssueLabel = UILabel()

    /// Whole-screen loading / error states, shown instead of `scrollView` while the profile is
    /// not on screen yet.
    private let loadingView = ILTempleSkeletonView()
    private let errorStateView = ILStateView(kind: .error)
    private lazy var retryButton = ILButton(title: "common.retry".localized, variant: .primary)
    private let errorStack = UIStackView()

    // MARK: - Initializer
    init(viewModel: ILTempleViewModel) {
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
        navBar.usesTransparentButtons = true
        headerBand.backgroundColor = ILColors.canvas.withAlphaComponent(0)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.addSubview(contentView)

        setupButtonsRow()
        setupIntroSection()
        setupOrgSection()
        setupArchitectureSection()
        setupRulesSection()
        setupEventsSection()
        setupLocationSection()
        setupFooterSection()
        setupStateViews()

        bodyStack.axis = .vertical
        bodyStack.alignment = .fill
        [
            statusCard, factsGrid,
            introEyebrow, biographyLabel, biographyToggle,
            orgEyebrow, orgCard,
            architectureEyebrow, architectureLabel, highlightsStack,
            amenitiesEyebrow, amenitiesGrid,
            rulesEyebrow, rulesCard,
            eventsHeaderRow, eventsEmptyView, sessionsStack,
            locationEyebrow, mapCard, contactsCard,
            footerStack
        ].forEach { bodyStack.addArrangedSubview($0) }

        bodyStack.setCustomSpacing(10, after: statusCard)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: factsGrid)
        bodyStack.setCustomSpacing(10, after: introEyebrow)
        bodyStack.setCustomSpacing(6, after: biographyLabel)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: biographyToggle)
        bodyStack.setCustomSpacing(10, after: orgEyebrow)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: orgCard)
        bodyStack.setCustomSpacing(10, after: architectureEyebrow)
        bodyStack.setCustomSpacing(12, after: architectureLabel)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: highlightsStack)
        bodyStack.setCustomSpacing(10, after: amenitiesEyebrow)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: amenitiesGrid)
        bodyStack.setCustomSpacing(10, after: rulesEyebrow)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: rulesCard)
        bodyStack.setCustomSpacing(10, after: eventsHeaderRow)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: eventsEmptyView)
        bodyStack.setCustomSpacing(Layout.sectionSpacing, after: sessionsStack)
        bodyStack.setCustomSpacing(10, after: locationEyebrow)
        bodyStack.setCustomSpacing(10, after: mapCard)
        bodyStack.setCustomSpacing(14, after: contactsCard)

        contentView.addSubview(heroView)
        contentView.addSubview(pillsStack)
        contentView.addSubview(bodyStack)

        heroView.onBlurProgress = { [weak self] progress in
            guard let self else { return }
            // Once solid the strip stays fully blurred, even when there is no photo to drive it.
            headerBand.setProgress(isHeaderSolid ? 1 : progress)
        }
        headerBand.addSubview(navBar)
        view.addSubview(scrollView)
        view.addSubview(loadingView)
        view.addSubview(errorStack)
        view.addSubview(headerBand)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (controller: ILTempleViewController, _) in
            controller.applyColorAppearanceChange()
        }
    }

    /// `layer.borderColor` là CGColor tĩnh, không tự đảo theo trait — refresh thủ công khi hệ
    /// thống đổi light/dark (thẻ dán cố định `orgCard`/`rulesCard`/`mapCard`/`contactsCard` và
    /// viền nét đứt của `eventsEmptyView` sống suốt vòng đời màn, khác các ô lưới được dựng lại
    /// mỗi lần `updateUI`).
    private func applyColorAppearanceChange() {
        orgCard.layer.borderColor = ILColors.border.cgColor
        rulesCard.layer.borderColor = ILColors.featBorder.cgColor
        mapCard.layer.borderColor = ILColors.border.cgColor
        contactsCard.layer.borderColor = ILColors.border.cgColor
        (eventsEmptyView.layer.sublayers?.first as? CAShapeLayer)?.strokeColor = ILColors.borderStrong.cgColor
    }

    private func setupStateViews() {
        loadingView.isHidden = true

        retryButton.onTap = { [weak self] in self?.retryTappedSubject.send(()) }
        errorStack.axis = .vertical
        errorStack.alignment = .fill
        errorStack.spacing = ILMetrics.groupSpacing
        errorStack.addArrangedSubview(errorStateView)
        errorStack.addArrangedSubview(retryButton)
        errorStack.isHidden = true
    }

    private func setupButtonsRow() {
        followButton.onTap = { [weak self] in self?.followTappedSubject.send(()) }
        directionsButton.onTap = { [weak self] in self?.googleMapsTappedSubject.send(()) }
        offerButton.onTap = { [weak self] in self?.offerTappedSubject.send(()) }

        pillsStack.axis = .horizontal
        pillsStack.spacing = ILMetrics.rowSpacing
        pillsStack.distribution = .fillEqually
        pillsStack.addArrangedSubview(followButton)
        pillsStack.addArrangedSubview(directionsButton)
        pillsStack.addArrangedSubview(offerButton)
    }

    private func setupIntroSection() {
        biographyLabel.numberOfLines = 0
        biographyLabel.clipsToBounds = true
        styleLinkButton(biographyToggle)
        biographyToggle.addTarget(self, action: #selector(handleBiographyToggle), for: .touchUpInside)
    }

    private func setupOrgSection() {
        orgCard.backgroundColor = ILColors.surface
        orgCard.layer.cornerRadius = ILMetrics.radiusCardLarge
        orgCard.layer.borderWidth = 1
        orgCard.layer.borderColor = ILColors.border.cgColor

        orgStack.axis = .vertical
        orgStack.translatesAutoresizingMaskIntoConstraints = false
        orgCard.addSubview(orgStack)
        NSLayoutConstraint.activate([
            orgStack.leadingAnchor.constraint(equalTo: orgCard.leadingAnchor, constant: 16),
            orgStack.trailingAnchor.constraint(equalTo: orgCard.trailingAnchor, constant: -16),
            orgStack.topAnchor.constraint(equalTo: orgCard.topAnchor),
            orgStack.bottomAnchor.constraint(equalTo: orgCard.bottomAnchor)
        ])
    }

    private func setupArchitectureSection() {
        architectureLabel.font = ILTypography.bodySmall
        architectureLabel.numberOfLines = 0

        highlightsStack.axis = .vertical
        highlightsStack.spacing = ILMetrics.rowSpacing
    }

    private func setupRulesSection() {
        rulesCard.backgroundColor = ILColors.featBackgroundStart
        rulesCard.layer.cornerRadius = ILMetrics.radiusCardLarge
        rulesCard.layer.borderWidth = 1
        rulesCard.layer.borderColor = ILColors.featBorder.cgColor

        rulesStack.axis = .vertical
        rulesStack.spacing = 10
        rulesStack.translatesAutoresizingMaskIntoConstraints = false
        rulesCard.addSubview(rulesStack)
        NSLayoutConstraint.activate([
            rulesStack.leadingAnchor.constraint(equalTo: rulesCard.leadingAnchor, constant: 16),
            rulesStack.trailingAnchor.constraint(equalTo: rulesCard.trailingAnchor, constant: -16),
            rulesStack.topAnchor.constraint(equalTo: rulesCard.topAnchor, constant: 16),
            rulesStack.bottomAnchor.constraint(equalTo: rulesCard.bottomAnchor, constant: -16)
        ])
    }

    private func setupEventsSection() {
        eventsViewAllButton.setTitleColor(ILColors.link, for: .normal)
        eventsViewAllButton.titleLabel?.font = ILTypography.chip
        eventsViewAllButton.setTitle("temple.events.viewAll".localized, for: .normal)
        eventsViewAllButton.addTarget(self, action: #selector(handleEventsTapped), for: .touchUpInside)

        eventsHeaderRow.axis = .horizontal
        eventsHeaderRow.alignment = .lastBaseline
        eventsHeaderRow.addArrangedSubview(eventsEyebrow)
        eventsHeaderRow.addArrangedSubview(UIView())
        eventsHeaderRow.addArrangedSubview(eventsViewAllButton)

        eventsEmptyView.layer.cornerRadius = ILMetrics.radiusCardSmall
        let dashedBorder = CAShapeLayer()
        dashedBorder.strokeColor = ILColors.borderStrong.cgColor
        dashedBorder.fillColor = nil
        dashedBorder.lineDashPattern = [4, 4]
        eventsEmptyView.layer.addSublayer(dashedBorder)
        eventsEmptyView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleEventsTapped))
        )

        eventsEmptyLabel.font = ILTypography.bodySmall
        eventsEmptyLabel.textColor = ILColors.inkTertiary
        eventsEmptyLabel.numberOfLines = 0
        eventsEmptyLabel.translatesAutoresizingMaskIntoConstraints = false
        eventsEmptyView.addSubview(eventsEmptyLabel)
        NSLayoutConstraint.activate([
            eventsEmptyLabel.leadingAnchor.constraint(equalTo: eventsEmptyView.leadingAnchor, constant: 16),
            eventsEmptyLabel.trailingAnchor.constraint(equalTo: eventsEmptyView.trailingAnchor, constant: -16),
            eventsEmptyLabel.topAnchor.constraint(equalTo: eventsEmptyView.topAnchor, constant: 14),
            eventsEmptyLabel.bottomAnchor.constraint(equalTo: eventsEmptyView.bottomAnchor, constant: -14)
        ])

        sessionsStack.axis = .vertical
        sessionsStack.spacing = ILMetrics.rowSpacing
    }

    private func setupLocationSection() {
        mapCard.backgroundColor = ILColors.surface
        mapCard.layer.cornerRadius = ILMetrics.radiusCardLarge
        mapCard.layer.borderWidth = 1
        mapCard.layer.borderColor = ILColors.border.cgColor
        mapCard.clipsToBounds = true

        mapPlaceholder.backgroundColor = ILColors.sunk2
        let mapCaption = UILabel()
        mapCaption.font = ILTypography.label
        mapCaption.textColor = ILColors.inkMuted
        mapCaption.text = "temple.map.placeholder".localized
        mapCaption.translatesAutoresizingMaskIntoConstraints = false
        mapPlaceholder.addSubview(mapCaption)
        NSLayoutConstraint.activate([
            mapCaption.centerXAnchor.constraint(equalTo: mapPlaceholder.centerXAnchor),
            mapCaption.centerYAnchor.constraint(equalTo: mapPlaceholder.centerYAnchor)
        ])

        addressLabel.font = ILTypography.body
        addressLabel.textColor = ILColors.ink
        addressLabel.numberOfLines = 0

        regionLabel.font = ILTypography.label
        regionLabel.textColor = ILColors.inkTertiary

        coordinateLabel.font = ILTypography.label
        coordinateLabel.textColor = ILColors.inkFaint

        googleMapsButton.onTap = { [weak self] in self?.googleMapsTappedSubject.send(()) }
        appleMapsButton.onTap = { [weak self] in self?.appleMapsTappedSubject.send(()) }
        googleMapsButton.title = "temple.map.googleMaps".localized
        appleMapsButton.title = "temple.map.appleMaps".localized
        let mapButtonsRow = UIStackView(arrangedSubviews: [googleMapsButton, appleMapsButton])
        mapButtonsRow.axis = .horizontal
        mapButtonsRow.spacing = ILMetrics.rowSpacing
        mapButtonsRow.distribution = .fillEqually

        let mapDetailStack = UIStackView(arrangedSubviews: [addressLabel, regionLabel, coordinateLabel, mapButtonsRow])
        mapDetailStack.axis = .vertical
        mapDetailStack.spacing = 4
        mapDetailStack.setCustomSpacing(12, after: coordinateLabel)
        mapDetailStack.translatesAutoresizingMaskIntoConstraints = false

        [mapPlaceholder, mapDetailStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            mapCard.addSubview($0)
        }
        NSLayoutConstraint.activate([
            mapPlaceholder.topAnchor.constraint(equalTo: mapCard.topAnchor),
            mapPlaceholder.leadingAnchor.constraint(equalTo: mapCard.leadingAnchor),
            mapPlaceholder.trailingAnchor.constraint(equalTo: mapCard.trailingAnchor),
            mapPlaceholder.heightAnchor.constraint(equalToConstant: 130),

            mapDetailStack.topAnchor.constraint(equalTo: mapPlaceholder.bottomAnchor, constant: 14),
            mapDetailStack.leadingAnchor.constraint(equalTo: mapCard.leadingAnchor, constant: 16),
            mapDetailStack.trailingAnchor.constraint(equalTo: mapCard.trailingAnchor, constant: -16),
            mapDetailStack.bottomAnchor.constraint(equalTo: mapCard.bottomAnchor, constant: -16)
        ])

        contactsCard.backgroundColor = ILColors.surface
        contactsCard.layer.cornerRadius = ILMetrics.radiusCardLarge
        contactsCard.layer.borderWidth = 1
        contactsCard.layer.borderColor = ILColors.border.cgColor

        contactsStack.axis = .vertical
        contactsStack.translatesAutoresizingMaskIntoConstraints = false
        contactsCard.addSubview(contactsStack)
        NSLayoutConstraint.activate([
            contactsStack.leadingAnchor.constraint(equalTo: contactsCard.leadingAnchor, constant: 16),
            contactsStack.trailingAnchor.constraint(equalTo: contactsCard.trailingAnchor, constant: -16),
            contactsStack.topAnchor.constraint(equalTo: contactsCard.topAnchor),
            contactsStack.bottomAnchor.constraint(equalTo: contactsCard.bottomAnchor)
        ])
    }

    private func setupFooterSection() {
        updatedLabel.font = ILTypography.label
        updatedLabel.textColor = ILColors.inkFaint

        reportIssueLabel.font = ILTypography.label
        reportIssueLabel.textColor = ILColors.inkFaint
        reportIssueLabel.text = "temple.footer.reportIssue".localized

        footerDotLabel.font = ILTypography.label
        footerDotLabel.textColor = ILColors.inkFaint
        footerDotLabel.text = "·"

        footerStack.axis = .horizontal
        footerStack.spacing = 6
        footerStack.alignment = .center
        footerStack.distribution = .equalCentering
        [UIView(), updatedLabel, footerDotLabel, reportIssueLabel, UIView()].forEach { footerStack.addArrangedSubview($0) }
    }

    // MARK: - Constraints
    override func setupConstraints() {
        super.setupConstraints()
        [scrollView, contentView, navBar, heroView, pillsStack, bodyStack, loadingView, errorStack].forEach {
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

            // 3 nút chờm lên hero 20pt.
            pillsStack.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: -20),
            pillsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            pillsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            bodyStack.topAnchor.constraint(equalTo: pillsStack.bottomAnchor, constant: 16),
            bodyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            bodyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),
            bodyStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),

            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            errorStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal)
        ])
    }

    // MARK: - Bind
    override func bindViewModel() {
        super.bindViewModel()

        let input = ILTempleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            followTapped: followTappedSubject.eraseToAnyPublisher(),
            bioToggled: bioToggledSubject.eraseToAnyPublisher(),
            googleMapsTapped: googleMapsTappedSubject.eraseToAnyPublisher(),
            appleMapsTapped: appleMapsTappedSubject.eraseToAnyPublisher(),
            offerTapped: offerTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            sessionTapped: sessionTappedSubject.eraseToAnyPublisher(),
            contactTapped: contactTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        output.errorMessage
            .sink { [weak self] message in self?.showError(message) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILTempleStateModel>) {
        switch state {
        case .idle:
            break
        case .loading:
            showScreenState(.loading)
        case .success(let model):
            showScreenState(.content)
            updateUI(with: model)
        case .failure(let error):
            configureErrorState(for: error)
            showScreenState(.error)
        }
    }

    private func showScreenState(_ screenState: ScreenState) {
        scrollView.isHidden = screenState != .content
        errorStack.isHidden = screenState != .error
        // Each skeleton bar starts pulsing itself once it is in a window.
        loadingView.isHidden = screenState != .loading
        if screenState != .content {
            // The header stays transparent over the plain canvas, with no title.
            scrollView.contentOffset = .zero
            updateHeaderAppearance()
        }
    }

    /// Offline gets its own glyph/title; every other failure (not found, server error) reads as a
    /// generic load error with the error's own message.
    private func configureErrorState(for error: Error) {
        if case ILCatalogError.offline = error {
            errorStateView.kind = .offline
            errorStateView.title = "temple.error.offlineTitle".localized
        } else {
            errorStateView.kind = .error
            errorStateView.title = "temple.error.title".localized
        }
        errorStateView.message = error.localizedDescription
    }

    private func updateUI(with model: ILTempleStateModel) {
        headerTitle = model.headerTitle
        navBar.title = isHeaderSolid ? headerTitle : ""
        hasHeroImage = model.heroImageURL?.isEmpty == false
        updateNavBarStyle()

        heroView.configure(
            rankChip: model.rankChip, sectChip: model.sectChip, name: model.name,
            hasAlias: model.hasAlias, aliasLine: model.aliasLine, placeLine: model.placeLine,
            imageURL: model.heroImageURL
        )

        followButton.title = model.followButtonTitle
        directionsButton.title = model.directionsButtonTitle
        offerButton.title = model.offerButtonTitle

        statusCard.configure(
            isOpen: model.isOpen, statusText: model.openStatusText, noteText: model.openNoteText,
            distanceText: model.distanceText, hourRows: model.hourRows
        )

        renderFactsGrid(model.facts)

        introEyebrow.title = "temple.section.intro".localized
        biographyLabel.attributedText = model.descriptionText.isEmpty
            ? Self.makePlaceholderText()
            : ILTypography.makeParagraph(
                text: model.descriptionText, font: ILTypography.scriptureDescription,
                color: ILColors.inkSecondary, cssLineHeight: 1.7
            )
        isBiographyExpanded = model.isBiographyExpanded
        biographyCollapsedConstraint.isActive = !model.isBiographyExpanded
        biographyToggle.setTitle(model.biographyToggleTitle, for: .normal)

        orgEyebrow.title = "temple.section.org".localized
        renderOrgInfo(model.orgInfo)

        architectureEyebrow.title = "temple.section.architecture".localized
        architectureLabel.attributedText = model.architectureText.isEmpty
            ? Self.makePlaceholderText()
            : ILTypography.makeParagraph(
                text: model.architectureText, font: ILTypography.bodySmall,
                color: ILColors.inkSecondary, cssLineHeight: 1.65
            )
        renderHighlights(model.highlights)

        amenitiesEyebrow.title = "temple.section.amenities".localized
        renderAmenitiesGrid(model.amenities)

        rulesEyebrow.title = "temple.section.rules".localized
        renderRules(model.visitRules)

        eventsEyebrow.title = "temple.section.events".localized
        eventsEmptyLabel.text = "temple.events.empty".localized
        eventsEmptyView.isHidden = model.hasUpcomingSchedule
        sessionsStack.isHidden = !model.hasUpcomingSchedule
        renderSessions(model.sessions)

        locationEyebrow.title = "temple.section.location".localized
        addressLabel.text = model.addressLine
        regionLabel.text = model.regionLine
        coordinateLabel.text = model.coordinateText
        renderContacts(model.contacts)

        // No date → only "Báo thông tin sai" is shown (no dangling "·").
        updatedLabel.text = model.updatedText
        updatedLabel.isHidden = model.updatedText.isEmpty
        footerDotLabel.isHidden = model.updatedText.isEmpty

        view.setNeedsLayout()
    }

    // MARK: - Rendering helpers
    private func renderFactsGrid(_ facts: [ILTempleFactModel]) {
        clearSubviews(of: factsGrid)
        let tiles = facts.map { ILTempleFactTileView(model: $0) }
        embedGrid(tiles, in: factsGrid)
    }

    private func renderOrgInfo(_ rows: [ILTempleOrgInfoModel]) {
        clear(orgStack)
        for (index, row) in rows.enumerated() {
            orgStack.addArrangedSubview(ILTempleKeyValueRow(label: row.label, value: row.value, isMuted: !row.hasValue, showsDivider: index < rows.count - 1))
        }
    }

    private func renderHighlights(_ highlights: [String]) {
        clear(highlightsStack)
        highlights.forEach { highlightsStack.addArrangedSubview(ILTempleHighlightCardView(text: $0)) }
    }

    private func renderAmenitiesGrid(_ amenities: [ILTempleAmenityModel]) {
        clearSubviews(of: amenitiesGrid)
        let tiles = amenities.map { ILTempleAmenityTileView(model: $0) }
        embedGrid(tiles, in: amenitiesGrid)
    }

    /// No rules from the API → the card shows the "Đang cập nhật" placeholder.
    private func renderRules(_ rules: [ILTempleRuleModel]) {
        clear(rulesStack)
        guard !rules.isEmpty else {
            let placeholder = UILabel()
            placeholder.attributedText = Self.makePlaceholderText()
            rulesStack.addArrangedSubview(placeholder)
            return
        }
        rules.forEach { rulesStack.addArrangedSubview(ILTempleRuleRow(model: $0)) }
    }

    private func renderSessions(_ sessions: [ILTempleSessionModel]) {
        clear(sessionsStack)
        for session in sessions {
            let row = ILRow(
                title: session.title, subtitle: session.subtitle, trailingText: session.trailingText,
                tone: mapTone(session.tone), glyph: mapGlyph(session.glyph)
            )
            row.onTap = { [weak self] in self?.sessionTappedSubject.send(session.id) }
            sessionsStack.addArrangedSubview(row)
        }
    }

    private func renderContacts(_ contacts: [ILTempleContactModel]) {
        clear(contactsStack)
        for (index, contact) in contacts.enumerated() {
            let row = ILTempleKeyValueRow(
                label: contact.label, value: contact.value, isMuted: !contact.hasValue,
                showsDivider: index < contacts.count - 1, showsChevron: contact.hasValue
            )
            if contact.hasValue {
                row.onTap = { [weak self] in self?.contactTappedSubject.send(contact.id) }
            }
            contactsStack.addArrangedSubview(row)
        }
    }

    /// Bố cục lưới 2 cột — dùng cho lưới 4 ô "Niên đại/Cấp di tích/Hệ phái/Vùng miền" và lưới 5 ô
    /// "Tiện ích" (hàng cuối lẻ chỉ chiếm nửa trái, còn nửa phải bỏ trống — khớp
    /// `grid-template-columns: repeat(2, 1fr)` trong design handoff).
    private func embedGrid(_ tiles: [UIView], in container: UIView) {
        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = Layout.gridSpacing
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        for pairStart in stride(from: 0, to: tiles.count, by: 2) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Layout.gridSpacing
            rowStack.distribution = .fillEqually
            rowStack.addArrangedSubview(tiles[pairStart])
            if pairStart + 1 < tiles.count {
                rowStack.addArrangedSubview(tiles[pairStart + 1])
            } else {
                rowStack.addArrangedSubview(UIView())
            }
            rowsStack.addArrangedSubview(rowStack)
        }

        container.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            rowsStack.topAnchor.constraint(equalTo: container.topAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func clear(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func clearSubviews(of view: UIView) {
        view.subviews.forEach { $0.removeFromSuperview() }
    }

    private func styleLinkButton(_ button: UIButton) {
        button.titleLabel?.font = ILTypography.chip
        button.setTitleColor(ILColors.link, for: .normal)
        button.contentHorizontalAlignment = .leading
    }

    private func mapTone(_ tone: ILTempleSessionTone) -> ILColors.Tone {
        switch tone {
        case .gold: return .gold
        case .green: return .green
        }
    }

    private func mapGlyph(_ glyph: ILTempleSessionGlyph) -> ILRow.Glyph {
        switch glyph {
        case .book: return .book
        case .circle: return .circle
        }
    }

    /// "Đang cập nhật" in the muted italic style the org/contact rows use for a missing value.
    private static func makePlaceholderText() -> NSAttributedString {
        var font = ILTypography.bodySmall
        if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) {
            font = UIFont(descriptor: descriptor, size: font.pointSize)
        }
        return NSAttributedString(
            string: "temple.info.updating".localized,
            attributes: [.font: font, .foregroundColor: ILColors.inkFaint]
        )
    }

    // MARK: - Layout-driven UI
    /// "Đọc thêm" chỉ hiện khi giới thiệu thực sự dài hơn chiều cao thu gọn; khi đang mở rộng thì
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

        if let dashedLayer = eventsEmptyView.layer.sublayers?.first(where: { $0 is CAShapeLayer }) as? CAShapeLayer {
            dashedLayer.frame = eventsEmptyView.bounds
            dashedLayer.path = UIBezierPath(
                roundedRect: eventsEmptyView.bounds, cornerRadius: ILMetrics.radiusCardSmall
            ).cgPath
        }
    }

    /// Header chuyển sang nền đặc + hiện tên chùa khi đáy hero đã cuộn lên sát header (design
    /// `hdrSolid`).
    private func updateHeaderAppearance() {
        let threshold = heroView.frame.maxY - headerBand.frame.height
        let shouldBeSolid = threshold > 0 && scrollView.contentOffset.y >= threshold
        guard shouldBeSolid != isHeaderSolid else { return }
        isHeaderSolid = shouldBeSolid
        updateNavBarStyle()
        heroView.update(contentOffsetY: scrollView.contentOffset.y)
        if shouldBeSolid { headerBand.setProgress(1) }
        UIView.animate(withDuration: 0.2) {
            self.headerBand.backgroundColor = ILColors.canvas.withAlphaComponent(
                shouldBeSolid ? Layout.solidHeaderTintAlpha : 0
            )
        }
        navBar.title = shouldBeSolid ? headerTitle : ""
    }

    /// Buttons are transparent, so over the photo they use the light (on-dark) palette; once the
    /// header turns solid, or when the temple has no photo, they use the normal theme palette.
    private func updateNavBarStyle() {
        navBar.isDark = hasHeroImage && !isHeaderSolid
    }

    // MARK: - Actions
    @objc private func handleBiographyToggle() {
        bioToggledSubject.send(())
    }

    @objc private func handleEventsTapped() {
        eventsTappedSubject.send(())
    }
}

// MARK: - UIScrollViewDelegate
extension ILTempleViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        heroView.update(contentOffsetY: scrollView.contentOffset.y)
        updateHeaderAppearance()
    }
}

// MARK: - Leaf Views

/// 1 ô trong lưới "Niên đại · Cấp di tích · Hệ phái · Vùng miền" — nhãn nhỏ + giá trị Lora lớn.
private final class ILTempleFactTileView: UIView {
    init(model: ILTempleFactModel) {
        super.init(frame: .zero)
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusField
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let labelView = UILabel()
        labelView.font = ILTypography.label
        labelView.textColor = ILColors.inkFaint
        labelView.text = model.label

        let valueLabel = UILabel()
        valueLabel.font = ILTypography.scriptureBodySmall
        valueLabel.textColor = ILColors.ink
        valueLabel.numberOfLines = 2
        valueLabel.text = model.value

        let stack = UIStackView(arrangedSubviews: [labelView, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 1 ô "Tiện ích" — dấu ✓ xanh (có) hoặc vòng rỗng (không có) + nhãn + ghi chú.
private final class ILTempleAmenityTileView: UIView {
    init(model: ILTempleAmenityModel) {
        super.init(frame: .zero)
        backgroundColor = model.isAvailable ? ILColors.surface : .clear
        layer.cornerRadius = ILMetrics.radiusField
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let badge = UIView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 16),
            badge.heightAnchor.constraint(equalToConstant: 16)
        ])
        if model.isAvailable {
            badge.backgroundColor = ILColors.green
            let check = UILabel()
            check.text = "✓"
            check.font = ILTypography.beVietnamPro(size: 10, weight: .semibold)
            check.textColor = .white
            check.textAlignment = .center
            check.translatesAutoresizingMaskIntoConstraints = false
            badge.addSubview(check)
            NSLayoutConstraint.activate([
                check.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
                check.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
            ])
        } else {
            badge.backgroundColor = .clear
            badge.layer.borderWidth = 1
            badge.layer.borderColor = ILColors.borderStrong.cgColor
        }

        let labelView = UILabel()
        labelView.font = ILTypography.bodySmallMedium
        labelView.textColor = ILColors.ink
        labelView.text = model.label

        let headerRow = UIStackView(arrangedSubviews: [badge, labelView])
        headerRow.axis = .horizontal
        headerRow.spacing = 6
        headerRow.alignment = .center

        let valueLabel = UILabel()
        valueLabel.font = ILTypography.label
        valueLabel.textColor = ILColors.inkTertiary
        valueLabel.numberOfLines = 2
        valueLabel.text = model.value

        let stack = UIStackView(arrangedSubviews: [headerRow, valueLabel])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 1 hàng "khóa · giá trị" dùng chung cho "Tổ chức & truyền thừa" và "Vị trí & liên hệ" — nhãn cố
/// định 96pt bên trái, giá trị (hoặc "Đang cập nhật" nghiêng mờ) bên phải, gạch chia dưới trừ hàng
/// cuối, chevron tùy chọn khi có thể chạm.
private final class ILTempleKeyValueRow: UIControl {
    var onTap: (() -> Void)? {
        didSet { isUserInteractionEnabled = onTap != nil }
    }

    init(label: String, value: String, isMuted: Bool, showsDivider: Bool, showsChevron: Bool = false) {
        super.init(frame: .zero)

        let labelView = UILabel()
        labelView.font = ILTypography.label
        labelView.textColor = ILColors.inkFaint
        labelView.text = label
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        labelView.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.font = isMuted ? ILTypography.bodySmall : ILTypography.body
        valueLabel.textColor = isMuted ? ILColors.inkFaint : (showsChevron ? ILColors.link : ILColors.ink)
        if isMuted {
            let descriptor = valueLabel.font.fontDescriptor.withSymbolicTraits(.traitItalic)
            if let descriptor { valueLabel.font = UIFont(descriptor: descriptor, size: valueLabel.font.pointSize) }
        }
        valueLabel.text = value
        valueLabel.numberOfLines = showsChevron ? 1 : 0
        valueLabel.lineBreakMode = showsChevron ? .byTruncatingTail : .byWordWrapping
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentRow = UIStackView(arrangedSubviews: [labelView, valueLabel])
        contentRow.axis = .horizontal
        contentRow.spacing = 12
        contentRow.alignment = .firstBaseline
        contentRow.isUserInteractionEnabled = false
        contentRow.translatesAutoresizingMaskIntoConstraints = false
        labelView.widthAnchor.constraint(equalToConstant: 96).isActive = true

        if showsChevron {
            let chevron = UILabel()
            chevron.font = ILTypography.chevron
            chevron.textColor = ILColors.inkTertiary
            chevron.text = "›"
            chevron.setContentHuggingPriority(.required, for: .horizontal)
            contentRow.addArrangedSubview(chevron)
        }

        let divider = UIView()
        divider.backgroundColor = ILColors.borderSoft
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isHidden = !showsDivider

        addSubview(contentRow)
        addSubview(divider)
        NSLayoutConstraint.activate([
            contentRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentRow.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            contentRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),

            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onTap?()
    }
}

/// 1 thẻ điểm nổi bật trong "Kiến trúc & di sản" — chấm vàng + nội dung.
private final class ILTempleHighlightCardView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        backgroundColor = ILColors.surface
        layer.cornerRadius = ILMetrics.radiusField
        layer.borderWidth = 1
        layer.borderColor = ILColors.border.cgColor

        let dot = UIView()
        dot.backgroundColor = ILColors.gold
        dot.layer.cornerRadius = 3
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6)
        ])

        let label = UILabel()
        label.font = ILTypography.bodySmall
        label.textColor = ILColors.ink
        label.numberOfLines = 0
        label.text = text

        let row = UIStackView(arrangedSubviews: [dot, label])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 1 hàng "Lưu ý khi viếng thăm" đánh số ("01", "02"...).
private final class ILTempleRuleRow: UIStackView {
    init(model: ILTempleRuleModel) {
        super.init(frame: .zero)

        let numberLabel = UILabel()
        numberLabel.font = ILTypography.beVietnamPro(size: 11, weight: .medium)
        numberLabel.textColor = ILColors.link
        numberLabel.text = model.number
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.widthAnchor.constraint(equalToConstant: 16).isActive = true

        let textLabel = UILabel()
        textLabel.font = ILTypography.bodySmall
        textLabel.textColor = ILColors.templeHeaderInk
        textLabel.numberOfLines = 0
        textLabel.text = model.text

        axis = .horizontal
        spacing = 12
        alignment = .top
        addArrangedSubview(numberLabel)
        addArrangedSubview(textLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
