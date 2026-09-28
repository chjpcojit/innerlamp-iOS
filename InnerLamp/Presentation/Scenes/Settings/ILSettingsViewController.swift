//
//  ILSettingsViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILSettingsViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILSettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let profileTappedSubject = PassthroughSubject<Void, Never>()
    private let bellToggleChangedSubject = PassthroughSubject<Bool, Never>()
    private let fastDayToggleChangedSubject = PassthroughSubject<Bool, Never>()
    private let bellSoundTappedSubject = PassthroughSubject<Void, Never>()
    private let fontScaleChangedSubject = PassthroughSubject<Double, Never>()
    private let bilingualToggleChangedSubject = PassthroughSubject<Bool, Never>()
    private let darkModeTappedSubject = PassthroughSubject<Void, Never>()
    private let downloadsTappedSubject = PassthroughSubject<Void, Never>()
    private let languageTappedSubject = PassthroughSubject<Void, Never>()
    private let helpTappedSubject = PassthroughSubject<Void, Never>()
    private let hideJournalToggleChangedSubject = PassthroughSubject<Bool, Never>()
    private let exportDataTappedSubject = PassthroughSubject<Void, Never>()
    private let offlineTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView = ILNavBar(title: "settings.header.title".localized)

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    private lazy var accountCardView = ILSettingsAccountCardView()
    private lazy var scheduleEyebrow = ILSectionEyebrowView(title: "settings.section.schedule".localized)
    private lazy var scheduleCard = ILSettingsScheduleCardView()
    private lazy var displayEyebrow = ILSectionEyebrowView(title: "settings.section.display".localized)
    private lazy var displayCard = ILSettingsDisplayCardView()
    private lazy var contentEyebrow = ILSectionEyebrowView(title: "settings.section.content".localized)
    private lazy var contentCard = ILSettingsContentCardView()
    private lazy var privacyEyebrow = ILSectionEyebrowView(title: "settings.section.privacy".localized)
    private lazy var privacyCard = ILSettingsPrivacyCardView()

    private lazy var footerButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.label
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.setTitleColor(ILColors.inkMuted, for: .normal)
        button.addTarget(self, action: #selector(handleOfflineTap), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializer
    init(viewModel: ILSettingsViewModel) {
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
        // Cài đặt là màn con không hiện thanh điều hướng đáy (theo design handoff) — che bar của tab.
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        [headerView, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [
            accountCardView, scheduleEyebrow, scheduleCard,
            displayEyebrow, displayCard,
            contentEyebrow, contentCard,
            privacyEyebrow, privacyCard, footerButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }

        // Khoảng cách giữa các nhóm lớn hơn khoảng cách hàng (mặc định `rowSpacing` cho eyebrow→card).
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: accountCardView)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: scheduleCard)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: displayCard)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: contentCard)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: privacyCard)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        accountCardView.onTap = { [weak self] in self?.profileTappedSubject.send(()) }

        scheduleCard.onBellToggle = { [weak self] value in self?.bellToggleChangedSubject.send(value) }
        scheduleCard.onFastDayToggle = { [weak self] value in self?.fastDayToggleChangedSubject.send(value) }
        scheduleCard.onBellSoundTap = { [weak self] in self?.bellSoundTappedSubject.send(()) }

        displayCard.onFontScaleChanged = { [weak self] value in self?.fontScaleChangedSubject.send(value) }
        displayCard.onBilingualToggle = { [weak self] value in self?.bilingualToggleChangedSubject.send(value) }
        displayCard.onDarkModeTap = { [weak self] in self?.darkModeTappedSubject.send(()) }

        contentCard.onDownloadsTap = { [weak self] in self?.downloadsTappedSubject.send(()) }
        contentCard.onLanguageTap = { [weak self] in self?.languageTappedSubject.send(()) }
        contentCard.onHelpTap = { [weak self] in self?.helpTappedSubject.send(()) }

        privacyCard.onHideJournalToggle = { [weak self] value in self?.hideJournalToggleChangedSubject.send(value) }
        privacyCard.onExportTap = { [weak self] in self?.exportDataTappedSubject.send(()) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -(ILMetrics.screenPadding.bottom)),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILSettingsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            profileTapped: profileTappedSubject.eraseToAnyPublisher(),
            bellToggleChanged: bellToggleChangedSubject.eraseToAnyPublisher(),
            fastDayToggleChanged: fastDayToggleChangedSubject.eraseToAnyPublisher(),
            bellSoundTapped: bellSoundTappedSubject.eraseToAnyPublisher(),
            fontScaleChanged: fontScaleChangedSubject.eraseToAnyPublisher(),
            bilingualToggleChanged: bilingualToggleChangedSubject.eraseToAnyPublisher(),
            darkModeTapped: darkModeTappedSubject.eraseToAnyPublisher(),
            downloadsTapped: downloadsTappedSubject.eraseToAnyPublisher(),
            languageTapped: languageTappedSubject.eraseToAnyPublisher(),
            helpTapped: helpTappedSubject.eraseToAnyPublisher(),
            hideJournalToggleChanged: hideJournalToggleChangedSubject.eraseToAnyPublisher(),
            exportDataTapped: exportDataTappedSubject.eraseToAnyPublisher(),
            offlineTapped: offlineTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILSettingsStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure:
            // Cài đặt hiện là dữ liệu cục bộ, không có nhánh lỗi mạng.
            break
        }
    }

    private func updateUI(with model: ILSettingsStateModel) {
        accountCardView.configure(
            initial: model.accountInitial,
            name: model.accountName,
            subtitle: model.accountSubtitle
        )

        scheduleCard.configure(
            bellEnabled: model.bellEnabled,
            bellScheduleText: model.bellScheduleText,
            fastDayReminderEnabled: model.fastDayReminderEnabled,
            bellSoundTitle: model.bellSoundTitle
        )

        displayCard.configure(
            fontScale: model.scriptureFontScale,
            bilingualEnabled: model.bilingualEnabled,
            themeTitle: model.themeTitle
        )

        contentCard.configure(
            downloadsSummary: model.downloadsSummary,
            languageSummary: model.languageSummary
        )

        privacyCard.configure(hideJournalFromSangha: model.hideJournalFromSangha)

        let footerText = "\(model.versionText) · \("settings.footer.legal".localized)\n\("settings.footer.offline".localized)"
        footerButton.setTitle(footerText, for: .normal)
    }

    // MARK: - Actions
    @objc private func handleOfflineTap() {
        offlineTappedSubject.send(())
    }
}
