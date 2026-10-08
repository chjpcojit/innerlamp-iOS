//
//  ILPhotoViewerViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn xem 1 ảnh Phật giáo (lightbox): nền tối, ảnh 4:3 bay ra từ ô ở lưới (hero), vuốt ngang hoặc
/// chạm mũi tên để đổi ảnh trong danh sách đang lọc, tim yêu thích, 3 nút hành động.
final class ILPhotoViewerViewController: BaseViewController, TransitionProviding {

    // MARK: - Layout constants
    private static let topButtonSize: CGFloat = 44
    private static let arrowButtonSize: CGFloat = 36
    private static let arrowInset: CGFloat = 10
    /// Chiều cao / chiều rộng của ảnh — cùng tỉ lệ ô ở lưới (`AS-Photos-001`).
    private static let imageAspectRatio: CGFloat = 0.75
    private static let stepFadeDuration: TimeInterval = 0.26

    // MARK: - Properties
    private let viewModel: ILPhotoViewerViewModel
    private let startID: String
    private var currentID: String
    private var cancellables = Set<AnyCancellable>()
    private let closeTappedSubject = PassthroughSubject<Void, Never>()
    private let previousTappedSubject = PassthroughSubject<Void, Never>()
    private let nextTappedSubject = PassthroughSubject<Void, Never>()
    private let favoriteTappedSubject = PassthroughSubject<Void, Never>()
    private let actionTappedSubject = PassthroughSubject<ILPhotoViewerAction, Never>()

    // MARK: - TransitionProviding
    var pushTransition: NavigationTransitionAnimating? {
        HeroTransition(heroID: ILPhotoViewerHeroID.make(photoID: startID))
    }

