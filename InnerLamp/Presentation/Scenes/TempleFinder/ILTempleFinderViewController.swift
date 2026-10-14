//
//  ILTempleFinderViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn "Chọn chùa tu tập" (`findtp` trong design handoff, chế độ chọn): header dán cố định gồm
/// `ILNavBar` (phụ đề "Chùa hiện tại: …"), ô tìm kiếm và 4 chip miền; bên dưới là danh sách chùa
/// (nút "Chọn" đặt chùa tu tập, chạm hàng mở Trang chùa) kết thúc bằng dòng "Không thấy chùa bạn
/// tìm?" — mở form đề xuất thêm chùa thay cho danh sách.
final class ILTempleFinderViewController: BaseViewController {

    private enum Item {
        case sent(String)
        case empty(String)
        case temple(ILTempleFinderRowModel)
        case add
    }

    private enum ScreenState {
        case loading
        case list
        case form
        case error
    }

    // MARK: - Layout
    private static let chipRowHeight: CGFloat = 36

    // MARK: - Properties
    private let viewModel: ILTempleFinderViewModel
    private var cancellables = Set<AnyCancellable>()
    private var items: [Item] = []
    private var isShowingForm = false
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let backTappedSubject = PassthroughSubject<Void, Never>()
    private let queryChangedSubject = PassthroughSubject<String, Never>()
    private let regionSelectedSubject = PassthroughSubject<ILTempleFinderRegionFilter, Never>()
    private let templeTappedSubject = PassthroughSubject<String, Never>()
    private let pickTappedSubject = PassthroughSubject<String, Never>()
    private let retryTappedSubject = PassthroughSubject<Void, Never>()
    private let addTappedSubject = PassthroughSubject<Void, Never>()
    private let addCancelledSubject = PassthroughSubject<Void, Never>()
    private let addSubmittedSubject = PassthroughSubject<ILTempleFinderProposal, Never>()

