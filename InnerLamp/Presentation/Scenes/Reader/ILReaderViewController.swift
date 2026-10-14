//
//  ILReaderViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILReaderViewController: BaseViewController {

    // MARK: - Constants
    private static let contentHorizontalInset: CGFloat = 22
    /// The current line settles at 38% of the visible list height (design `clientHeight * 0.38`).
    private static let scrollAnchorRatio: CGFloat = 0.38
    /// Extra scrollable space below the last line (design `padding-bottom: 40vh`).
    private static let bottomInsetRatio: CGFloat = 0.4
    private static let estimatedRowHeight: CGFloat = 44

    // MARK: - Properties
    private let viewModel: ILReaderViewModel
    private var cancellables = Set<AnyCancellable>()
    private var state = ILReaderStateModel.initial
    private var hasRenderedState = false

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let settingsTappedSubject = PassthroughSubject<Void, Never>()
    private let autoScrollToggledSubject = PassthroughSubject<Void, Never>()
    private let contentTappedSubject = PassthroughSubject<Void, Never>()
    private let playPauseTappedSubject = PassthroughSubject<Void, Never>()
    private let seekBackTappedSubject = PassthroughSubject<Void, Never>()
    private let seekForwardTappedSubject = PassthroughSubject<Void, Never>()
    private let speedSelectedSubject = PassthroughSubject<Double, Never>()
    private let fontSizeSelectedSubject = PassthroughSubject<Int, Never>()
    private let themeSelectedSubject = PassthroughSubject<Int, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let v = UIView()
        return v
    }()
    private lazy var headerBorder: UIView = {
        let v = UIView()
        return v
    }()
    private lazy var headerView: ILNavBar = {
        let v = ILNavBar(showBack: true)
        return v
    }()
    private lazy var autoScrollRow: ILReaderAutoScrollRowView = {
        let v = ILReaderAutoScrollRowView()
        return v
    }()
    private lazy var settingsPanel: ILReaderSettingsPanelView = {
        let v = ILReaderSettingsPanelView()
        return v
    }()
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerView, autoScrollRow, settingsPanel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(12, after: autoScrollRow)
        return stack
    }()

    private lazy var tableView: UITableView = {
        let v = UITableView(frame: .zero, style: .plain)
        v.backgroundColor = .clear
        v.separatorStyle = .none
        v.showsVerticalScrollIndicator = false
        v.allowsSelection = false
        v.rowHeight = UITableView.automaticDimension
        v.estimatedRowHeight = Self.estimatedRowHeight
        v.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: ILMetrics.screenHorizontal))
        v.register(ILReaderLineCell.self, forCellReuseIdentifier: ILReaderLineCell.reuseIdentifier)
        v.register(ILReaderHeadingCell.self, forCellReuseIdentifier: ILReaderHeadingCell.reuseIdentifier)
        return v
    }()
    private lazy var legendFooter: UIView = {
        let v = UIView()
        v.frame = CGRect(x: 0, y: 0, width: 0, height: 26 + 16)
        return v
    }()
    private lazy var legendBellLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        return v
    }()
    private lazy var legendKnockLabel: UILabel = {
        let v = UILabel()
        v.font = ILTypography.label
        return v
    }()
    private lazy var controlsView: ILReaderControlsView = {
        let v = ILReaderControlsView()
        return v
    }()

    // MARK: - Initializer
    init(viewModel: ILReaderViewModel) {
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
        // "Màn hình luôn sáng" — keep the screen on while chanting.
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomInset = tableView.bounds.height * Self.bottomInsetRatio
        if tableView.contentInset.bottom != bottomInset {
            tableView.contentInset.bottom = bottomInset
        }
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onAction = { [weak self] in self?.settingsTappedSubject.send(()) }
        autoScrollRow.onToggle = { [weak self] in self?.autoScrollToggledSubject.send(()) }
        settingsPanel.onFontSizeSelect = { [weak self] index in self?.fontSizeSelectedSubject.send(index) }
        settingsPanel.onThemeSelect = { [weak self] index in self?.themeSelectedSubject.send(index) }

        controlsView.onPlayPauseTap = { [weak self] in self?.playPauseTappedSubject.send(()) }
        controlsView.onSeekBackTap = { [weak self] in self?.seekBackTappedSubject.send(()) }
        controlsView.onSeekForwardTap = { [weak self] in self?.seekForwardTappedSubject.send(()) }
        controlsView.onSpeedSelect = { [weak self] speed in self?.speedSelectedSubject.send(speed) }

        tableView.dataSource = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleContentTap))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        setupLegendFooter()

        headerContainer.addSubview(headerStack)
        headerContainer.addSubview(headerBorder)
        view.addSubview(tableView)
        view.addSubview(headerContainer)
        view.addSubview(controlsView)
    }

    private func setupLegendFooter() {
        let stack = UIStackView(arrangedSubviews: [legendBellLabel, legendKnockLabel])
        stack.axis = .horizontal
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        legendFooter.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: legendFooter.centerXAnchor),
            stack.topAnchor.constraint(equalTo: legendFooter.topAnchor, constant: 26)
        ])
        tableView.tableFooterView = legendFooter
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerContainer, headerStack, headerBorder, tableView, controlsView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: horizontal),
            headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -horizontal),
            headerStack.bottomAnchor.constraint(equalTo: headerBorder.topAnchor, constant: -ILMetrics.rowSpacing),

            headerBorder.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerBorder.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerBorder.heightAnchor.constraint(equalToConstant: 1),
            headerBorder.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.contentHorizontalInset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.contentHorizontalInset),
            tableView.bottomAnchor.constraint(equalTo: controlsView.topAnchor),

            controlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILReaderViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            settingsTapped: settingsTappedSubject.eraseToAnyPublisher(),
            autoScrollToggled: autoScrollToggledSubject.eraseToAnyPublisher(),
            contentTapped: contentTappedSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            seekBackTapped: seekBackTappedSubject.eraseToAnyPublisher(),
            seekForwardTapped: seekForwardTappedSubject.eraseToAnyPublisher(),
            speedSelected: speedSelectedSubject.eraseToAnyPublisher(),
            fontSizeSelected: fontSizeSelectedSubject.eraseToAnyPublisher(),
            themeSelected: themeSelectedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    @objc private func handleContentTap() {
        contentTappedSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILReaderStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILReaderStateModel) {
        let previous = state
        let isFirstRender = !hasRenderedState
        state = model
        hasRenderedState = true

        let palette = ILReaderPalette.palette(forThemeIndex: model.themeIndex)
        overrideUserInterfaceStyle = palette.interfaceStyle
        view.backgroundColor = palette.background
        headerContainer.backgroundColor = palette.background
        headerBorder.backgroundColor = palette.line
        legendBellLabel.text = model.legendBellText
        legendKnockLabel.text = model.legendKnockText
        legendBellLabel.textColor = palette.subtle
        legendKnockLabel.textColor = palette.subtle

        headerView.title = model.title
        headerView.subtitle = model.statusText
        headerView.rightActionTitle = model.fontSizeActionTitle
        autoScrollRow.configure(with: model, palette: palette)
        settingsPanel.configure(with: model, palette: palette)
        setSettingsPanelVisible(model.isSettingsVisible, animated: !isFirstRender)
        controlsView.configure(with: model, palette: palette)

        let needsReload = isFirstRender
            || previous.themeIndex != model.themeIndex
            || previous.fontSizeIndex != model.fontSizeIndex
            || rowTexts(of: previous.rows) != rowTexts(of: model.rows)
        if needsReload {
            tableView.reloadData()
        } else {
            refreshChangedRows(from: previous.rows, to: model.rows, palette: palette)
        }

        if !isFirstRender,
           model.isAutoScrollEnabled,
           let row = model.currentRowIndex,
           row != previous.currentRowIndex {
            scrollToRow(row)
        }
    }

    private func setSettingsPanelVisible(_ isVisible: Bool, animated: Bool) {
        guard settingsPanel.isHidden == isVisible else { return }
        let changes = {
            self.settingsPanel.isHidden = !isVisible
            self.settingsPanel.alpha = isVisible ? 1 : 0
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }

    /// Visible text of each row — a change means the list structure differs and cells must reload.
    private func rowTexts(of rows: [ILReaderRowState]) -> [String] {
        rows.map { row in
            switch row {
            case .heading(let title): return title
            case .line(let line): return line.text + "\u{0}" + line.gloss + "\u{0}" + line.cueGlyph
            }
        }
    }

    /// Same structure, only the highlight moved: restyle the affected visible cells with a cross-fade.
    private func refreshChangedRows(from old: [ILReaderRowState], to new: [ILReaderRowState], palette: ILReaderPalette) {
        for (index, (oldRow, newRow)) in zip(old, new).enumerated() where oldRow != newRow {
            guard case .line(let line) = newRow,
                  let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ILReaderLineCell else {
                continue
            }
            cell.configure(with: line, fontSizeIndex: state.fontSizeIndex, palette: palette, animated: true)
        }
    }

    private func scrollToRow(_ row: Int) {
        let indexPath = IndexPath(row: row, section: 0)
        guard row < tableView.numberOfRows(inSection: 0) else { return }
        let rowRect = tableView.rectForRow(at: indexPath)
        let targetY = rowRect.minY - tableView.bounds.height * Self.scrollAnchorRatio
        let minY = -tableView.adjustedContentInset.top
        let maxY = max(minY, tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom)
        tableView.setContentOffset(CGPoint(x: 0, y: min(max(targetY, minY), maxY)), animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ILReaderViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let palette = ILReaderPalette.palette(forThemeIndex: state.themeIndex)
        switch state.rows[indexPath.row] {
        case .heading(let title):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ILReaderHeadingCell.reuseIdentifier, for: indexPath
            ) as? ILReaderHeadingCell ?? ILReaderHeadingCell(style: .default, reuseIdentifier: nil)
            cell.configure(title: title, palette: palette)
            return cell
        case .line(let line):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ILReaderLineCell.reuseIdentifier, for: indexPath
            ) as? ILReaderLineCell ?? ILReaderLineCell(style: .default, reuseIdentifier: nil)
            cell.configure(with: line, fontSizeIndex: state.fontSizeIndex, palette: palette, animated: false)
            return cell
        }
    }
}
