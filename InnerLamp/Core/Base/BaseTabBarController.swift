//
//  BaseTabBarController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// `UITabBarController` nền tảng cho toàn app.
///
/// Mặc định chuyển tab dùng `CrossFadeTransition` (UIKit không animate gì khi
/// chuyển tab nếu không tự implement). Tab nào cần hiệu ứng riêng thì conform
/// `TabTransitionProviding` trên chính view controller của tab đó.
class BaseTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
}

// MARK: - UITabBarControllerDelegate
extension BaseTabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if let providing = toVC as? TabTransitionProviding {
            return providing.tabTransition ?? CrossFadeTransition()
        }
        return CrossFadeTransition()
    }
}