    /// Morphs back into the tile of the photo being shown now (falls back to a crossfade when that
    /// tile is not on screen).
    var popTransition: NavigationTransitionAnimating? {
        HeroTransition(heroID: ILPhotoViewerHeroID.make(photoID: currentID))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - UI Elements
    private lazy var closeButton = ILPhotoViewerIconButton(
        icon: ILIcons.viewerClose,
        diameter: Self.topButtonSize,
        backdrop: false,
        accessibilityLabel: "photoViewer.a11y.close".localized
    )

    private lazy var favoriteButton = ILPhotoViewerIconButton(
        icon: ILIcons.viewerHeart,
        diameter: Self.topButtonSize,
        backdrop: false,
        accessibilityLabel: "photoViewer.a11y.favorite".localized
    )

    private lazy var previousButton = ILPhotoViewerIconButton(
        icon: ILIcons.viewerChevronLeft,
        diameter: Self.arrowButtonSize,
        backdrop: true,
        accessibilityLabel: "photoViewer.a11y.previous".localized
    )

    private lazy var nextButton = ILPhotoViewerIconButton(
        icon: ILIcons.viewerChevronRight,
        diameter: Self.arrowButtonSize,
        backdrop: true,
        accessibilityLabel: "photoViewer.a11y.next".localized
    )

    private let counterLabel = UILabel()
    private let imageArea = UIView()
    private let heroImageView = ILRemoteImageView(frame: .zero)
    private let infoPanel = ILPhotoViewerInfoPanelView()

    // MARK: - Initializer
    init(viewModel: ILPhotoViewerViewModel, startID: String) {
        self.viewModel = viewModel
        self.startID = startID
        self.currentID = startID
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
        view.backgroundColor = ILColors.darkBackground

        counterLabel.font = ILTypography.subheadMedium
        counterLabel.textColor = ILColors.inkOnDarkSecondary
        counterLabel.textAlignment = .center

        heroImageView.backgroundColor = ILColors.surfaceDark
        heroImageView.contentMode = .scaleAspectFill

        closeButton.addAction(UIAction { [weak self] _ in self?.closeTappedSubject.send(()) }, for: .touchUpInside)
        favoriteButton.addAction(UIAction { [weak self] _ in self?.favoriteTappedSubject.send(()) }, for: .touchUpInside)
        previousButton.addAction(UIAction { [weak self] _ in self?.previousTappedSubject.send(()) }, for: .touchUpInside)
        nextButton.addAction(UIAction { [weak self] _ in self?.nextTappedSubject.send(()) }, for: .touchUpInside)
        infoPanel.onAction = { [weak self] action in self?.actionTappedSubject.send(action) }

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        imageArea.addGestureRecognizer(swipeLeft)
        imageArea.addGestureRecognizer(swipeRight)

        imageArea.addSubview(heroImageView)
        imageArea.addSubview(previousButton)
        imageArea.addSubview(nextButton)
        [closeButton, counterLabel, favoriteButton, imageArea, infoPanel].forEach { view.addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()
        [closeButton, counterLabel, favoriteButton, imageArea, heroImageView, previousButton, nextButton, infoPanel]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let side = ILMetrics.spaceSmall + 4
        let horizontal = ILMetrics.screenHorizontal

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            favoriteButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            favoriteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            counterLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            infoPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
            infoPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
            infoPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ILMetrics.spaceStandard),

            imageArea.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
            imageArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageArea.bottomAnchor.constraint(equalTo: infoPanel.topAnchor, constant: -ILMetrics.spaceStandard),

            heroImageView.leadingAnchor.constraint(equalTo: imageArea.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: imageArea.trailingAnchor),
            heroImageView.centerYAnchor.constraint(equalTo: imageArea.centerYAnchor),
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: Self.imageAspectRatio),

            previousButton.leadingAnchor.constraint(equalTo: imageArea.leadingAnchor, constant: Self.arrowInset),
            previousButton.centerYAnchor.constraint(equalTo: imageArea.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: imageArea.trailingAnchor, constant: -Self.arrowInset),
            nextButton.centerYAnchor.constraint(equalTo: imageArea.centerYAnchor)
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILPhotoViewerViewModel.Input(
            closeTapped: closeTappedSubject.eraseToAnyPublisher(),
            previousTapped: previousTappedSubject.eraseToAnyPublisher(),
            nextTapped: nextTappedSubject.eraseToAnyPublisher(),
            favoriteTapped: favoriteTappedSubject.eraseToAnyPublisher(),
            actionTapped: actionTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on:)`: state is already sent on main, and the first state must be in place
        // before the hero transition reads the destination frame.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        // Swipe left reveals the next photo, swipe right the previous one.
        if gesture.direction == .left {
            nextTappedSubject.send(())
        } else {
            previousTappedSubject.send(())
        }
    }

    // MARK: - Render
    private func render(state: ViewState<ILPhotoViewerStateModel>) {
        switch state {
        case .idle, .loading:
            break
        case .success(let model):
            updateUI(with: model)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    private func updateUI(with model: ILPhotoViewerStateModel) {
        counterLabel.text = model.counter
        favoriteButton.icon = model.isFavorite ? ILIcons.viewerHeartFilled : ILIcons.viewerHeart
        previousButton.alpha = model.hasPrevious ? 1 : 0
        previousButton.isUserInteractionEnabled = model.hasPrevious
        nextButton.alpha = model.hasNext ? 1 : 0
        nextButton.isUserInteractionEnabled = model.hasNext
        infoPanel.configure(item: model.item, toast: model.toast)

        guard model.item.id != currentID || heroImageView.heroID == nil else { return }
        let isStep = heroImageView.heroID != nil
        currentID = model.item.id
        heroImageView.heroID = ILPhotoViewerHeroID.make(photoID: model.item.id)
        let applyImage = { [heroImageView] in heroImageView.setImage(urlString: model.item.imageURL) }
        if isStep {
            UIView.transition(
                with: heroImageView,
                duration: Self.stepFadeDuration,
                options: [.transitionCrossDissolve, .allowUserInteraction],
                animations: applyImage
            )
        } else {
            applyImage()
        }
    }
}
