//
//  ILMemorialAvatarView.swift
//  InnerLamp
//

import UIKit

/// Circular portrait of a memorial entry: the initials placeholder, or the signed photo when the
/// entry has one. The URL is passed as a string because it is short-lived state, never persisted
/// (D8); a missing/failed URL simply leaves the initials visible.
final class ILMemorialAvatarView: UIView {

    private let size: CGFloat

    private lazy var initialsView: ILAvatarView = {
        ILAvatarView(initials: "", tone: .gold, size: size)
    }()

    private lazy var remoteImageView: ILRemoteImageView = {
        let view = ILRemoteImageView(frame: .zero)
        view.backgroundColor = ILColors.goldSoft
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = size / 2
        view.isHidden = true
        return view
    }()

    init(size: CGFloat) {
        self.size = size
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// EN: The signed URL's query changes every refresh; the cache key keeps the entry id and the
    /// object path (which changes when the photo is replaced) and drops the signature.
    /// VI: Query của URL có chữ ký đổi mỗi lần; cache key giữ entry id và object path (đổi khi thay
    /// ảnh) và bỏ phần chữ ký.
    static func cacheKey(entryID: String, photoURLString: String?) -> String {
        let path = photoURLString.flatMap(URL.init(string:))?.path ?? ""
        return "memorial.photo.\(entryID)\(path)"
    }

    func configure(initials: String, photoURLString: String?, entryID: String) {
        initialsView.initials = initials
        guard let photoURLString, !photoURLString.isEmpty else {
            remoteImageView.isHidden = true
            remoteImageView.setImage(urlString: nil)
            initialsView.isHidden = false
            return
        }
        initialsView.isHidden = true
        remoteImageView.isHidden = false
        remoteImageView.setImage(
            urlString: photoURLString,
            cacheKey: Self.cacheKey(entryID: entryID, photoURLString: photoURLString)
        )
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        [initialsView, remoteImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size),
            initialsView.topAnchor.constraint(equalTo: topAnchor),
            initialsView.bottomAnchor.constraint(equalTo: bottomAnchor),
            initialsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            initialsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            remoteImageView.topAnchor.constraint(equalTo: topAnchor),
            remoteImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            remoteImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            remoteImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
