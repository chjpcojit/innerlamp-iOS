//
//  ILLanguageViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLanguageViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILLanguageViewModel
    private var cancellables = Set<AnyCancellable>()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let languageSelectedSubject = PassthroughSubject<ILAppLanguage, Never>()
    private let fontSizeSelectedSubject = PassthroughSubject<ILScriptureFontSize, Never>()
    private let themeSelectedSubject = PassthroughSubject<ILSettingsThemeMode, Never>()

    private var languageRows: [ILLanguageOptionRowView] = []
    private var themeTiles: [ILLanguageThemeTileView] = []
    private var renderedLanguages: [ILAppLanguage] = []
    private var renderedThemes: [ILSettingsThemeMode] = []

    // MARK: - UI Elements
    private lazy var headerView = ILNavBar(title: "language.header.title".localized)

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

    private lazy var languageEyebrow = ILSectionEyebrowView(title: "language.section.language".localized)
    private lazy var languageStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.rowSpacing - 1
        return stack
    }()

    private lazy var fontSizeEyebrow = ILSectionEyebrowView(title: "language.section.fontSize".localized)
    private lazy var fontSizeCard = ILLanguageFontSizeCardView()

    private lazy var themeEyebrow = ILSectionEyebrowView(title: "language.section.theme".localized)
    private lazy var themeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = ILMetrics.rowSpacing
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILLanguageViewModel) {
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
        // Child of Settings: no bottom nav bar (per design handoff) — hide the tab's bar.
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
            languageEyebrow, languageStack,
            fontSizeEyebrow, fontSizeCard,
            themeEyebrow, themeStack
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }

        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 3, after: languageEyebrow)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 4, after: languageStack)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 3, after: fontSizeEyebrow)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 4, after: fontSizeCard)
        contentStack.setCustomSpacing(ILMetrics.spaceMedium - 3, after: themeEyebrow)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        fontSizeCard.onSelect = { [weak self] fontSize in self?.fontSizeSelectedSubject.send(fontSize) }
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

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium + 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLanguageViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            languageSelected: languageSelectedSubject.eraseToAnyPublisher(),
            fontSizeSelected: fontSizeSelectedSubject.eraseToAnyPublisher(),
            themeSelected: themeSelectedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main, and deferring it
        // renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILLanguageStateModel>) {
        switch state {
        case .idle, .loading, .failure:
            // Preferences are local — there is no loading or error branch.
            break
        case .success(let model):
            updateUI(with: model)
        }
    }

    private func updateUI(with model: ILLanguageStateModel) {
        if renderedLanguages != model.languageOptions.map(\.language) {
            languageRows.forEach { $0.removeFromSuperview() }
            languageRows = model.languageOptions.map { option in
                let row = ILLanguageOptionRowView()
                row.onTap = { [weak self] in self?.languageSelectedSubject.send(option.language) }
                languageStack.addArrangedSubview(row)
                return row
            }
            renderedLanguages = model.languageOptions.map(\.language)
        }
        zip(languageRows, model.languageOptions).forEach { row, option in
            row.configure(title: option.title, subtitle: option.subtitle, isSelected: option.isSelected)
        }

        fontSizeCard.configure(
            options: model.fontSizeOptions,
            previewText: model.previewText,
            previewFontIndex: model.previewFontIndex
        )

        if renderedThemes != model.themeOptions.map(\.theme) {
            themeTiles.forEach { $0.removeFromSuperview() }
            themeTiles = model.themeOptions.map { option in
                let tile = ILLanguageThemeTileView(theme: option.theme)
                tile.onTap = { [weak self] in self?.themeSelectedSubject.send(option.theme) }
                themeStack.addArrangedSubview(tile)
                return tile
            }
            renderedThemes = model.themeOptions.map(\.theme)
        }
        zip(themeTiles, model.themeOptions).forEach { tile, option in
            tile.configure(title: option.title, isSelected: option.isSelected)
        }
    }
}
