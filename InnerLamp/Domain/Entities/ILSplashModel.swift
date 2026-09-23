//
//  ILSplashModel.swift
//  InnerLamp
//

import Foundation

/// Plain state model for the Splash screen — no UIKit, no business logic.
/// Splash is a static branding moment (không có nội dung động để render),
/// nên state chỉ tồn tại để đi đúng qua ViewState<T> như mọi screen khác.
struct ILSplashStateModel {
    static let initial = ILSplashStateModel()
}
