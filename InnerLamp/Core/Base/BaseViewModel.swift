//
//  BaseViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import Foundation

/// ViewModel không import UIKit — chỉ expose state ra ngoài qua closure,
/// ViewController subscribe vào để tự cập nhật UI. Nhờ vậy ViewModel
/// test được độc lập, không cần chạy UIKit.
protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case failure(Error)
}
