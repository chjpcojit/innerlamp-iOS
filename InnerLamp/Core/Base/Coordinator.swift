//
//  Coordinator.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    
    var parentCoordinator: Coordinator? {get set}
    
    func start()
}

extension Coordinator {
    /// Thêm 1 child coordinator, tự gán parent và giữ reference lại
    /// (nếu không giữ, coordinator con sẽ bị deinit ngay sau khi start()
    /// chạy xong vì không còn ai retain nó).
    func addChild(_ coordinator: Coordinator) {
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
    }

    /// Gỡ 1 child coordinator ra khỏi danh sách khi flow của nó đã xong.
    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    /// Gọi khi coordinator hiện tại đã hoàn thành flow của mình — tự gỡ
    /// mình ra khỏi parent. Coordinator cụ thể (Login, OTP...) nên gọi
    /// hàm này thay vì tự ý thao tác childCoordinators của parent.
    func finish() {
        parentCoordinator?.removeChild(self)
    }
}


protocol FinishableCoordinator: Coordinator {
    var onFinish: (() -> Void?) { get set }
}
