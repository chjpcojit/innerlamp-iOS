//
//  ILSplashViewController.swift
//  InnerLamp
//

import UIKit
import Combine

/// Màn hình đầu tiên app hiện ra — thuần thương hiệu, không có tương tác người dùng.
/// Tự chuyển tiếp sau một khoảng thời gian ngắn để lộ hết animation của ngọn đèn.
///
/// Bố cục bám sát `isSplash` của design handoff: khối giữa (vòng đèn → wordmark → slogan) được
/// canh giữa màn theo kiểu flexbox, còn quầng sáng / ripple / tia sáng neo theo tỉ lệ
/// chiều cao màn. Màn này đi qua bộ token `--il-spl-*` nên đảo màu theo light/dark.
final class ILSplashViewController: BaseViewController {

    // MARK: - Spec
    private enum Metrics {
        /// Vòng đèn 96px — tỉ lệ vòng/lửa nằm trong `ILLogoView`.
        static let lampDiameter: CGFloat = 96
        /// Khoảng cách wordmark xuống từ đáy vòng đèn (`margin-top:26px`).
        static let wordmarkTopSpacing: CGFloat = 26
        /// Khoảng cách slogan xuống từ wordmark (`margin-top:12px`).
        static let taglineTopSpacing: CGFloat = 12
    }

    private enum Timing {
        /// Đủ lâu để thấy trọn nhịp bùng lửa + một nhịp thở trước khi rời màn.
        static let autoAdvanceDelay: TimeInterval = 3.2
        /// `ilignite` của design trễ 0.25s so với `ilrise` của vòng.
        static let flameIgniteDelay: TimeInterval = 0.25
        /// `ilpulse` của lửa bắt đầu sau khi bùng xong (`1.35s`).
        static let flamePulseDelay: TimeInterval = 1.35
        /// `ilrise` áp cho slogan (`0.8s ease .95s both`).
        static let taglineRiseDelay: TimeInterval = 0.95
        static let taglineRiseDuration: TimeInterval = 0.8
        /// Quãng dịch lên của `ilrise` (`translateY(10px)`).
        static let riseDistance: CGFloat = 10
    }

    // MARK: - Properties
    private let viewModel: ILSplashViewModel
    private var cancellables = Set<AnyCancellable>()
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let splashFinishedSubject = PassthroughSubject<Void, Never>()
    private var hasStartedAnimations = false

