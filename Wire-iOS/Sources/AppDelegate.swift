//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit
import WireCommonComponents
import WireSyncEngine
import avs

enum ApplicationLaunchType {
    case unknown
    case direct
    case push
    case url
    case registration
    case passwordReset
}

extension Notification.Name {
    static let ZMUserSessionDidBecomeAvailable = Notification.Name("ZMUserSessionDidBecomeAvailableNotification")
}

private let zmLog = ZMSLog(tag: "AppDelegate")

class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Private Property
    private var launchOperations: [LaunchSequenceOperation] = [
        BackendEnvironmentOperation(),
        TrackingOperation(),
        AppCenterOperation(),
        PerformanceDebuggerOperation(),
        ZMSLogOperation(),
        AVSLoggingOperation(),
        AutomationHelperOperation(),
        MediaManagerOperation(),
        FileBackupExcluderOperation(),
        APIVersionOperation(),
        FontSchemeOperation(),
        VoIPPushHelperOperation(),
        CleanUpDebugStateOperation()
    ]
    private var appStateCalculator = AppStateCalculator()

    // MARK: - Private Set Property
    private(set) var appRootRouter: AppRootRouter?
    private(set) var launchType: ApplicationLaunchType = .unknown

    // MARK: - Public Set Property
    var window: UIWindow?

    // Singletons
    var unauthenticatedSession: UnauthenticatedSession? {
        return SessionManager.shared?.unauthenticatedSession
    }

    var appCenterInitCompletion: Completion?
    var launchOptions: LaunchOptions = [:]

    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    var mediaPlaybackManager: MediaPlaybackManager? {
        return appRootRouter?.rootViewController
            .firstChild(ofType: ZClientViewController.self)?.mediaPlaybackManager
    }

    // When running production code, this should always be true to ensure that we set the self user provider
    // on the `SelfUser` helper. The `TestingAppDelegate` subclass should override this with `false` in order
    // to require explict configuration of the self user.

    var shouldConfigureSelfUserProvider: Bool {
        return true
    }

    override init() {
        super.init()
    }

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        zmLog.info("application:willFinishLaunchingWithOptions \(String(describing: launchOptions)) (applicationState = \(application.applicationState.rawValue))")

        // Initial log line to indicate the client version and build
        zmLog.info("Wire-ios version \(String(describing: Bundle.main.shortVersionString)) (\(String(describing: Bundle.main.infoDictionary?[kCFBundleVersionKey as String])))")

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SessionManager.shared?.updateDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        ZMSLog.switchCurrentLogToPrevious()

        zmLog.info("application:didFinishLaunchingWithOptions START \(String(describing: launchOptions)) (applicationState = \(application.applicationState.rawValue))")

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userSessionDidBecomeAvailable(_:)),
                                               name: Notification.Name.ZMUserSessionDidBecomeAvailable,
                                               object: nil)

        self.launchOptions = launchOptions ?? [:]

        if UIApplication.shared.isProtectedDataAvailable || ZMPersistentCookieStorage.hasAccessibleAuthenticationCookieData() {
            createAppRootRouterAndInitialiazeOperations(launchOptions: launchOptions ?? [:])
        }

        zmLog.info("application:didFinishLaunchingWithOptions END \(String(describing: launchOptions))")
        zmLog.info("Application was launched with arguments: \(ProcessInfo.processInfo.arguments)")

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        zmLog.info("applicationWillEnterForeground: (applicationState = \(application.applicationState.rawValue)")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        zmLog.info("applicationDidBecomeActive (applicationState = \(application.applicationState.rawValue))")

        switch launchType {
        case .url,
             .push:
            break
        default:
            launchType = .direct
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        zmLog.info("applicationWillResignActive:  (applicationState = \(application.applicationState.rawValue))")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        zmLog.info("applicationDidEnterBackground:  (applicationState = \(application.applicationState.rawValue))")

        launchType = .unknown

        UserDefaults.standard.synchronize()
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appRootRouter?.openDeepLinkURL(url) ?? false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        zmLog.info("applicationWillTerminate:  (applicationState = \(application.applicationState.rawValue))")
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        appRootRouter?.performQuickAction(for: shortcutItem,
                                          completionHandler: completionHandler)
    }

    @objc
    func userSessionDidBecomeAvailable(_ notification: Notification?) {
        launchType = .direct
        if launchOptions[UIApplication.LaunchOptionsKey.url] != nil {
            launchType = .url
        }

        if launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
            launchType = .push
        }
    }

    // MARK: - URL handling

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        zmLog.info("application:continueUserActivity:restorationHandler: \(userActivity)")

        return SessionManager.shared?.continueUserActivity(userActivity) ?? false
    }

    // MARK: - BackgroundUpdates

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        zmLog.info("application:didReceiveRemoteNotification:fetchCompletionHandler: notification: \(userInfo)")

        launchType = (application.applicationState == .inactive || application.applicationState == .background) ? .push : .direct
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        zmLog.info("application:performFetchWithCompletionHandler:")

        appRootRouter?.performWhenAuthenticated {
            ZMUserSession.shared()?.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        zmLog.info("application:handleEventsForBackgroundURLSession:completionHandler: session identifier: \(identifier)")

        appRootRouter?.performWhenAuthenticated {
            ZMUserSession.shared()?.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
        }
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        guard appRootRouter == nil else { return }
        createAppRootRouterAndInitialiazeOperations(launchOptions: launchOptions)
    }
}

