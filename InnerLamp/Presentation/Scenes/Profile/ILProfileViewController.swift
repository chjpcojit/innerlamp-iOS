//
//  ILProfileViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILProfileViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILProfileViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let editProfileTappedSubject = PassthroughSubject<Void, Never>()
    private let statsTappedSubject = PassthroughSubject<Void, Never>()
    private let awardsTappedSubject = PassthroughSubject<Void, Never>()
    private let offeringTappedSubject = PassthroughSubject<Void, Never>()
    private let premiumTappedSubject = PassthroughSubject<Void, Never>()
    private let reminderTappedSubject = PassthroughSubject<Void, Never>()
    private let settingsTappedSubject = PassthroughSubject<Void, Never>()
    private let notificationsTappedSubject = PassthroughSubject<Void, Never>()
    private let communityTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView = ILProfileHeaderView()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
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

    private lazy var premiumCard: ILProfilePremiumCardView = {
        let card = ILProfilePremiumCardView()
        card.title = "profile.premium.title".localized
        card.subtitle = "profile.premium.subtitle".localized
        return card
    }()

    private lazy var menuCard = ILProfileMenuCardView()

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

        [scrollView, headerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [statsCard, heatmapCard, badgesHeader, badgesRow, meritCard, premiumCard, menuCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: statsCard)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: heatmapCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 2, after: badgesHeader)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: badgesRow)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium, after: meritCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium, after: premiumCard)

        headerView.onEditTapped = { [weak self] in self?.editProfileTappedSubject.send(()) }
        heatmapCard.onTap = { [weak self] in self?.statsTappedSubject.send(()) }
        badgesHeader.onTrailingTap = { [weak self] in self?.awardsTappedSubject.send(()) }
        badgesRow.onTap = { [weak self] in self?.awardsTappedSubject.send(()) }
        meritCard.onTap = { [weak self] in self?.offeringTappedSubject.send(()) }
        premiumCard.onTap = { [weak self] in self?.premiumTappedSubject.send(()) }
        menuCard.onReminderTapped = { [weak self] in self?.reminderTappedSubject.send(()) }
        menuCard.onSettingsTapped = { [weak self] in self?.settingsTappedSubject.send(()) }
        menuCard.onNotificationsTapped = { [weak self] in self?.notificationsTappedSubject.send(()) }
        menuCard.onCommunityTapped = { [weak self] in self?.communityTappedSubject.send(()) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.groupSpacing + 2),
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
            offeringTapped: offeringTappedSubject.eraseToAnyPublisher(),
            premiumTapped: premiumTappedSubject.eraseToAnyPublisher(),
            reminderTapped: reminderTappedSubject.eraseToAnyPublisher(),
            settingsTapped: settingsTappedSubject.eraseToAnyPublisher(),
            notificationsTapped: notificationsTappedSubject.eraseToAnyPublisher(),
            communityTapped: communityTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Gửi sau khi đã subscribe ở trên, trong cùng 1 call đồng bộ — PassthroughSubject không
        // phát lại giá trị đã gửi trước khi có subscriber.
        viewDidLoadSubject.send(())
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
        headerView.configure(with: model.header)

        statsCard.configure(items: model.stats.map { .init(value: $0.value, caption: $0.caption) })

        if let heatmap = model.heatmap {
            heatmapCard.configure(with: heatmap)
        }
        heatmapCard.isHidden = model.heatmap == nil

        badgesHeader.trailingText = model.badgesLinkText
        badgesRow.configure(badges: model.badges)
        badgesHeader.isHidden = !model.hasBadges
        badgesRow.isHidden = !model.hasBadges

        meritCard.configure(summary: model.meritSummary)
        premiumCard.isHidden = !model.showsPremiumUpsell

        menuCard.configure(reminderValue: model.reminderValue, communityValue: model.communityValue)
    }
}
