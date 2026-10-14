//
//  ILFestivalDetailHeroView.swift
//  InnerLamp
//

import UIKit

/// EN: Festival hero image slot — rounded card with the remote image and an "empty" caption shown
///     when the festival has no image.
/// VI: Khung ảnh đại diện của ngày lễ — thẻ bo góc chứa ảnh từ server và nhãn "chưa có" khi không có ảnh.
final class ILFestivalDetailHeroView: UIView {

    // MARK: - UI Elements
    private lazy var imageView: ILRemoteImageView = {
        let view = ILRemoteImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.label
        label.textColor = ILColors.inkSubtle
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(imageURL: String?, emptyText: String) {
        imageView.setImage(urlString: imageURL)
        emptyLabel.text = emptyText
        emptyLabel.isHidden = imageURL?.isEmpty == false
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = ILColors.sunk2
        layer.cornerRadius = ILMetrics.radiusCardLarge
        clipsToBounds = true
        [imageView, emptyLabel].forEach { addSubview($0) }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
