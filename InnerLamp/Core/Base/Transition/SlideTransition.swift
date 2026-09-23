//
//  SlideTransition.swift
//  InnerLamp
//
//  Created by ChjpCoj on 15/9/26.
//

import UIKit

/// Hiệu ứng trượt màn hình theo 1 trong 4 hướng (giống push/pop mặc định của
/// UIKit nhưng cho phép chọn hướng khác nhau cho từng màn hình qua
/// `TransitionProviding`). View đích trượt vào từ cạnh tương ứng, view nguồn
/// trượt ra một phần (parallax) theo hướng ngược lại — giống cảm giác push
/// chuẩn của `UINavigationController`.
///
/// Cách dùng — mỗi VC tự khai báo hướng của riêng mình:
/// ```swift
/// final class SettingsViewController: BaseViewController, TransitionProviding {
///     var pushTransition: NavigationTransitionAnimating? {
///         SlideTransition(direction: .bottomToTop)
///     }
///     // popTransition không cần khai báo, tự đảo thành .topToBottom.
/// }
/// ```
final class SlideTransition: NSObject, NavigationTransitionAnimating {
    /// Hướng view đích trượt vào từ cạnh nào của màn hình.
    enum Direction {
        case rightToLeft // VC mới trượt vào từ mép phải — mặc định giống push chuẩn của iOS.
        case leftToRight // VC mới trượt vào từ mép trái — mặc định giống pop chuẩn của iOS.
        case bottomToTop
        case topToBottom

        var reversed: Direction {
            switch self {
            case .rightToLeft: return .leftToRight
            case .leftToRight: return .rightToLeft
            case .bottomToTop: return .topToBottom
            case .topToBottom: return .bottomToTop
            }
        }

        /// Vị trí bắt đầu (ngoài màn hình) của view đích, dịch chuyển từ đó về `.identity`.
        func incomingStart(in size: CGSize) -> CGAffineTransform {
            switch self {
            case .rightToLeft: return CGAffineTransform(translationX: size.width, y: 0)
            case .leftToRight: return CGAffineTransform(translationX: -size.width, y: 0)
            case .bottomToTop: return CGAffineTransform(translationX: 0, y: size.height)
            case .topToBottom: return CGAffineTransform(translationX: 0, y: -size.height)
            }
        }

        /// Vị trí kết thúc (parallax) của view nguồn khi view đích đã trượt hết vào.
        func outgoingEnd(in size: CGSize, parallaxRatio: CGFloat) -> CGAffineTransform {
            switch self {
            case .rightToLeft: return CGAffineTransform(translationX: -size.width * parallaxRatio, y: 0)
            case .leftToRight: return CGAffineTransform(translationX: size.width * parallaxRatio, y: 0)
            case .bottomToTop: return CGAffineTransform(translationX: 0, y: -size.height * parallaxRatio)
            case .topToBottom: return CGAffineTransform(translationX: 0, y: size.height * parallaxRatio)
            }
        }
    }

    private let direction: Direction
    private let duration: TimeInterval
    private let parallaxRatio: CGFloat
    private var propertyAnimator: UIViewPropertyAnimator?

    var reversed: NavigationTransitionAnimating {
        SlideTransition(direction: direction.reversed, duration: duration, parallaxRatio: parallaxRatio)
    }

    /// - Parameters:
    ///   - direction: Hướng view đích trượt vào.
    ///   - duration: Thời lượng animation.
    ///   - parallaxRatio: View nguồn trượt ra bao nhiêu % kích thước màn hình (0 = đứng yên,
    ///     giống modal cover; 0.3 = giống push chuẩn của UIKit).
    init(direction: Direction = .rightToLeft, duration: TimeInterval = 0.35, parallaxRatio: CGFloat = 0.3) {
        self.direction = direction
        self.duration = duration
        self.parallaxRatio = parallaxRatio
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    // Conform `UIViewControllerInterruptibleAnimatedTransitioning` (khai báo ngầm qua
    // `NavigationTransitionAnimating`) để `UIPercentDrivenInteractiveTransition` có thể
    // pause/resume/đảo chiều animation này một cách mượt mà thay vì chỉ tua nhanh khi hủy.
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

        let size = container.bounds.size
        toView.transform = direction.incomingStart(in: size)

        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            toView.transform = .identity
            fromVC.view.transform = self.direction.outgoingEnd(in: size, parallaxRatio: self.parallaxRatio)
        }
        animator.addCompletion { [weak self] _ in
            fromVC.view.transform = .identity
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
