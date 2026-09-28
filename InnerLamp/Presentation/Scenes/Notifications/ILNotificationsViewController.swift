//
//  ILNotificationsViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILNotificationsViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILNotificationsViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let closeTappedSubject = PassthroughSubject<Void, Never>()
    private let sitNowTappedSubject = PassthroughSubject<Void, Never>()
    private let skipTonightTappedSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Elements
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.canvas
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayMedium
        label.textColor = ILColors.ink
        label.text = "notifications.header.title".localized
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.note
        button.setTitle("notifications.header.close".localized, for: .normal)
        button.setTitleColor(ILColors.link, for: .normal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        return button
    }()

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

    private lazy var heroCard = ILNotificationsHeroCardView()
    private lazy var todayEyebrow = ILSectionEyebrowView(title: "notifications.section.today".localized)

    private lazy var listStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILNotificationsViewModel) {
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
        // Màn con không hiện thanh điều hướng đáy (theo design handoff) — che bar của tab.
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
        [titleLabel, closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [heroCard, todayEyebrow, listStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: heroCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 4, after: todayEyebrow)

        heroCard.onSitNow = { [weak self] in self?.sitNowTappedSubject.send(()) }
        heroCard.onSkip = { [weak self] in self?.skipTonightTappedSubject.send(()) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -ILMetrics.spaceMedium + 2),

            closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: ILMetrics.spaceSmall),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            closeButton.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILNotificationsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            closeTapped: closeTappedSubject.eraseToAnyPublisher(),
            sitNowTapped: sitNowTappedSubject.eraseToAnyPublisher(),
            skipTonightTapped: skipTonightTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILNotificationsStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure:
            // Thông báo hiện là dữ liệu mẫu cục bộ, không có nhánh lỗi mạng.
            break
        }
    }

    private func updateUI(with model: ILNotificationsStateModel) {
        if let hero = model.hero {
            heroCard.eyebrow = hero.eyebrow
            heroCard.title = hero.title
            heroCard.isHidden = false
        } else {
            heroCard.isHidden = true
        }

        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in model.items {
            let row = ILNotificationRowView()
            row.configure(with: item)
            listStack.addArrangedSubview(row)
        }
    }

    // MARK: - Actions
    @objc private func handleCloseTap() {
        closeTappedSubject.send(())
    }
}
