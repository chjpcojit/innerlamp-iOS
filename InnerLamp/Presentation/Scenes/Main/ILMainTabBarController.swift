//
//  ILMainTabBarController.swift
//  InnerLamp
//

import UIKit

/// Container chính sau khi đăng nhập: 4 trang (Trang chủ / Thư viện / Đạo tràng / Tôi).
///
/// `UITabBar` native bị ẩn — thanh điều hướng đáy là `ILBottomNavBar` (đúng UI thiết kế) phủ
/// lên trên container. Đổi tab vẫn đi qua `UITabBarController`, nên kế thừa hiệu ứng crossfade
/// của `BaseTabBarController`.
///
/// Nút Đèn ở giữa bar là **hành động**, không phải trang (không có tab thứ 5) — xem
/// `onLampTapped`.
final class ILMainTabBarController: BaseTabBarController {

    /// Thứ tự tab = thứ tự `viewControllers`. `.lamp` cố tình không có mặt ở đây.
    static let tabOrder: [ILBottomNavBar.Tab] = [.home, .lib, .sangha, .me]

    /// Chạm nút Đèn giữa bar. Chưa có màn/luồng Đèn nên coordinator chưa gán.
    var onLampTapped: (() -> Void)?

    private let bottomNav = ILBottomNavBar(activeTab: .home)

    /// Đổi tab bằng code cũng phải kéo theo trạng thái active của bar.
    override var selectedIndex: Int {
        didSet { syncBottomNav() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true

        bottomNav.translatesAutoresizingMaskIntoConstraints = false
        bottomNav.onTabSelected = { [weak self] tab in self?.handleBottomNavTapped(tab) }
        view.addSubview(bottomNav)

        NSLayoutConstraint.activate([
            bottomNav.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomNav.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomNav.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // UIKit có thể chèn lại content view của tab lên trên — giữ bar luôn nổi trên cùng.
        view.bringSubviewToFront(bottomNav)
    }

    /// Ẩn/hiện `ILBottomNavBar` — dùng cho màn con phủ kín (vd. Niệm Phật) đẩy lên trên nav của tab.
    func setBottomNavHidden(_ hidden: Bool, animated: Bool) {
        bottomNav.isUserInteractionEnabled = !hidden
        let apply = { self.bottomNav.alpha = hidden ? 0 : 1 }
        if animated {
            UIView.animate(withDuration: 0.2, animations: apply)
        } else {
            apply()
        }
    }

    private func handleBottomNavTapped(_ tab: ILBottomNavBar.Tab) {
        guard let index = Self.tabOrder.firstIndex(of: tab) else {
            onLampTapped?()
            return
        }
        selectedIndex = index
    }

    private func syncBottomNav() {
        guard Self.tabOrder.indices.contains(selectedIndex) else { return }
        bottomNav.activeTab = Self.tabOrder[selectedIndex]
    }
}
