//
//  ILArticlesStateModel.swift
//  InnerLamp
//

import Foundation

/// One article row in the "All articles" list — a presentation copy of `ILArticlesItemEntity`
/// with the "… phút đọc" string already formatted for the view layer.
struct ILArticlesArticleModel: Equatable, Identifiable {
    let id: String
    let category: String
    let title: String
    let author: String
    let readText: String
    var thumbnailURL: String? = nil
}

/// UI state for the "All articles" screen — Presentation layer, owned and mutated exclusively by
/// `ILArticlesViewModel`. No UIKit import, no business logic — the view only reads this to render.
/// The load-more footer state is derived by the ViewController from `isLoadingMore` / `hasMore`
/// (mapped onto `ILLoadMoreFooterView.State` there).
struct ILArticlesStateModel: Equatable {
    /// Header subtitle ("5 / 60 bài") already formatted.
    var subtitle: String = ""
    var articles: [ILArticlesArticleModel] = []
    var isLoadingMore: Bool = false
    var hasMore: Bool = false

    static let initial = ILArticlesStateModel()
}
