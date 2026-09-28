//
//  ILLunarDayDetailViewController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import UIKit
import Combine

final class ILLunarDayDetailViewController: BaseViewController {

    /// Ngưỡng cuộn để header trong suốt chuyển sang nền đặc (khớp design handoff "cuộn quá 110px").
    private static let headerSolidThreshold: CGFloat = 110

    // MARK: - Properties
    private let viewModel: ILLunarDayDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()

    private var isHeaderSolid = false

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerContainer = UIView()
    private let navBar = ILNavBar(showBack: true)

    private let heroView = ILLunarDayDetailHeroView()
    private let infoCardView = ILLunarDayDetailInfoCardView()
    private let almanacView = ILLunarDayDetailAlmanacView()
    private let elementsTitleLabel = UILabel()
    private let elementsView = ILLunarDayDetailElementsView()
    private let verseCardView = ILLunarDayDetailVerseCardView()

    private let goodHoursTitleLabel = UILabel()
    private let goodHoursView = ILLunarDayDetailGoodHoursView()

    private let clashTitleLabel = UILabel()
    private let clashView = ILLunarDayDetailClashView()

    private let directionsTitleLabel = UILabel()
    private let directionsView = ILLunarDayDetailDirectionsView()

    // MARK: - Initializer
    init(viewModel: ILLunarDayDetailViewModel) {
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

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        navBar.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerContainer.addSubview(navBar)

        [goodHoursTitleLabel, clashTitleLabel, directionsTitleLabel, elementsTitleLabel].forEach {
            $0.font = ILTypography.bodyMedium
            $0.textColor = ILColors.ink
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.addSubview(contentView)

        [
            heroView, infoCardView,
            almanacView,
            elementsTitleLabel, elementsView,
            verseCardView,
            goodHoursTitleLabel, goodHoursView,
            clashTitleLabel, clashView,
            directionsTitleLabel, directionsView
        ].forEach { contentView.addSubview($0) }

        view.addSubview(scrollView)
        view.addSubview(headerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            scrollView, contentView, headerContainer, navBar,
            heroView, infoCardView,
            almanacView,
            elementsTitleLabel, elementsView,
            verseCardView,
            goodHoursTitleLabel, goodHoursView,
            clashTitleLabel, clashView,
            directionsTitleLabel, directionsView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Hero full-bleed nằm trên cùng nội dung cuộn.
            heroView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            infoCardView.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: 6),
            infoCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            infoCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            // Thẻ "Ngày [Cát/Hung]" — thẻ độc lập, không có tiêu đề section.
            almanacView.topAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: 22),
            almanacView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            almanacView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            elementsTitleLabel.topAnchor.constraint(equalTo: almanacView.bottomAnchor, constant: 26),
            elementsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            elementsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            elementsView.topAnchor.constraint(equalTo: elementsTitleLabel.bottomAnchor, constant: 12),
            elementsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            elementsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            verseCardView.topAnchor.constraint(equalTo: elementsView.bottomAnchor, constant: 22),
            verseCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            verseCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            goodHoursTitleLabel.topAnchor.constraint(equalTo: verseCardView.bottomAnchor, constant: 26),
            goodHoursTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            goodHoursTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            goodHoursView.topAnchor.constraint(equalTo: goodHoursTitleLabel.bottomAnchor, constant: 12),
            goodHoursView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            goodHoursView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            clashTitleLabel.topAnchor.constraint(equalTo: goodHoursView.bottomAnchor, constant: 26),
            clashTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            clashTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            clashView.topAnchor.constraint(equalTo: clashTitleLabel.bottomAnchor, constant: 12),
            clashView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            clashView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            directionsTitleLabel.topAnchor.constraint(equalTo: clashView.bottomAnchor, constant: 26),
            directionsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            directionsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),

            directionsView.topAnchor.constraint(equalTo: directionsTitleLabel.bottomAnchor, constant: 12),
            directionsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontal),
            directionsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontal),
            directionsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -36),

            // Header ‹ đè lên hero, nền chuyển trong suốt → đặc khi cuộn.
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            navBar.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: horizontal),
            navBar.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -horizontal),
            navBar.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -ILMetrics.spaceSmall)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLunarDayDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILLunarDayDetailStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILLunarDayDetailStateModel) {
        heroView.configure(
            eyebrowText: model.eyebrowText,
            day: model.heroDay,
            month: model.heroMonth,
            year: model.heroYear,
            solar: model.heroSolar,
            typeTone: model.typeTone,
            typeText: model.typeLabel,
            adviceText: model.adviceText
        )

        infoCardView.rows = model.infoRows

        almanacView.configure(model.almanac)

        elementsTitleLabel.text = model.elementsTitle
        elementsView.configure(
            napamLine: model.napamLine,
            napamElement: model.napamElement,
            elements: model.elements
        )

        verseCardView.verseLines = model.verseLines
        verseCardView.verseSource = model.verseSource

        goodHoursTitleLabel.text = model.goodHoursTitle
        goodHoursView.hours = model.goodHours

        clashTitleLabel.text = model.clashTitle
        clashView.items = model.clashItems
        clashView.note = model.clashNote

        directionsTitleLabel.text = model.directionsTitle
        directionsView.directions = model.directions
    }
}

// MARK: - UIScrollViewDelegate
extension ILLunarDayDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let solid = scrollView.contentOffset.y > Self.headerSolidThreshold
        guard solid != isHeaderSolid else { return }
        isHeaderSolid = solid
        UIView.animate(withDuration: 0.2) {
            self.headerContainer.backgroundColor = solid ? ILColors.canvas : .clear
        }
    }
}
