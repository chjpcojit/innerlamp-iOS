//
//  ILSanghaViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Tab Chùa — khớp màn `sangha` trong design handoff. Đã chọn chùa tu tập: thẻ chùa, thông báo,
/// khóa tu & lễ sắp tới, pháp thoại, cúng dường, số Phật tử. Chưa chọn: chùa gần bạn, chùa trực
/// tuyến, khóa tu sắp diễn ra. Cả hai trạng thái kết thúc bằng "Ngày lễ & ngày chay sắp tới".
final class ILSanghaViewController: BaseViewController {

    private enum Layout {
        static let sectionSpacing: CGFloat = 24
        static let titleSpacing: CGFloat = 12
        static let cardSpacing: CGFloat = 10
    }

    // MARK: - Properties
    private let viewModel: ILSanghaViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private var hasAppeared = false
    private let changeTempleTappedSubject = PassthroughSubject<Void, Never>()
    private let myTempleTappedSubject = PassthroughSubject<Void, Never>()
    private let eventsTappedSubject = PassthroughSubject<Void, Never>()
    private let eventActionTappedSubject = PassthroughSubject<String, Never>()
    private let talkTappedSubject = PassthroughSubject<String, Never>()
    private let offerTappedSubject = PassthroughSubject<Void, Never>()
    private let nearbyTempleTappedSubject = PassthroughSubject<String, Never>()
    private let pickTappedSubject = PassthroughSubject<String, Never>()
    private let onlineSessionTappedSubject = PassthroughSubject<String, Never>()
    private let festivalsTappedSubject = PassthroughSubject<Void, Never>()
    private let dayReminderTappedSubject = PassthroughSubject<String, Never>()

    // MARK: - UI Elements
    private lazy var headerBand: ILStickyHeaderBand = {
        let band = ILStickyHeaderBand()
        return band
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayMedium
        label.textColor = ILColors.ink
        label.text = "sangha.title".localized
        label.accessibilityTraits = .header
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

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
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializer
    init(viewModel: ILSanghaViewModel) {
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
        // Lần hiện đầu đã được `viewDidLoad` nạp — chỉ nạp lại khi quay về (vd. sau khi đổi chùa).
        if hasAppeared { viewWillAppearSubject.send(()) }
        hasAppeared = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyHeaderInset()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        // Band last so it sits above the scroll view.
        [scrollView, headerBand].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        headerBand.addSubview(titleLabel)
        headerBand.bind(to: scrollView)
        scrollView.addSubview(contentStack)
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerBand.topAnchor.constraint(equalTo: view.topAnchor),
            headerBand.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBand.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: headerBand.leadingAnchor, constant: ILMetrics.screenHorizontal),
            titleLabel.trailingAnchor.constraint(equalTo: headerBand.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            titleLabel.bottomAnchor.constraint(equalTo: headerBand.bottomAnchor, constant: -ILMetrics.spaceMedium + 2),

            // Scroll view chạy dưới header để nội dung mờ xuyên qua kính; chiều cao header được áp
            // thành top content inset trong `viewDidLayoutSubviews`.
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceSmall),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -(ILMetrics.bottomNavHeight + ILMetrics.groupSpacing)),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILSanghaViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            changeTempleTapped: changeTempleTappedSubject.eraseToAnyPublisher(),
            myTempleTapped: myTempleTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            eventActionTapped: eventActionTappedSubject.eraseToAnyPublisher(),
            talkTapped: talkTappedSubject.eraseToAnyPublisher(),
            offerTapped: offerTappedSubject.eraseToAnyPublisher(),
            nearbyTempleTapped: nearbyTempleTappedSubject.eraseToAnyPublisher(),
            pickTapped: pickTappedSubject.eraseToAnyPublisher(),
            onlineSessionTapped: onlineSessionTappedSubject.eraseToAnyPublisher(),
            festivalsTapped: festivalsTappedSubject.eraseToAnyPublisher(),
            dayReminderTapped: dayReminderTappedSubject.eraseToAnyPublisher()
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
    private func render(state: ViewState<ILSanghaStateModel>) {
        guard case .success(let model) = state else { return }
        rebuildContent(with: model)
    }

    private func rebuildContent(with model: ILSanghaStateModel) {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if let myTemple = model.myTemple {
            addMyTempleSections(myTemple)
        }
        if let chooser = model.chooser {
            addChooserSections(chooser)
        }
        addDaysSection(model.days)
    }

