//
//  ILSplashLoadingIndicatorView.swift
//  InnerLamp
//

import UIKit

/// Ba chấm vàng nhấp nháy phía dưới màn Splash — dấu hiệu duy nhất cho biết app đang chuẩn bị.
/// Bản thân composition là riêng của Splash dù `ILLoadingDotsView` bên trong dùng chung.
///
/// Design handoff (`isSplash`) chỉ có đúng hàng chấm, không kèm nhãn chữ — phần "đang chuẩn bị"
/// trước đây đã bỏ để khớp.
final class ILSplashLoadingIndicatorView: UIView {

    // MARK: - Spec
    private enum Metrics {
        /// Chấm nhỏ 5px, khoảng cách 7px (`width:5px;gap:7px` của design).
        static let dotDiameter: CGFloat = 5
        static let dotSpacing: CGFloat = 7
    }

    // MARK: - UI Elements
    private let dotsView = ILLoadingDotsView(
        dotDiameter: Metrics.dotDiameter,
        spacing: Metrics.dotSpacing,
        color: ILColors.goldBright
    )

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        addSubview(dotsView)

        NSLayoutConstraint.activate([
            dotsView.topAnchor.constraint(equalTo: topAnchor),
            dotsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dotsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dotsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Animation
    func startPulsingAnimation() {
        dotsView.startPulsingAnimation()
    }
}
