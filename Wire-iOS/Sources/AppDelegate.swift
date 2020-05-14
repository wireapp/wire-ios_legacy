//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

    var window: UIWindow? {
        get {
            return rootViewController?.mainWindow
        }
        
        set {
            assert(true, "cannot set window")
        }
    }
    
    // Singletons
    var unauthenticatedSession: UnauthenticatedSession? {
        return SessionManager.shared?.unauthenticatedSession
    }
    
    var callWindowRootViewController: CallWindowRootViewController? {
        return rootViewController?.callWindow.rootViewController as? CallWindowRootViewController
    }
    
    var notificationsWindow: UIWindow? {
        return rootViewController?.overlayWindow
    }

    private(set) var rootViewController: AppRootViewController!
    private(set) var launchType: ApplicationLaunchType = .unknown
    var appCenterInitCompletion: Completion?
    
    var launchOptions: [AnyHashable : Any] = [:]
    
    private static var sharedAppDelegate: AppDelegate!

    static var shared: AppDelegate {
        return sharedAppDelegate!
    }

    var mediaPlaybackManager: MediaPlaybackManager? {
        return (rootViewController.visibleViewController as? ZClientViewController)?.mediaPlaybackManager
    }

    // When running production code, this should always be true to ensure that we set the self user provider
    // on the `SelfUser` helper. The `TestingAppDelegate` subclass should override this with `false` in order
    // to require explict configuration of the self user.
    
    var shouldConfigureSelfUserProvider: Bool {
        return true
    }
    
    override init() {
        super.init()
        AppDelegate.sharedAppDelegate = self
    }
    
    func setupBackendEnvironment() {
        guard let backendTypeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() else {
            return
        }
        AutomationHelper.sharedHelper.persistBackendTypeOverrideIfNeeded(with: backendTypeOverride)
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        zmLog.info("application:willFinishLaunchingWithOptions \(String(describing: launchOptions)) (applicationState = \(application.applicationState.rawValue))")
        
        // Initial log line to indicate the client version and build
        zmLog.info("Wire-ios version \(String(describing: Bundle.main.infoDictionary?["CFBundleShortVersionString"])) (\(String(describing: Bundle.main.infoDictionary?[kCFBundleVersionKey as String])))")
        
        // Note: if we instantiate the root view controller (& windows) any earlier,
        // the windows will not receive any info about device orientation.
        rootViewController = AppRootViewController()
        
        PerformanceDebugger.shared.start()
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ZMSLog.switchCurrentLogToPrevious()
        
        zmLog.info("application:didFinishLaunchingWithOptions START \(String(describing: launchOptions)) (applicationState = \(application.applicationState.rawValue))")
        
        setupBackendEnvironment()
        
        setupTracking()
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionDidBecomeAvailable(_:)), name: Notification.Name.ZMUserSessionDidBecomeAvailable, object: nil)
        
        setupAppCenter() {
            self.rootViewController?.launch(with: launchOptions ?? [:])
        }
        
        if let launchOptions = launchOptions {
            self.launchOptions = launchOptions
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
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return open(url: url, options: options)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        zmLog.info("applicationWillTerminate:  (applicationState = \(application.applicationState.rawValue))")
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        rootViewController?.quickActionsManager?.performAction(for: shortcutItem, completionHandler: completionHandler)
    }
    
    func setupTracking() {
        let containsConsoleAnalytics = ProcessInfo.processInfo.arguments.contains(AnalyticsProviderFactory.ZMConsoleAnalyticsArgumentKey)
        
        let trackingManager = TrackingManager.shared
        
        AnalyticsProviderFactory.shared.useConsoleAnalytics = containsConsoleAnalytics
        Analytics.loadShared(withOptedOut: trackingManager.disableCrashAndAnalyticsSharing)
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
        trackErrors()
    }
    
    // MARK: - URL handling
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        zmLog.info("application:continueUserActivity:restorationHandler: \(userActivity)")
        
        return (SessionManager.shared?.continueUserActivity(userActivity)) ?? false
    }
    
    // MARK : - BackgroundUpdates
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        zmLog.info("application:didReceiveRemoteNotification:fetchCompletionHandler: notification: \(userInfo)")
        
        launchType = (application.applicationState == .inactive || application.applicationState == .background) ? .push : .direct
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        zmLog.info("application:performFetchWithCompletionHandler:")
        
        rootViewController?.performWhenAuthenticated() {
            ZMUserSession.shared()?.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        zmLog.info("application:handleEventsForBackgroundURLSession:completionHandler: session identifier: \(identifier)")
        
        rootViewController?.performWhenAuthenticated() {
            ZMUserSession.shared()?.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
        }
    }
}