    // MARK: - Đã chọn chùa tu tập
    private func addMyTempleSections(_ model: ILSanghaMyTempleModel) {
        let changeButton = UIButton(type: .system)
        changeButton.setTitle("sangha.myTemple.change".localized, for: .normal)
        changeButton.titleLabel?.font = ILTypography.chip
        changeButton.setTitleColor(ILColors.link, for: .normal)
        changeButton.addTarget(self, action: #selector(handleChangeTemple), for: .touchUpInside)
        let eyebrow = ILSectionEyebrowView(title: "sangha.myTemple.eyebrow".localized)
        let eyebrowRow = UIStackView(arrangedSubviews: [eyebrow, UIView(), changeButton])
        eyebrowRow.axis = .horizontal
        eyebrowRow.alignment = .center
        add(eyebrowRow, spacingAfter: 6)

        let card = ILSanghaMyTempleCardView()
        card.configure(with: model)
        card.onTap = { [weak self] in self?.myTempleTappedSubject.send(()) }
        add(card, spacingAfter: Layout.sectionSpacing)

        add(makeSectionHeader(title: "sangha.news.title".localized), spacingAfter: Layout.titleSpacing)
        let newsRows = model.announcements.map { news -> UIView in
            let row = ILSanghaAnnouncementRowView()
            row.configure(timeText: news.timeText, text: news.text)
            return row
        }
        add(ILSanghaCardView(rows: newsRows), spacingAfter: Layout.sectionSpacing)

        add(
            makeSectionHeader(
                title: "sangha.events.title".localized,
                trailing: ("sangha.events.all".localized, { [weak self] in self?.eventsTappedSubject.send(()) })
            ),
            spacingAfter: Layout.titleSpacing
        )
        addEventCards(model.events)

        add(makeSectionHeader(title: "sangha.talks.title".localized), spacingAfter: Layout.titleSpacing)
        for (index, talk) in model.talks.enumerated() {
            let row = ILRow(title: talk.title, subtitle: talk.subtitle, tone: .green, glyph: .dot)
            row.onTap = { [weak self] in self?.talkTappedSubject.send(talk.talkID) }
            add(row, spacingAfter: index == model.talks.count - 1 ? Layout.sectionSpacing : Layout.cardSpacing)
        }

        let offerRow = ILRow(
            title: "sangha.offer.title".localized, subtitle: model.offerSubtitle, tone: .rose, glyph: .circle
        )
        offerRow.onTap = { [weak self] in self?.offerTappedSubject.send(()) }
        add(offerRow, spacingAfter: ILMetrics.spaceMedium - 2)

        let peers = ILSanghaPeersCardView()
        peers.configure(text: model.peersText)
        add(peers, spacingAfter: Layout.sectionSpacing)
    }

    // MARK: - Chưa chọn chùa tu tập
    private func addChooserSections(_ model: ILSanghaChooserModel) {
        let intro = makeIntroCard()
        add(intro, spacingAfter: Layout.sectionSpacing)

        add(
            makeSectionHeader(title: "sangha.nearby.title".localized, trailingMuted: model.locationText),
            spacingAfter: Layout.titleSpacing
        )
        add(ILSanghaPlaceholderView(text: "sangha.nearby.mapPlaceholder".localized, height: 150), spacingAfter: Layout.cardSpacing)
        let nearbyRows = model.nearby.map { temple -> UIView in
            let row = ILSanghaTempleRowView()
            row.configure(with: temple)
            row.onTap = { [weak self] in self?.nearbyTempleTappedSubject.send(temple.id) }
            row.onPick = { [weak self] in self?.pickTappedSubject.send(temple.id) }
            return row
        }
        add(ILSanghaCardView(rows: nearbyRows), spacingAfter: Layout.sectionSpacing)

        add(makeSectionHeader(title: "sangha.online.title".localized), spacingAfter: Layout.titleSpacing)
        for (index, session) in model.online.enumerated() {
            let card = ILSanghaOnlineCardView()
            card.configure(with: session)
            card.onTap = { [weak self] in self?.onlineSessionTappedSubject.send(session.id) }
            add(card, spacingAfter: index == model.online.count - 1 ? Layout.sectionSpacing : Layout.cardSpacing)
        }

        add(makeSectionHeader(title: "sangha.retreats.title".localized), spacingAfter: Layout.titleSpacing)
        addEventCards(model.retreats)
    }

    private func makeIntroCard() -> UIView {
        let card = UIView()
        card.backgroundColor = ILColors.surface
        card.layer.cornerRadius = ILMetrics.radiusCardMedium
        card.layer.borderWidth = 1
        card.layer.borderColor = ILColors.goldCardBorder.cgColor
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (_: ILSanghaViewController, _) in
            card.layer.borderColor = ILColors.goldCardBorder.cgColor
        }

        let title = UILabel()
        title.font = ILTypography.heroCardTitle
        title.textColor = ILColors.ink
        title.numberOfLines = 0
        title.text = "sangha.empty.title".localized
        let body = UILabel()
        body.numberOfLines = 0
        body.attributedText = ILTypography.makeAttributedString(
            text: "sangha.empty.body".localized,
            font: ILTypography.bodyCompact,
            color: ILColors.inkTertiary,
            lineHeightMultiple: 1.6
        )
        let stack = UIStackView(arrangedSubviews: [title, body])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
        ])
        return card
    }

    // MARK: - Dùng chung
    private func addEventCards(_ events: [ILSanghaEventRowModel]) {
        for (index, event) in events.enumerated() {
            let row = ILSanghaDateRowView()
            let accessory: ILSanghaDateRowView.Accessory
            if let label = event.actionLabel {
                accessory = .pill(title: label, style: pillStyle(isOn: event.isActionOn, isGold: event.isGoldAction))
            } else {
                accessory = .chevron
            }
            row.configure(
                dayNumber: event.dayNumber, monthLabel: event.monthLabel,
                title: event.title, subtitle: event.subtitle, accessory: accessory
            )
            row.onTap = { [weak self] in self?.eventsTappedSubject.send(()) }
            row.onAction = { [weak self] in self?.eventActionTappedSubject.send(event.id) }
            add(ILSanghaCardView(rows: [row]), spacingAfter: index == events.count - 1 ? Layout.sectionSpacing : Layout.cardSpacing)
        }
    }

    private func addDaysSection(_ days: [ILSanghaDayRowModel]) {
        guard !days.isEmpty else { return }
        add(
            makeSectionHeader(
                title: "sangha.days.title".localized,
                trailing: ("sangha.days.calendar".localized, { [weak self] in self?.festivalsTappedSubject.send(()) })
            ),
            spacingAfter: Layout.titleSpacing
        )
        let rows = days.map { day -> UIView in
            let row = ILSanghaDateRowView()
            row.configure(
                dayNumber: day.dayNumber, monthLabel: day.monthLabel, title: day.title, subtitle: day.subtitle,
                suggestion: day.suggestion, isHighlighted: day.isFestival,
                accessory: .pill(title: day.reminderLabel, style: pillStyle(isOn: day.isReminderOn, isGold: true))
            )
            row.onTap = { [weak self] in self?.festivalsTappedSubject.send(()) }
            row.onAction = { [weak self] in self?.dayReminderTappedSubject.send(day.id) }
            return row
        }
        add(ILSanghaCardView(rows: rows), spacingAfter: 0)
    }

    private func pillStyle(isOn: Bool, isGold: Bool) -> ILSanghaPillButton.Style {
        guard isOn else { return .off }
        return isGold ? .onGold : .onSolid
    }

    private func makeSectionHeader(
        title: String,
        trailing: (text: String, action: () -> Void)? = nil,
        trailingMuted: String? = nil
    ) -> UIView {
        let header = ILSectionHeaderView(title: title, trailingText: trailing?.text)
        if let trailing {
            header.onTrailingTap = trailing.action
        }
        guard let trailingMuted else { return header }

        let label = UILabel()
        label.font = ILTypography.subhead
        label.textColor = ILColors.inkMuted
        label.text = trailingMuted
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        let titleLabel = UILabel()
        titleLabel.font = ILTypography.headerTitle
        titleLabel.textColor = ILColors.ink
        titleLabel.text = title
        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), label])
        row.axis = .horizontal
        row.alignment = .lastBaseline
        return row
    }

    private func add(_ view: UIView, spacingAfter: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(view)
        contentStack.setCustomSpacing(spacingAfter, after: view)
    }

    /// Đẩy nội dung xuống dưới header; lần layout đầu thì đặt offset ở đỉnh nội dung thay vì dưới header.
    private func applyHeaderInset() {
        let top = headerBand.bounds.height
        guard top > 0, scrollView.contentInset.top != top else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        scrollView.contentInset.top = top
        scrollView.verticalScrollIndicatorInsets.top = top
        if wasAtTop { scrollView.contentOffset.y = -top }
    }

    // MARK: - Actions
    @objc private func handleChangeTemple() {
        changeTempleTappedSubject.send(())
    }
}