// MARK: - Private Helpers
private extension AppDelegate {
    private func createAppRootRouterAndInitialiazeOperations(launchOptions: LaunchOptions) {
        createAppRootRouter(launchOptions: launchOptions)
        queueInitializationOperations(launchOptions: launchOptions)
    }

    private func createAppRootRouter(launchOptions: LaunchOptions) {
        guard let viewController = window?.rootViewController as? RootViewController else {
            fatalError("rootViewController is not of type RootViewController")
        }

        guard let sessionManager = createSessionManager(launchOptions: launchOptions) else {
            fatalError("sessionManager is not created")
        }

        let navigator = Navigator(NoBackTitleNavigationController())
        appRootRouter = AppRootRouter(viewController: viewController,
                                      navigator: navigator,
                                      sessionManager: sessionManager,
                                      appStateCalculator: appStateCalculator)
    }

    private func createSessionManager(launchOptions: LaunchOptions) -> SessionManager? {
        guard
            let appVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String,
            let url = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let configuration = SessionManagerConfiguration.load(from: url),
            let mediaManager = AVSMediaManager.sharedInstance()
        else {
            return nil
        }

        configuration.blacklistDownloadInterval = Settings.shared.blacklistDownloadInterval
        let jailbreakDetector = JailbreakDetector()

        /// get maxNumberAccounts form SecurityFlags or SessionManager.defaultMaxNumberAccounts if no MAX_NUMBER_ACCOUNTS flag defined
        let maxNumberAccounts = SecurityFlags.maxNumberAccounts.intValue ?? SessionManager.defaultMaxNumberAccounts

        return SessionManager(
            maxNumberAccounts: maxNumberAccounts,
            appVersion: appVersion,
            mediaManager: mediaManager,
            analytics: Analytics.shared,
            delegate: appStateCalculator,
            application: UIApplication.shared,
            environment: BackendEnvironment.shared,
            configuration: configuration,
            detector: jailbreakDetector,
            requiredPushTokenType: requiredPushTokenType
        )
    }

    private func queueInitializationOperations(launchOptions: LaunchOptions) {
        var operations = launchOperations.map {
            BlockOperation(block: $0.execute)
        }

        operations.append(BlockOperation {
            self.startAppRouter(launchOptions: launchOptions)
        })

        OperationQueue.main.addOperations(operations, waitUntilFinished: false)
    }

    private func startAppRouter(launchOptions: LaunchOptions) {
        appRootRouter?.start(launchOptions: launchOptions)
    }

    private var requiredPushTokenType: PushToken.TokenType {
        // From iOS 14 our "unrestricted-voip" entitlement is no longer supported,
        // so users should register for standard push tokens instead and use the
        // notification service extension.
        if #available(iOS 14.0, *) {
            return .standard
        } else {
            return .voip
        }
    }

}
