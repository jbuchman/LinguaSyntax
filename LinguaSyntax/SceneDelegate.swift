//
//  SceneDelegate.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        importText(from: connectionOptions.urlContexts)
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        importText(from: URLContexts)
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
        importPendingSharedText()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        importPendingSharedText()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func importText(from urlContexts: Set<UIOpenURLContext>) {
        guard urlContexts.contains(where: { Self.isImportURL($0.url) }) else {
            return
        }

        if let text = urlContexts.compactMap({ Self.importedText(from: $0.url) }).first {
            TextImporter.importText(text)
            rootViewController()?.settings.text = text
        } else {
            importPendingSharedText()
        }
    }

    private func importPendingSharedText() {
        guard let text = TextImporter.importPendingSharedText() else {
            return
        }

        rootViewController()?.settings.text = text
    }

    private func rootViewController() -> ViewController? {
        findViewController(in: window?.rootViewController)
    }

    private func findViewController(in viewController: UIViewController?) -> ViewController? {
        if let viewController = viewController as? ViewController {
            return viewController
        }

        if let navigationController = viewController as? UINavigationController {
            return navigationController.viewControllers.compactMap(findViewController(in:)).first
        }

        if let tabBarController = viewController as? UITabBarController {
            return tabBarController.viewControllers?.compactMap(findViewController(in:)).first
        }

        if let presentedViewController = viewController?.presentedViewController,
           let foundViewController = findViewController(in: presentedViewController) {
            return foundViewController
        }

        return viewController?.children.compactMap(findViewController(in:)).first
    }

    static func importedText(from url: URL) -> String? {
        guard isImportURL(url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let text = components.queryItems?.first(where: { $0.name == Constants.importTextQueryItem })?.value,
              !text.isEmpty else {
            return nil
        }

        return text
    }

    static func isImportURL(_ url: URL) -> Bool {
        url.scheme == Constants.importURLScheme && url.host == Constants.importURLHost
    }

}
