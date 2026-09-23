//
//  ILSanghaPostListView.swift
//  InnerLamp
//

import UIKit

/// Mục "Chia sẻ của bạn đồng tu": tiêu đề mục + danh sách thẻ bài (`ILSanghaPostCardView`).
/// Dựng lại thẻ mỗi lần model đổi. Biết `ILSanghaPostModel` nên thuộc riêng màn Đạo tràng.
final class ILSanghaPostListView: UIView {

    // MARK: - Properties
    var onPostTapped: ((String) -> Void)?

    // MARK: - UI Elements
    private let sectionHeader = ILSectionHeaderView(title: "sangha.section.posts".localized)
    private let postsStack = UIStackView()

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
        sectionHeader.translatesAutoresizingMaskIntoConstraints = false

        postsStack.axis = .vertical
        postsStack.spacing = ILMetrics.spaceMedium - 2
        postsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(sectionHeader)
        addSubview(postsStack)

        NSLayoutConstraint.activate([
            sectionHeader.topAnchor.constraint(equalTo: topAnchor),
            sectionHeader.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionHeader.trailingAnchor.constraint(equalTo: trailingAnchor),

            postsStack.topAnchor.constraint(equalTo: sectionHeader.bottomAnchor, constant: ILMetrics.spaceMedium - 2),
            postsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            postsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            postsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure
    func configure(posts: [ILSanghaPostModel]) {
        postsStack.arrangedSubviews.forEach {
            postsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for post in posts {
            let card = ILSanghaPostCardView()
            card.configure(with: post)
            card.onTap = { [weak self] in self?.onPostTapped?(post.id) }
            postsStack.addArrangedSubview(card)
        }
    }
}
