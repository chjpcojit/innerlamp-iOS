//
//  ILFestivalDetailErrorView.swift
//  InnerLamp
//

import UIKit

/// EN: Full-screen error block — `ILStateView` (offline / generic error) plus a retry button.
/// VI: Khối lỗi toàn màn hình — `ILStateView` (offline / lỗi chung) kèm nút "Thử lại".
final class ILFestivalDetailErrorView: UIStackView {

    /// EN: Called when the retry button is tapped.
    /// VI: Gọi khi bấm nút "Thử lại".
    var onRetry: (() -> Void)?

    // MARK: - UI Elements
    private lazy var stateView = ILStateView(kind: .error)

    private lazy var retryButton: ILButton = {
        let button = ILButton(title: "common.retry".localized, variant: .primary)
        button.onTap = { [weak self] in self?.onRetry?() }
        return button
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(for error: Error) {
        if case ILCatalogError.offline = error {
            stateView.kind = .offline
            stateView.title = "festivalDetail.error.offlineTitle".localized
        } else {
            stateView.kind = .error
            stateView.title = "festivalDetail.error.title".localized
        }
        stateView.message = error.localizedDescription
    }

    // MARK: - Setup
    private func setupViews() {
        axis = .vertical
        alignment = .fill
        spacing = ILMetrics.groupSpacing
        [stateView, retryButton].forEach { addArrangedSubview($0) }
    }
}
