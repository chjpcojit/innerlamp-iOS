//
//  TransitionProviding.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Conform protocol này trên 1 `UIViewController` để tự khai báo hiệu ứng
/// chuyển cảnh riêng khi nó được push/pop trong `BaseNavigationController`.
/// `BaseNavigationController` kiểm tra động (`decidingVC as? TransitionProviding`)
/// từng VC cụ thể tại thời điểm chuyển cảnh, nên màn A và màn B hoàn toàn có thể
/// dùng 2 hiệu ứng khác nhau mà không cần khai báo tập trung ở đâu cả.
///
/// Không conform (hoặc trả `nil`) → dùng `SlideTransition(.rightToLeft)` mặc định
/// (giống push chuẩn của UIKit). Cách này để NavigationController không cần biết
/// trước danh sách hiệu ứng cụ thể, màn hình nào cần custom thì tự khai báo tại chỗ.
///
/// Ví dụ — mỗi màn tự chọn hiệu ứng riêng của mình:
/// ```swift
/// final class SettingsViewController: BaseViewController, TransitionProviding {
///     var pushTransition: NavigationTransitionAnimating? {
///         SlideTransition(direction: .bottomToTop) // Màn B: trượt từ dưới lên.
///     }
/// }
///
/// final class ProductDetailViewController: BaseViewController, TransitionProviding {
///     var pushTransition: NavigationTransitionAnimating? {
///         HeroTransition(heroID: "product-image") // Màn A: morph ảnh.
///     }
/// }
/// ```
protocol TransitionProviding {
    /// Hiệu ứng dùng khi VC này được **push** lên trên cùng stack.
    var pushTransition: NavigationTransitionAnimating? { get }

    /// Hiệu ứng dùng khi VC này bị **pop** ra khỏi stack.
    /// Mặc định dùng lại `pushTransition` (animate ngược lại) nếu không override.
    var popTransition: NavigationTransitionAnimating? { get }
}

extension TransitionProviding {
    // Mặc định đảo ngược hướng của pushTransition (VD: push trượt phải->trái thì
    // pop tự trượt trái->phải), giống hành vi push/pop mặc định của UIKit.
    var popTransition: NavigationTransitionAnimating? { pushTransition?.reversed }
}

/// Tương tự `TransitionProviding` nhưng dành cho tab được chọn trong
/// `BaseTabBarController`. Không conform → dùng `CrossFadeTransition` mặc định.
protocol TabTransitionProviding {
    var tabTransition: NavigationTransitionAnimating? { get }
}
