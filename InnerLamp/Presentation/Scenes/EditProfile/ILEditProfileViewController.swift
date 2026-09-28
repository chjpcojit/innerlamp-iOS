//
//  ILEditProfileViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILEditProfileViewController: BaseViewController {

    private enum Layout {
        static let avatarTop: CGFloat = 24
        static let sectionGap: CGFloat = 22
        static let visibilityTitleGap: CGFloat = 12
        static let navBarBottomGap: CGFloat = 10
    }

    // MARK: - Properties
    private let viewModel: ILEditProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let saveTappedSubject = PassthroughSubject<Void, Never>()
    private let changeAvatarTappedSubject = PassthroughSubject<Void, Never>()
    private let displayNameChangedSubject = PassthroughSubject<String, Never>()
    private let templeNameChangedSubject = PassthroughSubject<String, Never>()
    private let bioChangedSubject = PassthroughSubject<String, Never>()
    private let visibilityTappedSubject = PassthroughSubject<ILEditProfileVisibilityItem, Never>()
    private let changePasswordTappedSubject = PassthroughSubject<Void, Never>()
    private let deleteAccountTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView = ILNavBar(
        title: "editProfile.header.title".localized,
        rightActionTitle: "common.save".localized
    )

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    private lazy var avatarView = ILEditProfileAvatarView()

    private lazy var displayNameCard: ILInputCardView = {
        let card = ILInputCardView(label: "editProfile.field.displayName".localized)
        card.placeholder = "editProfile.field.displayName.placeholder".localized
        return card
    }()

    private lazy var phoneCard: ILInputCardView = {
        // Phone is the login identity — changing it needs OTP re-verification, so read-only here.
        let card = ILInputCardView(label: "editProfile.field.phone".localized, isEditable: false)
        card.keyboardType = .phonePad
        return card
    }()

    private lazy var templeCard: ILInputCardView = {
        let card = ILInputCardView(label: "editProfile.field.temple".localized)
        card.placeholder = "editProfile.field.temple.placeholder".localized
        return card
    }()

    private lazy var bioCard: ILInputCardView = {
        let card = ILInputCardView(label: "editProfile.field.bio".localized, style: .multiLine)
        card.placeholder = "editProfile.field.bio.placeholder".localized
        return card
    }()

    private lazy var visibilityTitleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.sectionTitle
        label.textColor = ILColors.ink
        label.text = "editProfile.visibility.title".localized
        return label
    }()

    private lazy var visibilityCard = ILEditProfileVisibilityCardView()
    private lazy var dangerZoneView = ILEditProfileDangerZoneView()

    // MARK: - Initializer
    init(viewModel: ILEditProfileViewModel) {
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
        // Edit Profile is a child screen without the bottom nav (per design handoff).
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvasWarm

        [headerView, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [
            avatarView,
            displayNameCard, phoneCard, templeCard, bioCard,
            visibilityTitleLabel, visibilityCard,
            dangerZoneView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }

        contentStack.setCustomSpacing(Layout.sectionGap, after: avatarView)
        contentStack.setCustomSpacing(Layout.sectionGap, after: bioCard)
        contentStack.setCustomSpacing(Layout.visibilityTitleGap, after: visibilityTitleLabel)
        contentStack.setCustomSpacing(Layout.sectionGap, after: visibilityCard)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in
            self?.view.endEditing(true)
            self?.saveTappedSubject.send(())
        }
        avatarView.onChangeAvatar = { [weak self] in self?.changeAvatarTappedSubject.send(()) }

        displayNameCard.onTextChanged = { [weak self] text in self?.displayNameChangedSubject.send(text) }
        templeCard.onTextChanged = { [weak self] text in self?.templeNameChangedSubject.send(text) }
        bioCard.onTextChanged = { [weak self] text in self?.bioChangedSubject.send(text) }

        visibilityCard.onItemTap = { [weak self] item in self?.visibilityTappedSubject.send(item) }
        dangerZoneView.onChangePassword = { [weak self] in self?.changePasswordTappedSubject.send(()) }
        dangerZoneView.onDeleteAccount = { [weak self] in self?.deleteAccountTappedSubject.send(()) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: Layout.navBarBottomGap),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Layout.avatarTop),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILEditProfileViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher(),
            changeAvatarTapped: changeAvatarTappedSubject.eraseToAnyPublisher(),
            displayNameChanged: displayNameChangedSubject.eraseToAnyPublisher(),
            templeNameChanged: templeNameChangedSubject.eraseToAnyPublisher(),
            bioChanged: bioChangedSubject.eraseToAnyPublisher(),
            visibilityTapped: visibilityTappedSubject.eraseToAnyPublisher(),
            changePasswordTapped: changePasswordTappedSubject.eraseToAnyPublisher(),
            deleteAccountTapped: deleteAccountTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILEditProfileStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILEditProfileStateModel) {
        avatarView.configure(initials: model.initials)

        displayNameCard.text = model.displayName
        displayNameCard.errorText = model.displayNameError
        phoneCard.text = model.phoneNumber
        templeCard.text = model.templeName
        bioCard.text = model.bio

        visibilityCard.configure(
            streakTitle: model.streakVisibilityTitle,
            journalTitle: model.journalVisibilityTitle,
            offeringHistoryTitle: model.offeringHistoryVisibilityTitle
        )

        headerView.isUserInteractionEnabled = !model.isSaving
    }
}
