//
//  ILMemorialPhotoView.swift
//  InnerLamp
//

import UIKit

/// Portrait block of the add/edit form. Present only while `MemorialFeatureFlags.isPhotoEnabled`;
/// the entry's signed URL (memory only, D8) or the picked-but-not-uploaded JPEG is shown above the
/// initials fallback.
final class ILMemorialPhotoView: UIView {

    var onPick: (() -> Void)?
    var onRemove: (() -> Void)?

    private let size: CGFloat = 104

    private lazy var portraitContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var initialsView: ILAvatarView = {
        ILAvatarView(initials: "", tone: .gold, size: size)
    }()

    private lazy var remoteImageView: ILRemoteImageView = {
        let view = ILRemoteImageView(frame: .zero)
        view.backgroundColor = ILColors.goldSoft
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private lazy var previewImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = size / 2
        view.isHidden = true
        return view
    }()

    private lazy var pickButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.subheadMedium
        button.setTitleColor(ILColors.link, for: .normal)
        button.addTarget(self, action: #selector(handlePick), for: .touchUpInside)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ILTypography.subhead
        button.setTitleColor(ILColors.inkSubtle, for: .normal)
        button.setTitle("memorial.edit.photo.remove".localized, for: .normal)
        button.addTarget(self, action: #selector(handleRemove), for: .touchUpInside)
        return button
    }()

    private lazy var buttonRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [pickButton, removeButton])
        stack.axis = .horizontal
        stack.spacing = ILMetrics.spaceMedium
        return stack
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API
    func configure(
        initials: String,
        photoURLString: String?,
        preview: UIImage?,
        canRemove: Bool,
        entryID: String
    ) {
        initialsView.initials = initials
        removeButton.isHidden = !canRemove
        pickButton.setTitle(
            (photoURLString != nil || preview != nil)
                ? "memorial.edit.photo.change".localized
                : "memorial.edit.photo.add".localized,
            for: .normal
        )

        previewImageView.image = preview
        previewImageView.isHidden = preview == nil
        let hasRemote = preview == nil && photoURLString != nil
        remoteImageView.isHidden = !hasRemote
        remoteImageView.setImage(
            urlString: hasRemote ? photoURLString : nil,
            cacheKey: hasRemote
                ? ILMemorialAvatarView.cacheKey(entryID: entryID, photoURLString: photoURLString)
                : nil
        )
        initialsView.isHidden = preview != nil || hasRemote
    }

    // MARK: - Setup
    private func setupViews() {
        portraitContainer.translatesAutoresizingMaskIntoConstraints = false
        initialsView.translatesAutoresizingMaskIntoConstraints = false
        remoteImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        [initialsView, remoteImageView, previewImageView].forEach(portraitContainer.addSubview)
        [portraitContainer, buttonRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            portraitContainer.topAnchor.constraint(equalTo: topAnchor),
            portraitContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            portraitContainer.widthAnchor.constraint(equalToConstant: size),
            portraitContainer.heightAnchor.constraint(equalToConstant: size),

            initialsView.topAnchor.constraint(equalTo: portraitContainer.topAnchor),
            initialsView.bottomAnchor.constraint(equalTo: portraitContainer.bottomAnchor),
            initialsView.leadingAnchor.constraint(equalTo: portraitContainer.leadingAnchor),
            initialsView.trailingAnchor.constraint(equalTo: portraitContainer.trailingAnchor),
            remoteImageView.topAnchor.constraint(equalTo: portraitContainer.topAnchor),
            remoteImageView.bottomAnchor.constraint(equalTo: portraitContainer.bottomAnchor),
            remoteImageView.leadingAnchor.constraint(equalTo: portraitContainer.leadingAnchor),
            remoteImageView.trailingAnchor.constraint(equalTo: portraitContainer.trailingAnchor),
            previewImageView.topAnchor.constraint(equalTo: portraitContainer.topAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: portraitContainer.bottomAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: portraitContainer.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: portraitContainer.trailingAnchor),

            buttonRow.topAnchor.constraint(equalTo: portraitContainer.bottomAnchor, constant: ILMetrics.spaceMedium),
            buttonRow.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonRow.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func handlePick() {
        onPick?()
    }

    @objc private func handleRemove() {
        onRemove?()
    }
}
