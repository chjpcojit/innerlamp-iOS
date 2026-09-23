//
//  NavigationTransitionAnimating.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Protocol cha cho mọi hiệu ứng chuyển cảnh dùng trong `BaseNavigationController`
/// và `BaseTabBarController`. Viết hiệu ứng mới (slide, hero, zoom...) bằng cách
/// tạo 1 class conform protocol này, không cần đụng vào Base*Controller.
protocol NavigationTransitionAnimating: UIViewControllerAnimatedTransitioning {
    /// `true` nếu hiệu ứng cho phép vuốt cạnh để pop theo kiểu tương tác (percent-driven).
    /// Hiệu ứng morph phức tạp (hero) nên trả `false` vì khó xử lý đúng khi bị hủy giữa chừng.
    var supportsInteractiveDismissal: Bool { get }

    /// Hiệu ứng đảo ngược, dùng làm giá trị mặc định cho `popTransition` khi VC chỉ khai báo
    /// `pushTransition` (xem `TransitionProviding`). VD: push trượt phải-sang-trái thì
    /// `reversed` phải là trượt trái-sang-phải để pop trông tự nhiên như UIKit mặc định.
    /// Hiệu ứng không có khái niệm "hướng" (crossfade, hero) có thể bỏ qua và trả `self`.
    var reversed: NavigationTransitionAnimating { get }
}

extension NavigationTransitionAnimating {
    var supportsInteractiveDismissal: Bool { true }
    var reversed: NavigationTransitionAnimating { self }
}
