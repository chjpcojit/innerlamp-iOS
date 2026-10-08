//
//  ILFamilyTreeViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILFamilyTreeViewController: BaseViewController, UIScrollViewDelegate {

    private typealias Tree = ILColors.FamilyTree
    private typealias Metrics = ILMetrics.FamilyTree

    // MARK: - Properties
    private let viewModel: ILFamilyTreeViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let searchToggledSubject = PassthroughSubject<Void, Never>()
    private let searchTextChangedSubject = PassthroughSubject<String, Never>()
    private let searchSubmittedSubject = PassthroughSubject<Void, Never>()
    private let generationSelectedSubject = PassthroughSubject<Int, Never>()
    private let memberTappedSubject = PassthroughSubject<String, Never>()
    private let sheetMemberTappedSubject = PassthroughSubject<String, Never>()
    private let sheetToggledSubject = PassthroughSubject<Void, Never>()
    private let sheetDismissedSubject = PassthroughSubject<Void, Never>()
    private let rootTappedSubject = PassthroughSubject<Void, Never>()
    private let meTappedSubject = PassthroughSubject<Void, Never>()
    private let createTappedSubject = PassthroughSubject<Void, Never>()
    private let joinTappedSubject = PassthroughSubject<Void, Never>()
    private let addTappedSubject = PassthroughSubject<Void, Never>()
    private let fullProfileTappedSubject = PassthroughSubject<Void, Never>()
    private let reminderTappedSubject = PassthroughSubject<Void, Never>()
    private let contextualActionTappedSubject = PassthroughSubject<Void, Never>()
    private let offeringTappedSubject = PassthroughSubject<Void, Never>()
    private let chantTappedSubject = PassthroughSubject<Void, Never>()
    private let templeTappedSubject = PassthroughSubject<Void, Never>()
    private let titleTappedSubject = PassthroughSubject<Void, Never>()
    private let switcherDismissedSubject = PassthroughSubject<Void, Never>()
    private let viewSelectedSubject = PassthroughSubject<ILFamilyTreeViewKind, Never>()
    private let chronicleTappedSubject = PassthroughSubject<Void, Never>()

    private var renderedLayout: ILFamilyTreeLayout?
    private var renderedNodes: [ILFamilyTreeNodeModel] = []
    private var pendingFocus: ILFamilyTreeFocusRequest?
    private var handledFocusToken: Int?
    private var hasCenteredOnce = false
    private var isSheetExpanded = false
    private var lastFocusedID: String?
    /// The user has panned / zoomed since the last programmatic focus — a later relayout must not
    /// pull the tree back under their finger.
    private var userHasMovedCanvas = false
    private var lastLaidOutCanvasHeight: CGFloat = 0
    private var isSwitcherPresented = false

    // MARK: - UI Elements
    private lazy var paperView = ILFamilyTreePaperView()

    private lazy var headerView = ILFamilyTreeHeaderView()

    private lazy var searchInput: ILFamilyTreeSearchFieldView = {
        let input = ILFamilyTreeSearchFieldView(placeholder: "familyTree.search.placeholder".localized)
        input.isHidden = true
        return input
    }()

    private lazy var chipScrollView = ILFamilyTreeChipRowView()

    /// Chip row with the design's 12pt top padding; hidden as a whole.
    private lazy var chipWrap: UIView = {
        let wrap = UIView()
        chipScrollView.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(chipScrollView)
        NSLayoutConstraint.activate([
            chipScrollView.topAnchor.constraint(equalTo: wrap.topAnchor, constant: Metrics.chipRowTopSpacing),
            chipScrollView.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            chipScrollView.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            chipScrollView.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            chipScrollView.heightAnchor.constraint(equalToConstant: Metrics.chipHeight)
        ])
        wrap.isHidden = true
        return wrap
    }()

    private lazy var legendView: ILFamilyTreeLegendView = {
        let legend = ILFamilyTreeLegendView()
        legend.isHidden = true
        return legend
    }()

    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerView, searchWrap, chipWrap, legendView])
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    private lazy var searchWrap: UIView = {
        let wrap = UIView()
        searchInput.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(searchInput)
        NSLayoutConstraint.activate([
            searchInput.topAnchor.constraint(equalTo: wrap.topAnchor, constant: Metrics.chipRowTopSpacing),
            searchInput.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            searchInput.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: Metrics.headerInset),
            searchInput.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -Metrics.headerInset)
        ])
        wrap.isHidden = true
        return wrap
    }()

    /// 1pt line between the header block and the canvas.
    private lazy var canvasTopBorder: UIView = {
        let line = UIView()
        line.backgroundColor = Tree.canvasTopBorder
        line.isUserInteractionEnabled = false
        return line
    }()

    private lazy var canvasArea: UIView = {
        let area = UIView()
        area.clipsToBounds = true
        return area
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.minimumZoomScale = Metrics.zoomLevels.first ?? 1
        scroll.maximumZoomScale = Metrics.zoomLevels.last ?? 1
        scroll.contentInset.bottom = Metrics.sheetScrollMargin
        scroll.delegate = self
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()

    private lazy var canvasView = ILFamilyTreeCanvasView()

    private lazy var zoomControls = ILFamilyTreeZoomControlsView()

    private lazy var scrimView: UIView = {
        let scrim = UIView()
        scrim.backgroundColor = Tree.scrim
        scrim.alpha = 0
        scrim.isHidden = true
        scrim.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleScrimTap)))
        return scrim
    }()

    private lazy var sheetView: ILFamilyTreeDetailSheetView = {
        let sheet = ILFamilyTreeDetailSheetView()
        sheet.isHidden = true
        return sheet
    }()

    private lazy var emptyStateView: ILFamilyTreeEmptyView = {
        let empty = ILFamilyTreeEmptyView()
        empty.isHidden = true
        empty.onCreateTap = { [weak self] in self?.createTappedSubject.send(()) }
        empty.onJoinTap = { [weak self] in self?.joinTappedSubject.send(()) }
        return empty
    }()

    private lazy var switcherView: ILFamilyTreeSwitcherView = {
        let switcher = ILFamilyTreeSwitcherView()
        switcher.isHidden = true
        switcher.alpha = 0
        switcher.onDismiss = { [weak self] in self?.switcherDismissedSubject.send(()) }
        switcher.onSelect = { [weak self] kind in self?.viewSelectedSubject.send(kind) }
        switcher.onChronicle = { [weak self] in self?.chronicleTappedSubject.send(()) }
        switcher.onCreate = { [weak self] in self?.createTappedSubject.send(()) }
        return switcher
    }()

    private lazy var sheetCollapsedConstraint = sheetView.heightAnchor.constraint(equalToConstant: Metrics.sheetCollapsedHeight)
    private lazy var sheetExpandedConstraint = sheetView.heightAnchor.constraint(
        equalTo: canvasArea.heightAnchor, multiplier: Metrics.sheetExpandedRatio
    )

    // MARK: - Initializer
    init(viewModel: ILFamilyTreeViewModel) {
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
        // Màn con không hiện thanh điều hướng đáy (theo design handoff).
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pushing a child form (create / add member / profile / chronicle) keeps the bar hidden;
        // only restore it when this screen is popped.
        guard isMovingFromParent else { return }
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCenteringInsets()
        recenterIfCanvasResized()
        applyPendingFocus()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = Tree.paperMid
        paperView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paperView)

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerView.onSearch = { [weak self] in self?.searchToggledSubject.send(()) }
        headerView.onAdd = { [weak self] in self?.addTappedSubject.send(()) }
        headerView.onSeal = { [weak self] in self?.chronicleTappedSubject.send(()) }
        headerView.onTitle = { [weak self] in self?.titleTappedSubject.send(()) }

        searchInput.onTextChanged = { [weak self] text in self?.searchTextChangedSubject.send(text) }
        searchInput.onReturn = { [weak self] in self?.searchSubmittedSubject.send(()) }
        chipScrollView.onSelect = { [weak self] generation in self?.generationSelectedSubject.send(generation) }

        canvasView.onMemberTapped = { [weak self] id in self?.memberTappedSubject.send(id) }
        scrollView.addSubview(canvasView)

        zoomControls.onZoomIn = { [weak self] in self?.stepZoom(by: 1) }
        zoomControls.onZoomOut = { [weak self] in self?.stepZoom(by: -1) }
        zoomControls.onRoot = { [weak self] in self?.rootTappedSubject.send(()) }
        zoomControls.onMe = { [weak self] in self?.meTappedSubject.send(()) }

        sheetView.onHeaderTap = { [weak self] in self?.sheetToggledSubject.send(()) }
        sheetView.onSwipeUp = { [weak self] in
            guard let self, !self.isSheetExpanded else { return }
            self.sheetToggledSubject.send(())
        }
        sheetView.onSwipeDown = { [weak self] in
            guard let self, self.isSheetExpanded else { return }
            self.sheetDismissedSubject.send(())
        }
        sheetView.onMemberTap = { [weak self] id in self?.sheetMemberTappedSubject.send(id) }
        sheetView.onFullProfileTap = { [weak self] in self?.fullProfileTappedSubject.send(()) }
        sheetView.onReminderTap = { [weak self] in self?.reminderTappedSubject.send(()) }
        sheetView.onContextualActionTap = { [weak self] in self?.contextualActionTappedSubject.send(()) }
        sheetView.onOfferingTap = { [weak self] in self?.offeringTappedSubject.send(()) }
        sheetView.onChantTap = { [weak self] in self?.chantTappedSubject.send(()) }
        sheetView.onTempleTap = { [weak self] in self?.templeTappedSubject.send(()) }

        [headerStack, canvasArea].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        [scrollView, emptyStateView, canvasTopBorder, zoomControls, scrimView, sheetView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            canvasArea.addSubview($0)
        }
        switcherView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switcherView)
        updateZoomControls()
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            paperView.topAnchor.constraint(equalTo: view.topAnchor),
            paperView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            paperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paperView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Metrics.headerTopPadding),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            canvasArea.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: Metrics.legendTopSpacing),
            canvasArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasArea.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: canvasArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: canvasArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: canvasArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: canvasArea.bottomAnchor),

            canvasTopBorder.topAnchor.constraint(equalTo: canvasArea.topAnchor),
            canvasTopBorder.leadingAnchor.constraint(equalTo: canvasArea.leadingAnchor),
            canvasTopBorder.trailingAnchor.constraint(equalTo: canvasArea.trailingAnchor),
            canvasTopBorder.heightAnchor.constraint(equalToConstant: 1),

            emptyStateView.topAnchor.constraint(equalTo: canvasArea.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: canvasArea.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: canvasArea.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: canvasArea.trailingAnchor),

            zoomControls.trailingAnchor.constraint(equalTo: canvasArea.trailingAnchor, constant: -Metrics.controlInset),
            zoomControls.bottomAnchor.constraint(
                equalTo: canvasArea.bottomAnchor,
                constant: -(Metrics.sheetCollapsedHeight + Metrics.controlInset)
            ),

            scrimView.topAnchor.constraint(equalTo: canvasArea.topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: canvasArea.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: canvasArea.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: canvasArea.bottomAnchor),

            sheetView.leadingAnchor.constraint(equalTo: canvasArea.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: canvasArea.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: canvasArea.bottomAnchor),
            sheetCollapsedConstraint,

            switcherView.topAnchor.constraint(equalTo: view.topAnchor),
            switcherView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            switcherView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switcherView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        switcherView.pinCardTop(to: headerView.bottomAnchor)
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILFamilyTreeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            searchToggled: searchToggledSubject.eraseToAnyPublisher(),
            searchTextChanged: searchTextChangedSubject.eraseToAnyPublisher(),
            searchSubmitted: searchSubmittedSubject.eraseToAnyPublisher(),
            generationSelected: generationSelectedSubject.eraseToAnyPublisher(),
            memberTapped: memberTappedSubject.eraseToAnyPublisher(),
            sheetMemberTapped: sheetMemberTappedSubject.eraseToAnyPublisher(),
            sheetToggled: sheetToggledSubject.eraseToAnyPublisher(),
            sheetDismissed: sheetDismissedSubject.eraseToAnyPublisher(),
            rootTapped: rootTappedSubject.eraseToAnyPublisher(),
            meTapped: meTappedSubject.eraseToAnyPublisher(),
            createTapped: createTappedSubject.eraseToAnyPublisher(),
            joinTapped: joinTappedSubject.eraseToAnyPublisher(),
            addTapped: addTappedSubject.eraseToAnyPublisher(),
            fullProfileTapped: fullProfileTappedSubject.eraseToAnyPublisher(),
            reminderTapped: reminderTappedSubject.eraseToAnyPublisher(),
            contextualActionTapped: contextualActionTappedSubject.eraseToAnyPublisher(),
            offeringTapped: offeringTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            titleTapped: titleTappedSubject.eraseToAnyPublisher(),
            switcherDismissed: switcherDismissedSubject.eraseToAnyPublisher(),
            viewSelected: viewSelectedSubject.eraseToAnyPublisher(),
            chronicleTapped: chronicleTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILFamilyTreeStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILFamilyTreeStateModel) {
        headerView.title = model.title
        headerView.subtitle = model.subtitle

        emptyStateView.isHidden = !model.isEmpty
        scrollView.isHidden = model.isEmpty
        zoomControls.isHidden = model.isEmpty
        chipWrap.isHidden = model.isEmpty
        legendView.isHidden = model.isEmpty
        legendView.showsMe = model.meID != nil
        zoomControls.showsMe = model.meID != nil
        legendView.isMerged = model.isMerged
        headerView.showsActions = !model.isEmpty
        headerView.showsAdd = !model.isMerged
        headerView.showsSwitcher = model.canSwitch
        headerView.isSearchActive = model.isSearchOpen && !model.isEmpty
        updateSwitcher(with: model)

        updateSearch(with: model)
        chipScrollView.configure(
            titles: model.generationChips.map(\.title),
            selectedIndex: model.generationChips.firstIndex(where: \.isSelected) ?? 0
        )
        // Showing the chips / legend / search field makes the header taller and the canvas area
        // shorter. Lay that out now: centring the tree against the stale (taller) height is what
        // left it sitting too low.
        if view.window != nil { view.layoutIfNeeded() }

        if renderedLayout != model.layout || renderedNodes != model.nodes {
            rebuildCanvas(layout: model.layout, nodes: model.nodes)
        }
        canvasView.applyState(selectedID: model.selectedID, lineageIDs: model.lineageIDs, alphas: model.nodeAlphas)

        updateSheet(with: model)

        if let focus = model.focus, focus.token != handledFocusToken {
            handledFocusToken = focus.token
            pendingFocus = focus
            applyPendingFocus()
        }
    }

    private func updateSwitcher(with model: ILFamilyTreeStateModel) {
        switcherView.configure(rows: model.switcherRows, canCreate: model.canCreateBook)
        let show = model.isSwitcherOpen && model.canSwitch
        guard show != isSwitcherPresented else { return }
        isSwitcherPresented = show
        if show { switcherView.isHidden = false }
        let updates = { self.switcherView.alpha = show ? 1 : 0 }
        let completion: (Bool) -> Void = { _ in
            // A newer open/close may have started meanwhile — only the latest one may hide the view.
            if !self.isSwitcherPresented { self.switcherView.isHidden = true }
        }
        if switcherView.window != nil {
            UIView.animate(withDuration: Metrics.sheetAnimationDuration / 2, animations: updates, completion: completion)
        } else {
            updates()
            completion(true)
        }
    }

    private func updateSearch(with model: ILFamilyTreeStateModel) {
        let wasHidden = searchWrap.isHidden
        searchWrap.isHidden = !(model.isSearchOpen && !model.isEmpty)
        searchInput.isHidden = searchWrap.isHidden
        searchInput.trailingText = model.searchCountText
        if searchInput.text != model.searchText { searchInput.text = model.searchText }
        if wasHidden && !searchWrap.isHidden {
            searchInput.focus()
        } else if searchWrap.isHidden {
            searchInput.unfocus()
        }
    }

    private func rebuildCanvas(layout: ILFamilyTreeLayout, nodes: [ILFamilyTreeNodeModel]) {
        renderedLayout = layout
        renderedNodes = nodes
        scrollView.zoomScale = 1
        canvasView.configure(layout: layout, nodes: nodes)
        scrollView.contentSize = layout.canvasSize
        updateCenteringInsets()
        hasCenteredOnce = false
        updateZoomControls()
    }

    private func updateSheet(with model: ILFamilyTreeStateModel) {
        guard let detail = model.detail, !model.isEmpty else {
            sheetView.isHidden = true
            return
        }
        sheetView.isHidden = false
        sheetView.configure(with: detail)
        // Lay the content out at the current size before any height animation starts.
        sheetView.layoutIfNeeded()
        setSheetExpanded(model.isSheetExpanded, animated: sheetView.window != nil)
    }

    private func setSheetExpanded(_ expanded: Bool, animated: Bool) {
        let changed = expanded != isSheetExpanded
        isSheetExpanded = expanded
        sheetView.setExpanded(expanded, animated: animated && changed)
        scrimView.isHidden = false
        sheetCollapsedConstraint.isActive = !expanded
        sheetExpandedConstraint.isActive = expanded
        let updates = {
            self.scrimView.alpha = expanded ? 1 : 0
            self.canvasArea.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in self.scrimView.isHidden = !expanded }
        if animated && changed {
            UIView.animate(withDuration: Metrics.sheetAnimationDuration, delay: 0,
                           options: [.curveEaseOut], animations: updates, completion: completion)
        } else {
            updates()
            completion(true)
        }
    }

    // MARK: - Zoom & focus
    private var currentZoomIndex: Int {
        let levels = Metrics.zoomLevels
        return levels.indices.min(by: { abs(levels[$0] - scrollView.zoomScale) < abs(levels[$1] - scrollView.zoomScale) })
            ?? Metrics.defaultZoomIndex
    }

    private func stepZoom(by delta: Int) {
        let target = currentZoomIndex + delta
        guard Metrics.zoomLevels.indices.contains(target) else { return }
        scrollView.setZoomScale(Metrics.zoomLevels[target], animated: true)
        // Keep the selected person in view once the zoom has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + Metrics.sheetAnimationDuration) { [weak self] in
            guard let self, let id = self.lastFocusedID else { return }
            self.center(on: id, animated: true)
        }
    }

    private func updateZoomControls() {
        let index = currentZoomIndex
        zoomControls.setEnabled(canZoomIn: index < Metrics.zoomLevels.count - 1, canZoomOut: index > 0)
    }

    private func applyPendingFocus() {
        guard let focus = pendingFocus, scrollView.bounds.width > 0, renderedLayout != nil else { return }
        pendingFocus = nil
        lastFocusedID = focus.memberID
        updateCenteringInsets()
        center(on: focus.memberID, animated: hasCenteredOnce)
        hasCenteredOnce = true
        userHasMovedCanvas = false
    }

    /// The canvas area changed height after the tree was centred (header grew, rotation, ...):
    /// centre again, unless the user has already moved the canvas themselves.
    private func recenterIfCanvasResized() {
        let height = scrollView.bounds.height
        defer { lastLaidOutCanvasHeight = height }
        guard height > 0, height != lastLaidOutCanvasHeight, lastLaidOutCanvasHeight > 0,
              hasCenteredOnce, !userHasMovedCanvas, pendingFocus == nil,
              let id = lastFocusedID else { return }
        center(on: id, animated: false)
    }

    /// Vertical span of the people (plus room for their crown / label), in canvas points at zoom 1.
    private var peopleSpan: (minY: CGFloat, maxY: CGFloat)? {
        guard let ys = renderedLayout?.centers.values.map(\.y), let low = ys.min(), let high = ys.max() else { return nil }
        return (low - Metrics.peopleSpanPaddingTop, high + Metrics.peopleSpanPaddingBottom)
    }

    /// Scroll offset that puts the middle of the people in the middle of the area above the
    /// collapsed sheet (negative when the tree is shorter than that area).
    private var centeredOffsetY: CGFloat? {
        guard let span = peopleSpan else { return nil }
        let available = scrollView.bounds.height - Metrics.sheetCollapsedHeight
        return (span.minY + span.maxY) / 2 * scrollView.zoomScale - available / 2
    }

    /// Pads the scroll insets so a tree smaller than the viewport can sit centred: horizontally on
    /// the canvas, vertically on the people (not on the canvas, which also holds the roots below).
    /// A tree that overflows scrolls as usual.
    private func updateCenteringInsets() {
        let bounds = scrollView.bounds
        guard bounds.width > 0 else { return }
        let content = scrollView.contentSize
        let horizontal = max((bounds.width - content.width) / 2, 0)
        var top: CGFloat = 0
        var bottom = Metrics.sheetScrollMargin
        if let desired = centeredOffsetY {
            top = max(-desired, 0)
            bottom = max(bottom, desired + bounds.height - content.height)
        }
        let inset = UIEdgeInsets(top: top, left: horizontal, bottom: bottom, right: horizontal)
        guard scrollView.contentInset != inset else { return }
        scrollView.contentInset = inset
    }

    /// Scrolls so `memberID` sits in the middle of the area not covered by the collapsed sheet.
    /// A tree that fits in that area is centred as a whole instead.
    private func center(on memberID: String, animated: Bool) {
        guard let point = canvasView.center(of: memberID) else { return }
        let scale = scrollView.zoomScale
        let visibleHeight = scrollView.bounds.height - Metrics.sheetCollapsedHeight - Metrics.controlInset
        var targetY = point.y * scale - visibleHeight / 2
        if let span = peopleSpan, let desired = centeredOffsetY,
           (span.maxY - span.minY) * scale <= scrollView.bounds.height - Metrics.sheetCollapsedHeight {
            targetY = desired
        }
        let target = CGPoint(x: point.x * scale - scrollView.bounds.width / 2, y: targetY)
        let inset = scrollView.contentInset
        let minX = -inset.left
        let minY = -inset.top
        let maxX = max(scrollView.contentSize.width - scrollView.bounds.width + inset.right, minX)
        let maxY = max(scrollView.contentSize.height - scrollView.bounds.height + inset.bottom, minY)
        scrollView.setContentOffset(
            CGPoint(x: min(max(target.x, minX), maxX), y: min(max(target.y, minY), maxY)),
            animated: animated
        )
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        canvasView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateCenteringInsets()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        userHasMovedCanvas = true
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        userHasMovedCanvas = true
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        canvasView.updateContentScale(scale * traitCollection.displayScale)
        updateZoomControls()
    }

    // MARK: - Actions
    @objc private func handleScrimTap() {
        sheetDismissedSubject.send(())
    }
}
