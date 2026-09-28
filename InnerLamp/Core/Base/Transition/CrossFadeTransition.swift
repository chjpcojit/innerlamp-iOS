//
//  CrossFadeTransition.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Hiệu ứng mặc định của `BaseTabBarController` khi tab không tự khai báo hiệu ứng riêng
/// (và có thể dùng cho push/pop nếu VC tự chọn): fade từ từ giữa 2 view.
final class CrossFadeTransition: NSObject, NavigationTransitionAnimating {
    private let duration: TimeInterval
    private var propertyAnimator: UIViewPropertyAnimator?

    init(duration: TimeInterval = 0.3) {
        self.duration = duration
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    // Conform `UIViewControllerInterruptibleAnimatedTransitioning` (khai báo ngầm qua
    // `NavigationTransitionAnimating`) để vuốt-cạnh có thể pause/resume/đảo chiều
    // animation này mượt mà thay vì chỉ tua nhanh khi hủy.
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if let existing = propertyAnimator {
            return existing
        }

        guard let toVC = transitionContext.viewController(forKey: .to),
              let fromVC = transitionContext.viewController(forKey: .from) else {
            let fallback = UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
            fallback.addCompletion { _ in transitionContext.completeTransition(false) }
            propertyAnimator = fallback
            return fallback
        }

        let container = transitionContext.containerView
        let toView = toVC.view!
        toView.frame = transitionContext.finalFrame(for: toVC)
        container.addSubview(toView)
        // Force the destination view to lay out before the fade starts. Without this, the
        // first rendered frame shows the view in its pre-layout state (e.g. a self-sized
        // card briefly stretched on the first tab appearance), which reads as a flicker.
        // Mirrors HeroTransition, which does the same to measure hero frames.
        toView.layoutIfNeeded()
        toView.alpha = 0

        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            toView.alpha = 1
            fromVC.view.alpha = 0
        }
        animator.addCompletion { [weak self] _ in
            // reset alpha để view không bị "biến mất" nếu bị push/hiện lại sau này
            fromVC.view.alpha = 1
            // Khi bị hủy, animator đảo về đầu nên view đích còn alpha = 0 — reset để lần sau không bị ẩn.
            toView.alpha = 1
            // Nếu bị hủy giữa chừng (vuốt cạnh rồi thả tay ngược lại), view đích cần được
            // gỡ khỏi containerView để không lưu lại "rác" trong cây view.
            if transitionContext.transitionWasCancelled {
                toView.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self?.propertyAnimator = nil
        }

        propertyAnimator = animator
        return animator
    }
}
