//
//  SceneDelegate.swift
//  InnerLamp
//
//  Created by ChjpCoj on 9/9/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    /// Retained so `sceneDidEnterBackground` can reach the Core Data stack. The coordinator holds
    /// the container too, but only as its own dependency — this is the scene's own handle on it.
    private var container: DIContainer?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let navigationController = BaseNavigationController()
        
        let container = DIContainer()
        let coordinator = AppCoordinator(navigationController: navigationController, container: container)

        self.window = window
        self.appCoordinator = coordinator
        self.container = container

        window.rootViewController = navigationController
        container.themeService.apply(to: window)
        window.makeKeyAndVisible()
        
        coordinator.start()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Persist whatever the Core Data view context still has pending. Only the view context is
        // saved here — repository writes go through `performBackgroundTask`, which saves its own
        // context before returning and never leaves work for this call.
        //
        // `try?` on purpose: this is the last callback before suspension. Failing to save here is
        // worth a log, not a crash, and there is no longer a `fatalError` behind it to worry about.
        try? container?.coreDataStack.saveViewContext()
    }


}

