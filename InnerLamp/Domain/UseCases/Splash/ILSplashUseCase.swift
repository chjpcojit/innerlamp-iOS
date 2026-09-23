//
//  ILSplashUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILSplashUseCase {
    func getInitialState() -> ILSplashStateModel
    /// Đã hoàn thành onboarding chưa — quyết định Splash sẽ chuyển tới Onboarding hay Main.
    func isOnboardingCompleted() -> Bool
}

/// Không tự lưu trữ gì — Splash chỉ cần đọc lại trạng thái onboarding đã có sẵn ở
/// `ILOnboardingUseCase` để quyết định điểm đến kế tiếp, tránh trùng key UserDefaults.
final class ILSplashUseCaseImpl: ILSplashUseCase {

    private let onboardingUseCase: ILOnboardingUseCase

    init(onboardingUseCase: ILOnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }

    func getInitialState() -> ILSplashStateModel {
        ILSplashStateModel.initial
    }

    func isOnboardingCompleted() -> Bool {
        onboardingUseCase.isOnboardingCompleted()
    }
}
