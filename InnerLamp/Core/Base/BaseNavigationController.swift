//
//  BaseNavigationController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit

/// `UINavigationController` nền tảng cho toàn app.
///
/// - Mặc định mọi push dùng `SlideTransition(.rightToLeft)` (giống push chuẩn của
///   UIKit), pop tự đảo thành `.leftToRight`.
/// - VC nào cần hiệu ứng riêng (slide hướng khác, hero, fade...) thì conform
///   `TransitionProviding` trên chính VC đó — NavigationController tự hỏi
///   `decidingVC as? TransitionProviding` ở mỗi lần chuyển cảnh để lấy đúng hiệu
///   ứng của **VC đó**, nên mỗi màn hình hoàn toàn có thể khác nhau, không cần
///   khai báo tập trung ở đây.
/// - Tự implement lại vuốt-cạnh-để-back bằng `UIScreenEdgePanGestureRecognizer`
///   + `UIPercentDrivenInteractiveTransition` vì custom animator sẽ vô hiệu hóa
///   `interactivePopGestureRecognizer` mặc định của UIKit.
class BaseNavigationController: UINavigationController {

    private var interactionController: UIPercentDrivenInteractiveTransition?

    private lazy var edgePopGesture: UIScreenEdgePanGestureRecognizer = {
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePopGesture(_:)))
        gesture.edges = .left
        gesture.delegate = self
        return gesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        // Tắt gesture mặc định của UIKit, dùng gesture riêng phía dưới để tránh
        // xung đột "double pop" giữa handler private của UIKit và handler của mình.
        interactivePopGestureRecognizer?.isEnabled = false
        view.addGestureRecognizer(edgePopGesture)
    }

    /// Hiệu ứng pop hiệu lực của VC đang ở đỉnh stack (đã tính default nếu VC
    /// không conform `TransitionProviding`), dùng để quyết định gesture vuốt-cạnh
    /// có được phép bắt đầu hay không.
    private var effectiveTopPopTransition: NavigationTransitionAnimating {
        (topViewController as? TransitionProviding)?.popTransition ?? Self.defaultTransition(for: .pop)
    }

    @objc private func handleEdgePopGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        ilDebugLog("EDGE state=\(gesture.state.rawValue) count=\(viewControllers.count)")
        let translation = gesture.translation(in: view)
        let percent = max(0, min(1, translation.x / view.bounds.width))
        ilDebugLog("EDGE state=\(gesture.state.rawValue) translation=\(translation.x) percent=\(percent)")

        switch gesture.state {
        case .began:
            // Chỉ được bắt đầu khi thật sự có màn để pop. Lưu ý: `popViewController` gỡ màn
            // khỏi stack NGAY lập tức nên các case `.changed`/`.ended` bên dưới không được
            // guard theo `viewControllers.count` nữa (sẽ luôn = 1 và bỏ hết sự kiện, khiến
            // interactive transition không bao giờ được update/finish → nav kẹt luôn).
            guard viewControllers.count > 1 else { return }
            interactionController = UIPercentDrivenInteractiveTransition()
            popViewController(animated: true)
            ilDebugLog("EDGE began -> popViewController, top=\(String(describing: topViewController))")

        case .changed:
            interactionController?.update(percent)

        case .ended, .cancelled, .failed:
            guard let interactionController else { return }
            let velocity = gesture.velocity(in: view).x
            if percent > 0.5 || velocity > 300 {
                ilDebugLog("EDGE finish velocity=\(velocity)")
                interactionController.finish()
            } else {
                ilDebugLog("EDGE cancel velocity=\(velocity)")
                interactionController.cancel()
            }
            self.interactionController = nil

        default:
            break
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension BaseNavigationController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        // Khi push: VC đích (toVC) quyết định hiệu ứng.
        // Khi pop: VC đang bị pop (fromVC) quyết định hiệu ứng (popTransition).
        let decidingVC = operation == .push ? toVC : fromVC
        ilDebugLog("ANIM operation=\(operation.rawValue) deciding=\(type(of: decidingVC))")
        if let providing = decidingVC as? TransitionProviding {
            let transition = operation == .push ? providing.pushTransition : providing.popTransition
            return transition ?? Self.defaultTransition(for: operation)
        }
        return Self.defaultTransition(for: operation)
    }

    /// Hiệu ứng dùng khi VC không tự conform `TransitionProviding`: trượt phải->trái
    /// khi push (giống push chuẩn của UIKit), tự đảo trái->phải khi pop.
    private static func defaultTransition(for operation: UINavigationController.Operation) -> NavigationTransitionAnimating {
        let push = SlideTransition(direction: .rightToLeft)
        return operation == .push ? push : push.reversed
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        ilDebugLog("INTERACTION animator=\(type(of: animationController)) hasIC=\(interactionController != nil)")
        guard let animator = animationController as? NavigationTransitionAnimating,
              animator.supportsInteractiveDismissal else {
            return nil
        }
        return interactionController
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BaseNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Không cho vuốt-cạnh bắt đầu pop nếu hiệu ứng của VC đang hiển thị không hỗ trợ
        // interactive dismissal (VD: HeroTransition) — tránh pop "giật cục" ngay khi vừa chạm.
        let isSwipeBackEnabled = (topViewController as? TransitionProviding)?.isSwipeBackEnabled ?? true
        return viewControllers.count > 1 && isSwipeBackEnabled && effectiveTopPopTransition.supportsInteractiveDismissal
    }
}
