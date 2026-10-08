//
//  ILPhotoViewerViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILPhotoViewerNavEvent: Equatable {
    /// Nút × — đóng viewer, quay về lưới.
    case close
}

protocol ILPhotoViewerViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — coordinator subscribe trong `start()`.
    var navigationEventPublisher: AnyPublisher<ILPhotoViewerNavEvent, Never> { get }
}

final class ILPhotoViewerViewModel: ILPhotoViewerViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let closeTapped: AnyPublisher<Void, Never>
        let previousTapped: AnyPublisher<Void, Never>
        let nextTapped: AnyPublisher<Void, Never>
        let favoriteTapped: AnyPublisher<Void, Never>
        let actionTapped: AnyPublisher<ILPhotoViewerAction, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILPhotoViewerStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILPhotoViewerNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILPhotoViewerNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILPhotoViewerStateModel>, Never>
    private let items: [ILPhotoViewerItemModel]
    private let toastDuration: TimeInterval
    private var index: Int
    private var favoriteIDs: Set<String> = []
    private var toast = ""
    private var toastTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    /// Fails when `startID` is not in `items` (nothing sensible to show).
    init?(items: [ILPhotoViewerItemModel], startID: String, toastDuration: TimeInterval = 1.8) {
        guard let startIndex = items.firstIndex(where: { $0.id == startID }) else { return nil }
        self.items = items
        self.index = startIndex
        self.toastDuration = toastDuration
        self.stateSubject = CurrentValueSubject(.success(Self.makeState(items: items, index: startIndex, favorites: [], toast: "")))
    }

    deinit {
        toastTask?.cancel()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.closeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.close) }
            .store(in: &cancellables)

        input.previousTapped
            .sink { [weak self] _ in self?.step(by: -1) }
            .store(in: &cancellables)

        input.nextTapped
            .sink { [weak self] _ in self?.step(by: 1) }
            .store(in: &cancellables)

        input.favoriteTapped
            .sink { [weak self] _ in self?.toggleFavorite() }
            .store(in: &cancellables)

        input.actionTapped
            .sink { [weak self] action in self?.handle(action) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func step(by delta: Int) {
        let target = index + delta
        guard items.indices.contains(target) else { return }
        index = target
        toastTask?.cancel()
        publish(toast: "")
    }

    private func toggleFavorite() {
        let id = items[index].id
        let isOn = favoriteIDs.insert(id).inserted
        if !isOn { favoriteIDs.remove(id) }
        showToast((isOn ? "photoViewer.toast.favoriteOn" : "photoViewer.toast.favoriteOff").localized)
    }

    private func handle(_ action: ILPhotoViewerAction) {
        // @ai: save / set wallpaper / share are stubs — see Docs/Tech-Debt/PhotoViewer/TD-PhotoViewer-001
        print("TODO: ILPhotoViewerViewModel.handle(\(action)) — real save/share not implemented")
        switch action {
        case .save: showToast("photoViewer.toast.saved".localized)
        case .setWallpaper: showToast("photoViewer.toast.wallpaperSet".localized)
        case .share: showToast("photoViewer.toast.shared".localized)
        }
    }

    /// Shows `text` under the actions and clears it after `toastDuration`; a newer toast replaces it.
    private func showToast(_ text: String) {
        toastTask?.cancel()
        publish(toast: text)
        let duration = toastDuration
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.publish(toast: "")
        }
    }

    private func publish(toast: String) {
        self.toast = toast
        stateSubject.send(.success(Self.makeState(items: items, index: index, favorites: favoriteIDs, toast: toast)))
    }

    private static func makeState(
        items: [ILPhotoViewerItemModel],
        index: Int,
        favorites: Set<String>,
        toast: String
    ) -> ILPhotoViewerStateModel {
        let item = items[index]
        return ILPhotoViewerStateModel(
            item: item,
            counter: String(format: "photoViewer.counter".localized, index + 1, items.count),
            hasPrevious: index > 0,
            hasNext: index < items.count - 1,
            isFavorite: favorites.contains(item.id),
            toast: toast
        )
    }
}
