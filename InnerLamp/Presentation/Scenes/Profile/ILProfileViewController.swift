//
//  ILProfileViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILProfileViewController: BaseViewController, UIScrollViewDelegate {

    // MARK: - Properties
    private let viewModel: ILProfileViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let editProfileTappedSubject = PassthroughSubject<Void, Never>()
    private let statsTappedSubject = PassthroughSubject<Void, Never>()
    private let awardsTappedSubject = PassthroughSubject<Void, Never>()
    private let meritTappedSubject = PassthroughSubject<Void, Never>()
    private let donateTappedSubject = PassthroughSubject<Void, Never>()
    private let reminderTappedSubject = PassthroughSubject<Void, Never>()
    private let settingsTappedSubject = PassthroughSubject<Void, Never>()
    private let notificationsTappedSubject = PassthroughSubject<Void, Never>()
    private let familyTreeTappedSubject = PassthroughSubject<Void, Never>()
    private let createFamilyTreeTappedSubject = PassthroughSubject<Void, Never>()
    private let communityTappedSubject = PassthroughSubject<Void, Never>()
    private let logoutConfirmedSubject = PassthroughSubject<Void, Never>()

    /// Last model painted. `render` is called for every state emission (e.g. again once
    /// `GET /v1/users/me` answers); sections whose data did not change are left alone so their
    /// cells/cards are not torn down and rebuilt mid-scroll.
    private var renderedModel: ILProfileStateModel?

    // MARK: - UI Elements
    // Cover + avatar + name scroll with the content; the compact bar is pinned and fades in once the
    // header has scrolled away.
    private lazy var headerView = ILProfileHeaderView()
    private lazy var compactBar = ILProfileCompactBarView()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()

    private lazy var statsCard = ILStatSummaryCardView()

    private lazy var heatmapCard: ILProfileHeatmapCardView = {
        let card = ILProfileHeatmapCardView()
        card.title = "profile.heatmap.title".localized
        return card
    }()

    private lazy var badgesHeader = ILSectionHeaderView(title: "profile.badges.title".localized)
    private lazy var badgesRow = ILProfileBadgesRowView()

    private lazy var meritCard: ILProfileMeritCardView = {
        let card = ILProfileMeritCardView()
        card.title = "profile.merit.title".localized
        return card
    }()

    private lazy var donateCard: ILProfileDonateCardView = {
        let card = ILProfileDonateCardView()
        card.title = "profile.donate.title".localized
        card.subtitle = "profile.donate.subtitle".localized
        return card
    }()

    private lazy var menuCard = ILProfileMenuCardView()

    private lazy var logoutButton: ILProfileLogoutButtonView = {
        let button = ILProfileLogoutButtonView()
        button.title = "profile.logout.button".localized
        return button
    }()

    private lazy var versionFooter = ILProfileVersionFooterView()

    // MARK: - Initializer
    init(viewModel: ILProfileViewModel) {
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
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        compactBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(compactBar)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(headerView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [statsCard, heatmapCard, badgesHeader, badgesRow, meritCard, donateCard, menuCard, logoutButton, versionFooter].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: statsCard)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: heatmapCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 2, after: badgesHeader)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: badgesRow)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium, after: meritCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium, after: donateCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium, after: menuCard)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 4, after: logoutButton)

        heatmapCard.onTap = { [weak self] in self?.statsTappedSubject.send(()) }
        badgesHeader.onTrailingTap = { [weak self] in self?.awardsTappedSubject.send(()) }
        badgesRow.onTap = { [weak self] in self?.awardsTappedSubject.send(()) }
        meritCard.onTap = { [weak self] in self?.meritTappedSubject.send(()) }
        donateCard.onTap = { [weak self] in self?.donateTappedSubject.send(()) }
        menuCard.onReminderTapped = { [weak self] in self?.reminderTappedSubject.send(()) }
        menuCard.onSettingsTapped = { [weak self] in self?.settingsTappedSubject.send(()) }
        menuCard.onNotificationsTapped = { [weak self] in self?.notificationsTappedSubject.send(()) }
        menuCard.onEditProfileTapped = { [weak self] in self?.editProfileTappedSubject.send(()) }
        menuCard.onFamilyTreeTapped = { [weak self] in self?.familyTreeTappedSubject.send(()) }
        menuCard.onCreateFamilyTreeTapped = { [weak self] in self?.createFamilyTreeTappedSubject.send(()) }
        menuCard.onCommunityTapped = { [weak self] in self?.communityTappedSubject.send(()) }
        logoutButton.onTap = { [weak self] in self?.presentLogoutConfirmation() }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            compactBar.topAnchor.constraint(equalTo: view.topAnchor),
            compactBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            compactBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            headerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.groupSpacing + 2),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -(ILMetrics.bottomNavHeight + ILMetrics.groupSpacing)),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILProfileViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            editProfileTapped: editProfileTappedSubject.eraseToAnyPublisher(),
            statsTapped: statsTappedSubject.eraseToAnyPublisher(),
            awardsTapped: awardsTappedSubject.eraseToAnyPublisher(),
            meritTapped: meritTappedSubject.eraseToAnyPublisher(),
            donateTapped: donateTappedSubject.eraseToAnyPublisher(),
            reminderTapped: reminderTappedSubject.eraseToAnyPublisher(),
            settingsTapped: settingsTappedSubject.eraseToAnyPublisher(),
            notificationsTapped: notificationsTappedSubject.eraseToAnyPublisher(),
            familyTreeTapped: familyTreeTappedSubject.eraseToAnyPublisher(),
            createFamilyTreeTapped: createFamilyTreeTappedSubject.eraseToAnyPublisher(),
            communityTapped: communityTappedSubject.eraseToAnyPublisher(),
            logoutConfirmed: logoutConfirmedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        output.logoutError
            .sink { [weak self] message in self?.showError(message) }
            .store(in: &cancellables)

        // Gửi sau khi đã subscribe ở trên, trong cùng 1 call đồng bộ — PassthroughSubject không
        // phát lại giá trị đã gửi trước khi có subscriber.
        viewDidLoadSubject.send(())
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        headerView.update(contentOffsetY: offsetY)
        compactBar.update(contentOffsetY: offsetY)
    }

    // MARK: - Render
    private func render(state: ViewState<ILProfileStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure:
            // TODO: hiển thị ILStateView(.error / .offline) khi có API hồ sơ thật.
            break
        }
    }

    private func updateUI(with model: ILProfileStateModel) {
        let previous = renderedModel
        guard model != previous else { return }
        renderedModel = model

        /// `true` on the first paint (no previous model) and whenever `keyPath` actually changed.
        func changed<Value: Equatable>(_ keyPath: KeyPath<ILProfileStateModel, Value>) -> Bool {
            previous?[keyPath: keyPath] != model[keyPath: keyPath]
        }

        if changed(\.header) {
            headerView.configure(with: model.header)
            compactBar.configure(name: model.header.fullName)
        }

        if changed(\.stats) {
            statsCard.configure(items: model.stats.map { .init(value: $0.value, caption: $0.caption) })
        }

        if changed(\.heatmap) {
            if let heatmap = model.heatmap {
                heatmapCard.configure(with: heatmap)
            }
            heatmapCard.isHidden = model.heatmap == nil
        }

        if changed(\.badges) || changed(\.badgesLinkText) {
            badgesHeader.trailingText = model.badgesLinkText
            badgesRow.configure(badges: model.badges)
            badgesHeader.isHidden = !model.hasBadges
            badgesRow.isHidden = !model.hasBadges
        }

        if changed(\.meritSummary) {
            meritCard.configure(summary: model.meritSummary)
        }

        if changed(\.reminderValue) || changed(\.communityValue) {
            menuCard.configure(reminderValue: model.reminderValue, communityValue: model.communityValue)
        }

        if changed(\.versionText) || changed(\.buildText) {
            versionFooter.configure(versionText: model.versionText, buildText: model.buildText)
        }

        logoutButton.isEnabled = !model.isLoggingOut
    }

    // MARK: - Logout
    /// The popup is a presentation concern (like `ILAlertPresenter` toasts), so the view shows it;
    /// only the confirmed choice reaches the ViewModel.
    private func presentLogoutConfirmation() {
        ILAlertPresenter.shared.show(
            .confirm(
                title: "profile.logout.confirm.title".localized,
                message: "profile.logout.confirm.message".localized,
                cancel: ILAlertAction(title: "profile.logout.confirm.cancel".localized),
                confirm: ILAlertAction(title: "profile.logout.confirm.action".localized) { [weak self] in
                    self?.logoutConfirmedSubject.send(())
                }
            ),
            from: self
        )
    }
}
