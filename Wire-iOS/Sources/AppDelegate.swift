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

import Foundation

let ZMUserSessionDidBecomeAvailableNotification = "ZMUserSessionDidBecomeAvailableNotification"
//private var ZM_UNUSED = "UI"

///TODO:
private var sharedAppDelegate: AppDelegate? = nil

//@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow!
    // Singletons
    private(set) var unauthenticatedSession: UnauthenticatedSession?
    private(set) var rootViewController: AppRootViewController!
    private(set) var callWindowRootViewController: CallWindowRootViewController?
    private(set) var notificationsWindow: UIWindow?
    private(set) var launchType: ApplicationLaunchType?
    var appCenterInitCompletion: () -> ()?
    
    var rootViewController: AppRootViewController?
    var launchType: ApplicationLaunchType?
    var launchOptions: [AnyHashable : Any] = [:]

    class var shared: AppDelegate {
        return sharedAppDelegate!
    }

    @objc
    var mediaPlaybackManager: MediaPlaybackManager? {
        return (rootViewController.visibleViewController as? ZClientViewController)?.mediaPlaybackManager
    }
    
    init() {
        super.init()
        sharedAppDelegate = self
    }
    
    func setupBackendEnvironment() {
        let BackendEnvironmentTypeKey = "ZMBackendEnvironmentType"
        let backendEnvironment = UserDefaults.standard.string(forKey: BackendEnvironmentTypeKey)
        UserDefaults.shared().set(backendEnvironment, forKey: BackendEnvironmentTypeKey)
        
        if AutomationHelper.sharedHelper.shouldPersistBackendType {
            UserDefaults.standard.set(backendEnvironment, forKey: BackendEnvironmentTypeKey)
        }
        
        if (backendEnvironment?.count ?? 0) == 0 || (backendEnvironment == "default") {
            let defaultBackend = Bundle.defaultBackend()
            
            ZMLogInfo("Backend environment is <not defined>. Using '%@'.", defaultBackend)
            UserDefaults.standard.set(defaultBackend, forKey: BackendEnvironmentTypeKey)
            UserDefaults.shared().set(defaultBackend, forKey: BackendEnvironmentTypeKey)
        } else {
            ZMLogInfo("Using '%@' backend environment", backendEnvironment)
        }
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ZMLogInfo("application:willFinishLaunchingWithOptions %@ (applicationState = %ld)", launchOptions, application.applicationState.rawValue)
        
        // Initial log line to indicate the client version and build
        ZMLogInfo("Wire-ios version %@ (%@)", Bundle.main.infoDictionary?["CFBundleShortVersionString"], Bundle.main.infoDictionary?[kCFBundleVersionKey as String])
        
        // Note: if we instantiate the root view controller (& windows) any earlier,
        // the windows will not receive any info about device orientation.
        rootViewController = AppRootViewController()
        
        PerformanceDebugger.shared.start()
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ZMSLog.switchCurrentLogToPrevious()
        
        ZMLogInfo("application:didFinishLaunchingWithOptions START %@ (applicationState = %ld)", launchOptions, application.applicationState.rawValue)
        
        setupBackendEnvironment()
        
        setupTracking()
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionDidBecomeAvailable(_:)), name: ZMUserSessionDidBecomeAvailableNotification, object: nil)
        
        setupAppCenter(withCompletion: {
            self.rootViewController?.launch(with: launchOptions)
        })
        if let launchOptions = launchOptions {
            self.launchOptions = launchOptions
        }
        
        ZMLogInfo("application:didFinishLaunchingWithOptions END %@", launchOptions)
        ZMLogInfo("Application was launched with arguments: %@", ProcessInfo.processInfo.arguments)
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        ZMLogInfo("applicationWillEnterForeground: (applicationState = %ld)", application.applicationState.rawValue)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        ZMLogInfo("applicationDidBecomeActive (applicationState = %ld)", application.applicationState.rawValue)
        
        switch launchType {
        case ApplicationLaunchURL, ApplicationLaunchPush:
            break
        default:
            launchType = ApplicationLaunchDirect
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        ZMLogInfo("applicationWillResignActive:  (applicationState = %ld)", application.applicationState.rawValue)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        ZMLogInfo("applicationDidEnterBackground:  (applicationState = %ld)", application.applicationState.rawValue)
        
        launchType = ApplicationLaunchUnknown
        
        UserDefaults.standard.synchronize()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return open(with: url, options: options)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ZMLogInfo("applicationWillTerminate:  (applicationState = %ld)", application.applicationState.rawValue)
        
        // In case of normal termination we do not need the run duration to persist
        UIApplication.shared.resetRunDuration()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        rootViewController?.quickActionsManager.performAction(for: shortcutItem, completionHandler: completionHandler)
    }
    
    func setupTracking() {
        let containsConsoleAnalytics = (ProcessInfo.processInfo.arguments as NSArray).indexOfObject(passingTest: { obj, idx, stop in
            if (obj == AnalyticsProviderFactory.zmConsoleAnalyticsArgumentKey) {
                stop = true
                return true
            }
            return false
        }) != NSNotFound
        
        let trackingManager = TrackingManager.shared()
        
        AnalyticsProviderFactory.shared().useConsoleAnalytics = containsConsoleAnalytics
        Analytics.loadShared(withOptedOut: trackingManager?.disableCrashAndAnalyticsSharing)
    }
    
    func userSessionDidBecomeAvailable(_ notification: Notification?) {
        launchType = ApplicationLaunchDirect
        if launchOptions[UIApplication.LaunchOptionsKey.url] != nil {
            launchType = ApplicationLaunchURL
        }
        
        if launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
            launchType = ApplicationLaunchPush
        }
        trackErrors()
    }
    
    // MARK: - URL handling
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        ZMLogInfo("application:continueUserActivity:restorationHandler: %@", userActivity)
        return SessionManager.shared().continue(userActivity, restorationHandler: restorationHandler)
    }
    
    // MARK: - AppController
    func unauthenticatedSession() -> UnauthenticatedSession? {
        return SessionManager.shared().unauthenticatedSession()
    }
    
    func callWindowRootViewController() -> CallWindowRootViewController? {
        return rootViewController?.callWindow.rootViewController as? CallWindowRootViewController
    }
    
    func window() -> UIWindow? {
        return rootViewController?.mainWindow
    }

    func setWindow(_ window: UIWindow?) {
        assert(true, "cannot set window")
    }
    
    func notificationsWindow() -> UIWindow? {
        return rootViewController?.overlayWindow
    }

    // MARK : - BackgroundUpdates
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ZMLogInfo("application:didReceiveRemoteNotification:fetchCompletionHandler: notification: %@", userInfo)
        launchType = (application.applicationState == .inactive || application.applicationState == .background) ? ApplicationLaunchPush : ApplicationLaunchDirect
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ZMLogInfo("application:performFetchWithCompletionHandler:")
        
        rootViewController?.perform(whenAuthenticated: {
            ZMUserSession.shared().application(application, performFetchWithCompletionHandler: completionHandler)
        })
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        ZMLogInfo("application:handleEventsForBackgroundURLSession:completionHandler: session identifier: %@", identifier)
        
        rootViewController?.perform(whenAuthenticated: {
            ZMUserSession.shared().application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
        })
    }
}
