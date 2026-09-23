//
//  BaseViewController.swift
//  InnerLamp
//
//  Created by ChjpCoj on 10/9/26.
//

import UIKit

/// Class cha cho mọi ViewController trong app — build UI bằng code
/// (không dùng Storyboard/XIB), gom các hàm setup chung ở đây.
class BaseViewController: UIViewController {

    /// Field đang được focus — dùng để tính rect cần cuộn tới khi keyboard đổi kích thước.
    private weak var activeEditingField: UIView?

    private let dismissKeyboardTapFilter = DismissKeyboardTapFilter()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupConstraints()
        bindViewModel()
        setupDismissKeyboardOnTap()
        setupKeyboardAvoidance()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Tap khoảng trống ngoài keyboard/control để ẩn keyboard
    private func setupDismissKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = dismissKeyboardTapFilter
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Keyboard avoidance
    // Áp dụng chung cho mọi màn có UIScrollView + UITextField (SignUp, Login, ForgotPassword...):
    // field đang gõ luôn tự cuộn lên trên keyboard, không cần từng ViewController tự wiring.
    private func setupKeyboardAvoidance() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleTextFieldDidBeginEditing(_:)),
            name: UITextField.textDidBeginEditingNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleTextFieldDidEndEditing(_:)),
            name: UITextField.textDidEndEditingNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
    }

    @objc private func handleTextFieldDidBeginEditing(_ notification: Notification) {
        guard let field = notification.object as? UIView, field.isDescendant(of: view) else { return }
        activeEditingField = field
        scrollActiveFieldIntoView(animated: true)
    }

    @objc private func handleTextFieldDidEndEditing(_ notification: Notification) {
        guard let field = notification.object as? UIView, field === activeEditingField else { return }
        activeEditingField = nil
    }

    @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard activeEditingField != nil,
              let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }

        // Bàn phím tự trồi/hạ theo `keyboardLayoutGuide` rồi (constraint ở từng ViewController) —
        // handler này chỉ còn việc cuộn field đang gõ lên trên nó. Curve ngoài 0...3 nghĩa là
        // frame đang đổi do người dùng vuốt tương tác (`scrollView.keyboardDismissMode = .interactive`),
        // không phải bàn phím tự show/hide theo chương trình — bỏ qua để khỏi tranh cuộn với chính
        // cử chỉ vuốt của người dùng, và vì UIView.AnimationCurve ngoài range đó không map được
        // sang UIView.AnimationOptions hợp lệ.
        guard let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) else { return }

        let endFrame = view.convert(endFrameValue.cgRectValue, from: nil)
        let isShowing = endFrame.minY < view.bounds.height

        // Cùng duration/curve với keyboard để layout (keyboardLayoutGuide) và scroll animate khớp
        // nhau. Gọi layoutIfNeeded() trước — frame của scrollView sau keyboard đã có giá trị cuối
        // cùng ngay khi gọi xong, dù animation UI vẫn đang chạy — nên scrollRectToVisible tính đúng.
        // `.allowUserInteraction`: views animated by UIView.animate ignore touches otherwise, which
        // would swallow taps for the whole keyboard transition.
        let options = UIView.AnimationOptions(rawValue: UInt(curve.rawValue) << 16)
            .union([.allowUserInteraction, .beginFromCurrentState])
        UIView.animate(withDuration: duration, delay: 0, options: options) { [weak self] in
            guard let self else { return }
            self.view.layoutIfNeeded()
            if isShowing {
                self.scrollActiveFieldIntoView(animated: false)
            }
        }
    }

    /// `scrollRectToVisible` tự bỏ qua nếu rect đã nằm trọn trong vùng thấy được — nên field vốn
    /// đã nằm trên keyboard thì không bị cuộn thêm, chỉ cuộn khi thực sự bị che.
    private func scrollActiveFieldIntoView(animated: Bool) {
        guard let field = activeEditingField, let scrollView = enclosingScrollView(of: field) else { return }
        // Chỉ nới đáy rect — margin giữa field và keyboard, không cần nới phía trên field.
        let bottomMargin: CGFloat = 24
        var targetRect = field.convert(field.bounds, to: scrollView)
        targetRect.size.height += bottomMargin
        scrollView.scrollRectToVisible(targetRect, animated: animated)
    }

    private func enclosingScrollView(of view: UIView) -> UIScrollView? {
        var superview = view.superview
        while let candidate = superview {
            if let scrollView = candidate as? UIScrollView { return scrollView }
            superview = candidate.superview
        }
        return nil
    }

    /// Override để add subview
    func setupViews() {}

    /// Override để add Auto Layout constraints
    func setupConstraints() {}

    /// Override để bind ViewModel output vào UI
    func bindViewModel() {}

    func showLoading() {
        // TODO: hiện loading indicator dùng chung
    }

    func hideLoading() {
        // TODO: ẩn loading indicator
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}

/// Decides which touches may trigger "tap outside to dismiss keyboard".
///
/// Only a tap on empty space should dismiss the keyboard. A tap that lands on a control (button,
/// checkbox, text field...) must be left alone: the dismiss recognizer fires on touch-up *before*
/// the control receives its own `touchesEnded`, `endEditing` synchronously posts
/// `keyboardWillChangeFrame` and `BaseViewController` calls `layoutIfNeeded()` in response, which
/// moves views pinned to `keyboardLayoutGuide` (e.g. a footer button) out from under the finger.
/// The control then sees the touch end outside its bounds and never sends `.touchUpInside`.
///
/// A separate object (not `BaseViewController` itself) so subclasses can keep their own
/// `UIGestureRecognizerDelegate` conformance for unrelated gestures.
private final class DismissKeyboardTapFilter: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var current = touch.view
        while let candidate = current, candidate !== gestureRecognizer.view {
            if candidate is UIControl || candidate is UITextField || candidate is UITextView {
                return false
            }
            // Custom tappable views (e.g. a label with its own UITapGestureRecognizer).
            if candidate.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) == true {
                return false
            }
            current = candidate.superview
        }
        return true
    }
}
