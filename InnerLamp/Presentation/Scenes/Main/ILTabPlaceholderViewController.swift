//
//  ILTabPlaceholderViewController.swift
//  InnerLamp
//

import UIKit

/// Chỗ giữ chỗ cho tab chưa có màn thật (Đạo tràng, Tôi). Thay bằng màn thật
/// (`il-screen-builder`) rồi xoá file này khi không còn tab nào dùng.
final class ILTabPlaceholderViewController: BaseViewController {

    private let navTab: ILBottomNavBar.Tab

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ILTypography.displayMedium
        label.textColor = ILColors.ink
        label.textAlignment = .center
        label.text = navTab.title
        return label
    }()

    init(tab: ILBottomNavBar.Tab) {
        self.navTab = tab
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = ILColors.canvas
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
