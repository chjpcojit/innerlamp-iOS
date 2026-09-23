//
//  HeroIdentifiable.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import UIKit
import ObjectiveC

/// Gắn `heroID` lên 1 view ở màn nguồn và view tương ứng ở màn đích để
/// `HeroTransition` tìm và morph frame giữa 2 view đó khi chuyển màn.
///
/// Ví dụ: ảnh thumbnail trong list và ảnh lớn ở màn chi tiết cùng gắn
/// `heroID = "product-image-\(id)"`.
extension UIView {
    private static var heroIDKey: UInt8 = 0

    var heroID: String? {
        get { objc_getAssociatedObject(self, &Self.heroIDKey) as? String }
        set { objc_setAssociatedObject(self, &Self.heroIDKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Duyệt đệ quy toàn bộ subview để tìm view có `heroID` khớp `id`.
    func findHeroView(id: String) -> UIView? {
        if heroID == id { return self }
        for subview in subviews {
            if let found = subview.findHeroView(id: id) {
                return found
            }
        }
        return nil
    }
}
