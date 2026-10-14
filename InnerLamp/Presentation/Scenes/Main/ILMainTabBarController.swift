//
//  ILMainTabBarController.swift
//  InnerLamp
//

import UIKit

/// Container chính sau khi đăng nhập: 4 trang (Trang chủ / Thư viện / Chùa / Tôi).
///
/// `UITabBar` native bị ẩn — thanh điều hướng đáy là `ILBottomNavBar` (đúng UI thiết kế) phủ
/// lên trên container. Đổi tab vẫn đi qua `UITabBarController`, nên kế thừa hiệu ứng crossfade
/// của `BaseTabBarController`.
///
/// Nút Đèn ở giữa bar là **hành động**, không phải trang (không có tab thứ 5) — xem
/// `onLampTapped`.
final class ILMainTabBarController: BaseTabBarController, TransitionProviding {

    /// Splash → Main is a crossfade rather than the default push slide.
    var pushTransition: NavigationTransitionAnimating? { CrossFadeTransition() }

    /// Thứ tự tab = thứ tự `viewControllers`. `.lamp` cố tình không có mặt ở đây.
    static let tabOrder: [ILBottomNavBar.Tab] = [.home, .lib, .sangha, .me]

    /// Chạm nút Đèn giữa bar — `ILMainTabCoordinator` gán để mở màn Thắp đèn.
    var onLampTapped: (() -> Void)?

    private lazy var bottomNav: ILBottomNavBar = {
        let bar = ILBottomNavBar(activeTab: .home)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    /// Bumped on every `setBottomNavHidden` call; lets a deferred show detect that it was superseded.
    private var requestToken = 0

    /// The transition during which a screen last asked to hide the bar. A show deferred for the same
    /// transition is dropped: the screen being revealed wants the bar hidden, whichever call came first.
    private var hideRequestTransitionID: ObjectIdentifier?

    /// Đổi tab bằng code cũng phải kéo theo trạng thái active của bar.
    override var selectedIndex: Int {
        didSet { syncBottomNav() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true

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
        // Any newer request supersedes a show that was deferred until a swipe-back settles.
        requestToken += 1
        let coordinator = (selectedViewController as? UINavigationController)?.transitionCoordinator
        if hidden {
            hideRequestTransitionID = coordinator.map { ObjectIdentifier($0 as AnyObject) }
        }
        if !hidden,
           let coordinator,
           coordinator.isInteractive || coordinator.isCancelled {
            // During an interactive swipe-back UIKit calls `viewWillDisappear` as soon as the finger moves,
            // and a cancelled swipe also sends it to the screen underneath. Showing the bar then would
            // flash it, so wait for the transition to finish and only show if it completed.
            let transitionID = ObjectIdentifier(coordinator as AnyObject)
            if coordinator.isCancelled || hideRequestTransitionID == transitionID { return }
            let token = requestToken
            coordinator.animate(alongsideTransition: nil) { [weak self] context in
                guard let self, !context.isCancelled, token == self.requestToken,
                      self.hideRequestTransitionID != transitionID else { return }
                self.applyBottomNav(hidden: false, animated: animated)
            }
            return
        }
        applyBottomNav(hidden: hidden, animated: animated)
    }

    private func applyBottomNav(hidden: Bool, animated: Bool) {
        bottomNav.isUserInteractionEnabled = !hidden
        let apply = { self.bottomNav.alpha = hidden ? 0 : 1 }
        if animated {
            UIView.animate(withDuration: 0.2, animations: apply)
        } else {
            apply()
        }
    }

    /// Chuyển tab theo lệnh từ ngoài (ví dụ avatar ở Trang chủ → tab Tôi).
    func selectTab(_ tab: ILBottomNavBar.Tab) {
        guard let index = Self.tabOrder.firstIndex(of: tab) else { return }
        selectedIndex = index
    }

    private func handleBottomNavTapped(_ tab: ILBottomNavBar.Tab) {
        guard Self.tabOrder.contains(tab) else {
            onLampTapped?()
            return
        }
        selectTab(tab)
    }

    private func syncBottomNav() {
        guard Self.tabOrder.indices.contains(selectedIndex) else { return }
        bottomNav.activeTab = Self.tabOrder[selectedIndex]
    }
}
