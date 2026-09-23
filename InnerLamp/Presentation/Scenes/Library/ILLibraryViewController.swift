//
//  ILLibraryViewController.swift
//  InnerLamp
//

import UIKit
import Combine

final class ILLibraryViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ILLibraryViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let categorySelectedSubject = PassthroughSubject<ILLibraryCategory, Never>()
    private let searchTappedSubject = PassthroughSubject<Void, Never>()
    private let featuredTappedSubject = PassthroughSubject<Void, Never>()
    private let itemTappedSubject = PassthroughSubject<String, Never>()

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
        label.text = "library.title".localized
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var headerDivider: UIView = {
        let view = UIView()
        view.backgroundColor = ILColors.border
        return view
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

    private lazy var searchBar = ILSearchBarView(placeholder: "library.search.placeholder".localized)
    private lazy var chipsView = ILLibraryCategoryChipsView()
    private lazy var featureCard = ILFeatureCardView()
    private lazy var listView = ILLibraryListView()

    // MARK: - Initializer
    init(viewModel: ILLibraryViewModel) {
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
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas

        [headerView, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        [titleLabel, headerDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [searchBar, chipsView, featureCard, listView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        contentStack.setCustomSpacing(ILMetrics.spaceMedium, after: searchBar)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing, after: chipsView)
        contentStack.setCustomSpacing(ILMetrics.groupSpacing + 2, after: featureCard)

        searchBar.onTap = { [weak self] in self?.searchTappedSubject.send(()) }
        chipsView.onCategorySelected = { [weak self] category in self?.categorySelectedSubject.send(category) }
        featureCard.onTap = { [weak self] in self?.featuredTappedSubject.send(()) }
        listView.onItemTapped = { [weak self] id in self?.itemTappedSubject.send(id) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ILMetrics.spaceMedium),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -ILMetrics.spaceMedium + 2),

            headerDivider.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerDivider.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ILMetrics.spaceMedium),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ILMetrics.screenHorizontal),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ILMetrics.screenHorizontal),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -(ILMetrics.bottomNavHeight + ILMetrics.groupSpacing)),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ILMetrics.screenHorizontal * 2)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILLibraryViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            searchTapped: searchTappedSubject.eraseToAnyPublisher(),
            featuredTapped: featuredTappedSubject.eraseToAnyPublisher(),
            itemTapped: itemTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Gửi sau khi đã subscribe ở trên, trong cùng 1 call đồng bộ — PassthroughSubject không
        // phát lại giá trị đã gửi trước khi có subscriber.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILLibraryStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure:
            // TODO: hiển thị ILStateView(.error) khi có API danh mục thật (Phase 3 của tasks.md).
            break
        }
    }

    private func updateUI(with model: ILLibraryStateModel) {
        chipsView.configure(chips: model.chips)

        if let featured = model.featured {
            featureCard.eyebrow = featured.eyebrow
            featureCard.title = featured.title
            featureCard.ctaTitle = featured.ctaTitle
            featureCard.isHidden = false
        } else {
            featureCard.isHidden = true
        }

        listView.configure(with: model)
    }
}