    // MARK: - UI Elements
    private let backdropView = ILSplashBrandBackdropView()
    private let ambienceView = ILSplashAmbienceView()
    private let lampGlowView = ILLogoView(size: Metrics.lampDiameter)
    private let emberFieldView = ILSplashEmberFieldView()
    private let wordmarkLabel = ILSplashWordmarkLabel(text: "splash.wordmark".localized)

    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.splashTagline
        label.textColor = ILColors.splashInkSub
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "splash.tagline".localized
        return label
    }()

    /// Khối giữa canh giữa màn theo chiều dọc — thay cho `justify-content:center` của design.
    /// Dùng layout guide thay vì `UIStackView` vì thứ tự vẽ phải là
    /// vòng đèn → hạt than → wordmark → slogan, mà stack thì ép mọi thứ liền mạch một hàng dọc.
    private let columnGuide = UILayoutGuide()

    // MARK: - Initializer
    init(viewModel: ILSplashViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // CAAnimation add trước khi view có window (vd. trong viewDidLoad) sẽ bị
        // Core Animation bỏ qua ở lần launch đầu — phải khởi động ở đây mới chắc chạy.
        guard !hasStartedAnimations else { return }
        hasStartedAnimations = true
        startBrandAnimations()
        scheduleAutoAdvance()
    }

    // MARK: - Setup
    override func setupViews() {
        super.setupViews()
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Thứ tự addSubview quyết định thứ tự vẽ, khớp đúng thứ tự phần tử trong design.
        [backdropView, ambienceView, lampGlowView, emberFieldView, wordmarkLabel, taglineLabel]
            .forEach(view.addSubview)
        view.addLayoutGuide(columnGuide)

        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    override func setupConstraints() {
        super.setupConstraints()

        // Hạt than neo vào vòng đèn — chỉ ghim được sau khi cả hai đã chung cây view.
        emberFieldView.alignEmbers(to: lampGlowView, ringDiameter: Metrics.lampDiameter)

        NSLayoutConstraint.activate([
            backdropView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Ripple/tia sáng neo theo tỉ lệ chiều cao màn nên phủ kín màn rồi tự đặt vị trí.
            ambienceView.topAnchor.constraint(equalTo: view.topAnchor),
            ambienceView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ambienceView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ambienceView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Cả khối giữa canh giữa màn: đỉnh guide là đỉnh vòng đèn, đáy guide là đáy slogan.
            columnGuide.topAnchor.constraint(equalTo: lampGlowView.topAnchor),
            columnGuide.bottomAnchor.constraint(equalTo: taglineLabel.bottomAnchor),
            columnGuide.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            lampGlowView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            emberFieldView.topAnchor.constraint(equalTo: view.topAnchor),
            emberFieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emberFieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emberFieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            wordmarkLabel.topAnchor.constraint(
                equalTo: lampGlowView.bottomAnchor,
                constant: Metrics.wordmarkTopSpacing
            ),
            wordmarkLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wordmarkLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: ILMetrics.screenHorizontal
            ),

            taglineLabel.topAnchor.constraint(
                equalTo: wordmarkLabel.bottomAnchor,
                constant: Metrics.taglineTopSpacing
            ),
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            taglineLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: ILMetrics.screenHorizontal
            ),
            taglineLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -ILMetrics.screenHorizontal
            )
        ])
    }

    override func bindViewModel() {
        super.bindViewModel()

        let input = ILSplashViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            splashFinished: splashFinishedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        // No `.receive(on: DispatchQueue.main)`: state is already sent on main (MainActor default),
        // and deferring it renders the first state only after the appear transition has run.
        output.state
            .sink { [weak self] state in self?.render(state: state) }
            .store(in: &cancellables)

        // Send after subscribing above, in the same synchronous call — PassthroughSubject
        // doesn't replay values sent before a subscriber attaches.
        viewDidLoadSubject.send(())
    }

    // MARK: - Render
    private func render(state: ViewState<ILSplashStateModel>) {
        switch state {
        case .idle, .loading, .success:
            break
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }

    // MARK: - Animations
    private func startBrandAnimations() {
        backdropView.startGlowAnimation()
        ambienceView.startAnimations()

        lampGlowView.startIgniteAnimation(
            delay: 0,
            flameDelay: Timing.flameIgniteDelay
        )
        lampGlowView.startFlickerAnimation(delay: Timing.flamePulseDelay)

        emberFieldView.startAnimations()
        wordmarkLabel.startRevealAnimation()
        startTaglineRiseAnimation()
    }

    /// `ilrise` — slogan trồi lên kèm mờ dần. Vòng đèn có bản `ilrise` riêng trong
    /// `ILLampGlowView`; đây là bản áp cho một `UILabel` trần nên viết tại chỗ.
    private func startTaglineRiseAnimation() {
        let beginTime = CACurrentMediaTime() + Timing.taglineRiseDelay

        let rise = CABasicAnimation(keyPath: "transform.translation.y")
        rise.fromValue = Timing.riseDistance
        rise.toValue = 0
        rise.duration = Timing.taglineRiseDuration
        rise.beginTime = beginTime
        rise.timingFunction = CAMediaTimingFunction(name: .easeOut)
        // Giữ trạng thái đầu (ẩn, thấp hơn 10pt) suốt `delay` thay vì hiện sẵn.
        rise.fillMode = .backwards
        rise.isRemovedOnCompletion = true
        taglineLabel.layer.add(rise, forKey: "ilRise")

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.toValue = 1
        fade.duration = Timing.taglineRiseDuration
        fade.beginTime = beginTime
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fade.fillMode = .backwards
        fade.isRemovedOnCompletion = true
        taglineLabel.layer.add(fade, forKey: "ilRiseOpacity")
    }

    private func scheduleAutoAdvance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.autoAdvanceDelay) { [weak self] in
            self?.splashFinishedSubject.send(())
        }
    }
}