    // MARK: - UI Elements
    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.backgroundColor = ILColors.canvas
        return container
    }()

    private lazy var headerView = ILNavBar(title: "templeFinder.title".localized, showBack: true)
    private lazy var searchInput = ILSearchInputView(placeholder: "templeFinder.search.placeholder".localized)

    private lazy var chipsScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = false
        return scroll
    }()

    private lazy var chipsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceSmall
        stack.alignment = .center
        return stack
    }()

    private lazy var headerDivider: UIView = {
        let divider = UIView()
        divider.backgroundColor = ILColors.border
        return divider
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.keyboardDismissMode = .onDrag
        table.estimatedRowHeight = 64
        table.rowHeight = UITableView.automaticDimension
        table.contentInset = UIEdgeInsets(
            top: ILMetrics.spaceSmall, left: 0, bottom: ILMetrics.groupSpacing + ILMetrics.spaceStandard, right: 0
        )
        table.dataSource = self
        table.delegate = self
        table.register(ILTempleFinderRowCell.self, forCellReuseIdentifier: ILTempleFinderRowCell.reuseIdentifier)
        table.register(ILTempleFinderAddCell.self, forCellReuseIdentifier: ILTempleFinderAddCell.reuseIdentifier)
        table.register(ILTempleFinderEmptyCell.self, forCellReuseIdentifier: ILTempleFinderEmptyCell.reuseIdentifier)
        table.register(ILTempleFinderSentCell.self, forCellReuseIdentifier: ILTempleFinderSentCell.reuseIdentifier)
        return table
    }()

    private lazy var formScrollView: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        v.keyboardDismissMode = .onDrag
        v.isHidden = true
        return v
    }()
    private lazy var formView = ILTempleFinderAddFormView()
    private lazy var skeletonView: ILTempleFinderSkeletonView = {
        let v = ILTempleFinderSkeletonView()
        v.isHidden = true
        return v
    }()
    private lazy var errorStateView = ILStateView(kind: .error)
    private lazy var retryButton = ILButton(title: "common.retry".localized, variant: .primary)
    private lazy var errorStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .fill
        v.spacing = ILMetrics.groupSpacing
        v.isHidden = true
        return v
    }()

    // MARK: - Initializer
    init(viewModel: ILTempleFinderViewModel) {
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

        headerView.onBack = { [weak self] in self?.backTappedSubject.send(()) }
        searchInput.onTextChanged = { [weak self] text in self?.queryChangedSubject.send(text) }

        [headerView, searchInput, chipsScrollView, headerDivider].forEach { headerContainer.addSubview($0) }
        chipsScrollView.addSubview(chipsStack)

        formScrollView.addSubview(formView)
        formView.onCancel = { [weak self] in self?.addCancelledSubject.send(()) }
        formView.onSubmit = { [weak self] proposal in self?.addSubmittedSubject.send(proposal) }

        retryButton.onTap = { [weak self] in self?.retryTappedSubject.send(()) }
        errorStack.addArrangedSubview(errorStateView)
        errorStack.addArrangedSubview(retryButton)

        view.addSubview(tableView)
        view.addSubview(formScrollView)
        view.addSubview(skeletonView)
        view.addSubview(errorStack)
        view.addSubview(headerContainer)
    }

    override func setupConstraints() {
        super.setupConstraints()
        [
            headerContainer, headerView, searchInput, chipsScrollView, chipsStack, headerDivider,
            tableView, formScrollView, formView, skeletonView, errorStack
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceSmall / 2),
            headerView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: horizontal),
            headerView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -horizontal),

            searchInput.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ILMetrics.spaceMedium),
            searchInput.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: horizontal),
            searchInput.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -horizontal),
            searchInput.heightAnchor.constraint(equalToConstant: ILMetrics.inputHeight),

            chipsScrollView.topAnchor.constraint(equalTo: searchInput.bottomAnchor, constant: ILMetrics.spaceMedium),
            chipsScrollView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            chipsScrollView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            chipsScrollView.heightAnchor.constraint(equalToConstant: Self.chipRowHeight),

            chipsStack.topAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.topAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.leadingAnchor, constant: horizontal),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.trailingAnchor, constant: -horizontal),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScrollView.contentLayoutGuide.bottomAnchor),

            headerDivider.topAnchor.constraint(equalTo: chipsScrollView.bottomAnchor, constant: ILMetrics.rowSpacing),
            headerDivider.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            formScrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            formScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            formScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            formScrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            formView.topAnchor.constraint(equalTo: formScrollView.contentLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            formView.bottomAnchor.constraint(equalTo: formScrollView.contentLayoutGuide.bottomAnchor, constant: -ILMetrics.groupSpacing),
            formView.leadingAnchor.constraint(equalTo: formScrollView.frameLayoutGuide.leadingAnchor, constant: horizontal),
            formView.trailingAnchor.constraint(equalTo: formScrollView.frameLayoutGuide.trailingAnchor, constant: -horizontal),

            skeletonView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorStack.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            errorStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILTempleFinderViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            queryChanged: queryChangedSubject.eraseToAnyPublisher(),
            regionSelected: regionSelectedSubject.eraseToAnyPublisher(),
            templeTapped: templeTappedSubject.eraseToAnyPublisher(),
            pickTapped: pickTappedSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher(),
            addTapped: addTappedSubject.eraseToAnyPublisher(),
            addCancelled: addCancelledSubject.eraseToAnyPublisher(),
            addSubmitted: addSubmittedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        output.filters
            .sink { [weak self] chips in self?.rebuildChips(chips) }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILTempleFinderStateModel>) {
        switch state {
        case .idle:
            break
        case .loading:
            showScreenState(.loading)
        case .success(let model):
            apply(model)
        case .failure(let error):
            configureErrorState(for: error)
            showScreenState(.error)
        }
    }

    private func apply(_ model: ILTempleFinderStateModel) {
        headerView.subtitle = model.subtitle

        if let form = model.addForm {
            if !isShowingForm { formView.open(prefillName: form.prefillName) }
            formView.apply(errorMessage: form.errorMessage, field: form.errorField)
            isShowingForm = true
            showScreenState(.form)
            return
        }
        isShowingForm = false

        var newItems: [Item] = []
        if let sent = model.sentMessage { newItems.append(.sent(sent)) }
        if let emptyText = model.emptyText { newItems.append(.empty(emptyText)) }
        newItems += model.rows.map(Item.temple)
        newItems.append(.add)
        items = newItems
        tableView.reloadData()
        showScreenState(.list)
    }

    private func showScreenState(_ screenState: ScreenState) {
        tableView.isHidden = screenState != .list
        formScrollView.isHidden = screenState != .form
        errorStack.isHidden = screenState != .error
        skeletonView.isHidden = screenState != .loading
    }

    /// Offline gets its own glyph/title; every other failure reads as a generic load error.
    private func configureErrorState(for error: Error) {
        if case ILCatalogError.offline = error {
            errorStateView.kind = .offline
            errorStateView.title = "templeFinder.error.offlineTitle".localized
        } else {
            errorStateView.kind = .error
            errorStateView.title = "templeFinder.error.title".localized
        }
        errorStateView.message = error.localizedDescription
    }

    private func rebuildChips(_ chips: [ILTempleFinderRegionChipModel]) {
        chipsStack.arrangedSubviews.forEach {
            chipsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for chip in chips {
            let view = ILChip(label: chip.label, state: chip.isSelected ? .selected : .normal)
            view.onTap = { [weak self] in self?.regionSelectedSubject.send(chip.filter) }
            chipsStack.addArrangedSubview(view)
        }
    }
}

// MARK: - UITableViewDataSource
extension ILTempleFinderViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let isFirst = index == firstCardIndex
        let isLast = index == items.count - 1

        switch items[index] {
        case .sent(let message):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ILTempleFinderSentCell.reuseIdentifier, for: indexPath
            )
            (cell as? ILTempleFinderSentCell)?.configure(message: message)
            return cell
        case .empty(let text):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ILTempleFinderEmptyCell.reuseIdentifier, for: indexPath
            )
            if let cell = cell as? ILTempleFinderEmptyCell {
                cell.configure(text: text)
                cell.applyPosition(isFirst: isFirst, isLast: isLast)
            }
            return cell
        case .temple(let model):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ILTempleFinderRowCell.reuseIdentifier, for: indexPath
            )
            if let cell = cell as? ILTempleFinderRowCell {
                cell.configure(with: model)
                cell.applyPosition(isFirst: isFirst, isLast: isLast)
                cell.onPick = { [weak self] in self?.pickTappedSubject.send(model.id) }
            }
            return cell
        case .add:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ILTempleFinderAddCell.reuseIdentifier, for: indexPath
            )
            (cell as? ILTempleFinderAddCell)?.applyPosition(isFirst: isFirst, isLast: isLast)
            return cell
        }
    }

    /// Cell đầu tiên thuộc thẻ — banner "đã gửi" đứng ngoài thẻ nên không tính.
    private var firstCardIndex: Int {
        if case .sent = items.first { return 1 }
        return 0
    }
}

// MARK: - UITableViewDelegate
extension ILTempleFinderViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch items[indexPath.row] {
        case .temple(let model):
            templeTappedSubject.send(model.id)
        case .add:
            view.endEditing(true)
            addTappedSubject.send(())
        case .sent, .empty:
            break
        }
    }
}
