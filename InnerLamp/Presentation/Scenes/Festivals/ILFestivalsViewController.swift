//
//  ILFestivalsViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILFestivalsViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILFestivalsViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let tabSelectedSubject = PassthroughSubject<ILFestivalsTab, Never>()
    private let loadMoreSubject = PassthroughSubject<Void, Never>()
    private let dayTappedSubject = PassthroughSubject<String, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    /// Các tháng đang hiển thị — để chỉ nối thêm tháng mới khi tải năm kế tiếp (không dựng lại).
    private var renderedMonths: [ILFestivalMonthModel] = []
    private var lastHeaderHeight: CGFloat = 0
    private var monthSections: [String: UIView] = [:]
    /// Tháng cần cuộn tới khi mở màn lần đầu; xoá sau khi đã cuộn.
    private var pendingScrollMonthId: String?
    private var hasScrolledToCurrentMonth = false

    // MARK: - UI Elements
    // Pinned header: sits above the scroll view and blurs in as content scrolls under it.
    private lazy var headerContainer: ILStickyHeaderBand = {
        let band = ILStickyHeaderBand()
        return band
    }()

    private lazy var headerView: ILNavBar = {
        let navBar = ILNavBar(title: "festivals.header.title".localized)
        return navBar
    }()

    private lazy var allChip: ILChip = {
        let chip = ILChip(label: "festivals.tab.all".localized)
        return chip
    }()

    private lazy var festivalsChip: ILChip = {
        let chip = ILChip(label: "festivals.tab.major".localized)
        return chip
    }()

    private lazy var observancesChip: ILChip = {
        let chip = ILChip(label: "festivals.tab.observance".localized)
        return chip
    }()

    private lazy var chipsRow: UIStackView = {
        let row = UIStackView(arrangedSubviews: [allChip, festivalsChip, observancesChip, UIView()])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = ILMetrics.spaceSmall
        return row
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.delegate = self
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ILMetrics.groupSpacing + 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var introLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = ILTypography.makeParagraph(
            text: "festivals.intro".localized,
            font: ILTypography.note,
            color: ILColors.inkTertiary,
            cssLineHeight: 1.6
        )
        return label
    }()

    // MARK: - Initializer
    init(viewModel: ILFestivalsViewModel) {
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
        (tabBarController as? ILMainTabBarController)?.setBottomNavHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollInsetForHeader()
        scrollToPendingMonthIfNeeded()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(chipsRow)

        // Scroll view first so the sticky header band stays on top of scrolled content.
        [scrollView, headerContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        headerContainer.bind(to: scrollView)

        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(introLabel)

        allChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.all) }
        festivalsChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.festivals) }
        observancesChip.onTap = { [weak self] in self?.tabSelectedSubject.send(.observances) }
    }

    override func setupConstraints() {
        super.setupConstraints()
        [headerView, chipsRow].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: ILMetrics.screenHorizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            chipsRow.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            chipsRow.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: ILMetrics.screenHorizontal),
            chipsRow.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -ILMetrics.screenHorizontal),

            chipsRow.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ILMetrics.screenPadding.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILFestivalsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            loadMoreTriggered: loadMoreSubject.eraseToAnyPublisher(),
            dayTapped: dayTappedSubject.eraseToAnyPublisher(),
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

    // MARK: - Pinned header
    /// Content starts below the pinned header: reserve its height as top inset.
    private func updateScrollInsetForHeader() {
        let height = headerContainer.frame.height
        guard height > 0, height != lastHeaderHeight else { return }
        let wasAtTop = lastHeaderHeight == 0 || scrollView.contentOffset.y <= -lastHeaderHeight + 0.5
        lastHeaderHeight = height
        scrollView.contentInset.top = height
        scrollView.verticalScrollIndicatorInsets.top = height
        if wasAtTop { scrollView.contentOffset.y = -height }
    }

    // MARK: - Render
    private func render(state: ViewState<ILFestivalsStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILFestivalsStateModel) {
        headerView.subtitle = model.subtitle
        updateSelectedChip(model.selectedTab)
        rebuildMonths(model.months)
        if !hasScrolledToCurrentMonth {
            pendingScrollMonthId = model.currentMonthId
            scrollToPendingMonthIfNeeded()
        }
    }

    /// Cuộn để tiêu đề tháng hiện tại nằm ngay dưới header, đúng 1 lần. Chờ tới khi header đã
    /// có chiều cao (inset đã đặt) và section đã có layout.
    private func scrollToPendingMonthIfNeeded() {
        guard let monthId = pendingScrollMonthId, lastHeaderHeight > 0,
              let section = monthSections[monthId] else { return }
        view.layoutIfNeeded()
        guard section.frame.height > 0 else { return }
        pendingScrollMonthId = nil
        hasScrolledToCurrentMonth = true

        let sectionTop = scrollView.convert(section.frame, from: contentStack).minY
        let minOffset = -scrollView.contentInset.top
        let maxOffset = max(minOffset, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        scrollView.contentOffset.y = min(max(sectionTop - scrollView.contentInset.top, minOffset), maxOffset)
    }

    private func updateSelectedChip(_ tab: ILFestivalsTab) {
        allChip.chipState = tab == .all ? .selected : .normal
        festivalsChip.chipState = tab == .festivals ? .selected : .normal
        observancesChip.chipState = tab == .observances ? .selected : .normal
    }

    /// Cập nhật danh sách tháng (tiêu đề tháng + các thẻ ngày lễ). `introLabel` giữ nguyên ở đầu
    /// stack. Dữ liệu không đổi thì bỏ qua; khi chỉ có tháng mới nối thêm vào cuối (tải năm kế
    /// tiếp) thì chỉ thêm các tháng đó; còn lại (đổi tab) dựng lại toàn bộ.
    private func rebuildMonths(_ months: [ILFestivalMonthModel]) {
        guard months != renderedMonths else { return }

        let isAppend = months.count > renderedMonths.count
            && Array(months.prefix(renderedMonths.count)) == renderedMonths
        var newMonths = months
        if isAppend {
            newMonths = Array(months.dropFirst(renderedMonths.count))
        } else {
            for subview in contentStack.arrangedSubviews where subview !== introLabel {
                contentStack.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
            monthSections = [:]
        }
        renderedMonths = months

        for month in newMonths {
            let section = makeMonthSection(month)
            monthSections[month.id] = section
            contentStack.addArrangedSubview(section)
        }
    }

    /// 1 tháng = stack dọc (tiêu đề tháng + các thẻ ngày lễ).
    private func makeMonthSection(_ month: ILFestivalMonthModel) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ILMetrics.spaceSmall

        let header = UILabel()
        header.font = ILTypography.scriptureBody
        header.textColor = ILColors.ink
        header.text = month.label
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(ILMetrics.rowSpacing, after: header)

        for day in month.days {
            let item = ILFestivalsItemView()
            item.configure(with: day)
            // Chỉ ngày lễ có tên mới có trang chi tiết; ngày trai giới không chạm được.
            if day.isFestival {
                item.onTap = { [weak self] in self?.dayTappedSubject.send(day.id) }
            }
            stack.addArrangedSubview(item)
        }
        return stack
    }
}

// MARK: - UIScrollViewDelegate
extension ILFestivalsViewController: UIScrollViewDelegate {
    /// Gần cuối danh sách (còn khoảng một màn hình) thì xin tải năm kế tiếp; ViewModel chặn tải trùng.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
        guard scrollView.contentSize.height > 0,
              visibleBottom > scrollView.contentSize.height - scrollView.bounds.height else { return }
        loadMoreSubject.send(())
    }
}
