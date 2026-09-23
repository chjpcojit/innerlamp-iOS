//
//  HeroTransition.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// Hiệu ứng morph 1 shared element giữa 2 màn hình (VD: thumbnail phóng to
/// thành ảnh chi tiết). Chỉ hỗ trợ **đúng 1 view** khớp `heroID` mỗi lần
/// chuyển cảnh — đủ cho phần lớn use case thực tế; cần morph nhiều view cùng
/// lúc thì viết animator riêng conform `NavigationTransitionAnimating`.
///
/// Cách dùng: gắn cùng 1 `heroID` lên view nguồn và view đích (xem
/// `UIView.heroID` trong `HeroIdentifiable.swift`), rồi khai báo trên VC đích:
/// ```swift
/// var pushTransition: NavigationTransitionAnimating? {
///     HeroTransition(heroID: "product-image")
/// }
/// ```
final class HeroTransition: NSObject, NavigationTransitionAnimating {
    private let heroID: String
    private let duration: TimeInterval

    /// Morph phức tạp khi bị ngắt giữa chừng (vuốt hủy) nên tắt interactive cho an toàn.
    var supportsInteractiveDismissal: Bool { false }

    init(heroID: String, duration: TimeInterval = 0.35) {
        self.heroID = heroID
        self.duration = duration
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let fromHeroView = fromVC.view.findHeroView(id: heroID),
              let toHeroView = toVC.view.findHeroView(id: heroID),
              let heroSnapshot = fromHeroView.snapshotView(afterScreenUpdates: false) else {
            // Không tìm thấy đủ 2 view khớp heroID -> fallback crossfade, không crash.
            CrossFadeTransition(duration: duration).animateTransition(using: transitionContext)
            return
        }

        let container = transitionContext.containerView
        let toView = toVC.view!
        toView.frame = transitionContext.finalFrame(for: toVC)
        container.addSubview(toView)
        toVC.view.layoutIfNeeded()

        let startFrame = fromHeroView.convert(fromHeroView.bounds, to: container)
        let endFrame = toHeroView.convert(toHeroView.bounds, to: container)

        toView.alpha = 0
        fromHeroView.isHidden = true
        toHeroView.isHidden = true

        heroSnapshot.frame = startFrame
        heroSnapshot.layer.cornerRadius = fromHeroView.layer.cornerRadius
        heroSnapshot.layer.masksToBounds = true
        container.addSubview(heroSnapshot)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: .curveEaseInOut,
            animations: {
                heroSnapshot.frame = endFrame
                heroSnapshot.layer.cornerRadius = toHeroView.layer.cornerRadius
                toView.alpha = 1
            },
            completion: { _ in
                fromHeroView.isHidden = false
                toHeroView.isHidden = false
                heroSnapshot.removeFromSuperview()
                // Phòng hờ trường hợp hiếm bị hủy giữa chừng (dù `supportsInteractiveDismissal`
                // đã là `false`): gỡ toView khỏi containerView để tránh view "rác" còn sót lại.
                if transitionContext.transitionWasCancelled {
                    toView.removeFromSuperview()
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
