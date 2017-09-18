//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import UIKit
import Classy

@objc
class AppRootViewController : UIViewController {
    
    public let mainWindow : UIWindow
    public let overlayWindow : UIWindow
    public fileprivate(set) var sessionManager : SessionManager?
    
    public fileprivate(set) var visibleViewController : UIViewController?
    fileprivate let appStateController : AppStateController
    fileprivate let classyCache : ClassyCache
    fileprivate let fileBackupExcluder : FileBackupExcluder
    fileprivate let avsLogObserver : AVSLogObserver
    fileprivate var authenticatedBlocks : [() -> Void] = []
    fileprivate let transitionQueue : DispatchQueue = DispatchQueue(label: "transitionQueue")
    fileprivate var isClassyInitialized = false
    
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        appStateController = AppStateController()
        classyCache = ClassyCache()
        fileBackupExcluder = FileBackupExcluder()
        avsLogObserver = AVSLogObserver()
        
        mainWindow = UIWindow()
        mainWindow.frame = UIScreen.main.bounds
        mainWindow.accessibilityIdentifier = "ZClientMainWindow"
        
        overlayWindow = PassthroughWindow()
        overlayWindow.backgroundColor = .clear
        overlayWindow.frame = UIScreen.main.bounds
        overlayWindow.windowLevel = UIWindowLevelStatusBar + 1
        overlayWindow.accessibilityIdentifier = "ZClientNotificationWindow"
        overlayWindow.rootViewController = NotificationWindowRootViewController()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        appStateController.delegate = self
        
        // Notification window has to be on top, so must be made visible last.  Changing the window level is
        // not possible because it has to be below the status bar.
        mainWindow.rootViewController = self
        mainWindow.makeKeyAndVisible()
        overlayWindow.makeKeyAndVisible()
        mainWindow.makeKey()
        
        configureMediaManager()
        
        if let appGroupIdentifier = Bundle.main.appGroupIdentifier {
            let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
            fileBackupExcluder.excludeLibraryFolderInSharedContainer(sharedContainerURL: sharedContainerURL)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onContentSizeCategoryChange), name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
        
        transition(to: .headless)
        
        enqueueTransition(to: appStateController.appState)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.frame = mainWindow.bounds
    }
    
    public func launch(with launchOptions : LaunchOptions) {
        let bundle = Bundle.main
        let appVersion = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
        let mediaManager = AVSMediaManager.sharedInstance()
        let analytics = Analytics.shared()
        
        SessionManager.create(
            appVersion: appVersion!,
            mediaManager: mediaManager!,
            analytics: analytics,
            delegate: appStateController,
            application: UIApplication.shared,
            launchOptions: launchOptions,
            blacklistDownloadInterval: Settings.shared().blacklistDownloadInterval)
        { sessionManager in
            self.sessionManager = sessionManager
            self.sessionManager?.localMessageNotificationResponder = self
            sessionManager.updateCallNotificationStyleFromSettings()
        }
    }
    
    func enqueueTransition(to appState: AppState) {
        
        transitionQueue.async {
            
            let transitionGroup = DispatchGroup()
            transitionGroup.enter()
            
            DispatchQueue.main.async {
                self.prepare(for: appState, completionHandler: {
                    transitionGroup.leave()
                })
            }
            
            transitionGroup.wait()
        }
        
        
        transitionQueue.async {
            
            let transitionGroup = DispatchGroup()
            transitionGroup.enter()
            
            DispatchQueue.main.async {
                self.transition(to: appState, completionHandler: {
                    transitionGroup.leave()
                })
            }
            
            transitionGroup.wait()
        }
    }
    
    func transition(to appState: AppState, completionHandler: (() -> Void)? = nil) {
        var viewController : UIViewController? = nil
        
        switch appState {
        case .blacklisted:
            viewController = BlacklistViewController()
        case .migrating:
            let launchImageViewController = LaunchImageViewController()
            launchImageViewController.showLoadingScreen()
            viewController = launchImageViewController
        case .unauthenticated(error: let error):
            UIColor.setAccentOverride(ZMUser.pickRandomAccentColor())
            mainWindow.tintColor = UIColor.accent()
            let registrationViewController = RegistrationViewController()
            registrationViewController.delegate = appStateController
            registrationViewController.signInError = error
            viewController = registrationViewController
        case .authenticated(completedRegistration: let completedRegistration):
            UIColor.setAccentOverride(.undefined)
            mainWindow.tintColor = UIColor.accent()
            executeAuthenticatedBlocks()
            let clientViewController = ZClientViewController()
            clientViewController.isComingFromRegistration = completedRegistration
            viewController = clientViewController
        case .headless:
            viewController = LaunchImageViewController()
        case .loading(account: let toAccount, from: let fromAccount):
            viewController = SkeletonViewController(from: fromAccount, to: toAccount)
        }
        
        if let viewController = viewController {
            transition(to: viewController, animated: true, completionHandler: completionHandler)
        } else {
            completionHandler?()
        }
    }
    
    
    private func dismissModalsFromAllChildren(of viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        for child in viewController.childViewControllers {
            if child.presentedViewController != nil {
                child.dismiss(animated: false, completion: nil)
            }
            dismissModalsFromAllChildren(of: child)
        }
    }
    
    func transition(to viewController : UIViewController, animated : Bool = true, completionHandler: (() -> Void)? = nil) {
        
        // If we have some modal view controllers presented in any of the (grand)children
        // of this controller they stay in memory and leak on iOS 10.
        dismissModalsFromAllChildren(of: visibleViewController)
        visibleViewController?.willMove(toParentViewController: nil)
        
        if let previousViewController = visibleViewController, animated {
        
            addChildViewController(viewController)
            transition(from: previousViewController,
                       to: viewController,
                       duration: 0.5,
                       options: .transitionCrossDissolve,
                       animations: nil,
                       completion:
                { (finished) in
                    viewController.didMove(toParentViewController: self)
                    previousViewController.removeFromParentViewController()
                    self.visibleViewController = viewController
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                    completionHandler?()
            })
        } else {
            UIView.performWithoutAnimation {
                visibleViewController?.removeFromParentViewController()
                addChildViewController(viewController)
                viewController.view.frame = view.bounds
                viewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                view.addSubview(viewController.view)
                viewController.didMove(toParentViewController: self)
                visibleViewController = viewController
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(false)
            }
            completionHandler?()
        }
    }
    
    func prepare(for appState: AppState, completionHandler: @escaping () -> Void) {
        
        if appState == .authenticated(completedRegistration: false) {
            (overlayWindow.rootViewController as? NotificationWindowRootViewController)?.transitionToLoggedInSession()
        } else {
            overlayWindow.rootViewController = NotificationWindowRootViewController()
        }
        
        if !isClassyInitialized && isClassyRequired(for: appState) {
            isClassyInitialized = true
            MagicConfig.shared()
            
            let windows = [mainWindow, overlayWindow]
            DispatchQueue.main.async {
                self.setupClassy(with: windows)
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }
    
    func isClassyRequired(for appState: AppState) -> Bool {
        switch appState {
        case .authenticated, .unauthenticated, .loading:
            return true
        default:
            return false
        }
    }
    
    func configureMediaManager() {
        guard !Settings.shared().disableAVS else { return }
        
        let mediaManager = AVSProvider.shared.mediaManager
        
        mediaManager?.configureSounds()
        mediaManager?.observeSoundConfigurationChanges()
        mediaManager?.isMicrophoneMuted = false
        mediaManager?.isSpeakerEnabled = false
    }
    
    func setupClassy(with windows: [UIWindow]) {
        
        let colorScheme = ColorScheme.default()
        colorScheme.accentColor = UIColor.accent()
        colorScheme.variant = ColorSchemeVariant(rawValue: Settings.shared().colorScheme.rawValue) ?? .light
        
        let fontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        CASStyler.default().cache = classyCache
        CASStyler.bootstrapClassy(withTargetWindows: windows)
        CASStyler.default().apply(colorScheme)
        CASStyler.default().apply(fontScheme: fontScheme)
    }
    
    func onContentSizeCategoryChange() {
        Message.invalidateMarkdownStyle()
        UIFont.wr_flushFontCache()
        NSAttributedString.wr_flushCellParagraphStyleCache()
        ConversationListCell.invalidateCachedCellSize()
        let fontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        CASStyler.default().apply(fontScheme: fontScheme)
    }
    
    public func performWhenAuthenticated(_ block : @escaping () -> Void) {
        if appStateController.appState == .authenticated(completedRegistration: false) {
            block()
        } else {
            authenticatedBlocks.append(block)
        }
    }
    
    func executeAuthenticatedBlocks() {
        while !authenticatedBlocks.isEmpty {
            authenticatedBlocks.removeFirst()()
        }
    }
    
    func reload() {
        enqueueTransition(to: .headless)
        enqueueTransition(to: self.appStateController.appState)
    }
    
}

// MARK: - Status Bar / Supported Orientations

extension AppRootViewController {
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIViewController.wr_supportedInterfaceOrientations()
    }
    
    override var prefersStatusBarHidden: Bool {
        return visibleViewController?.prefersStatusBarHidden ?? false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return visibleViewController?.preferredStatusBarStyle ?? .default
    }
    
}

extension AppRootViewController : AppStateControllerDelegate {
    
    func appStateController(transitionedTo appState: AppState) {
        enqueueTransition(to: appState)
    }
    
}

extension AppRootViewController : LocalMessageNotificationResponder {
    
    func processLocalMessage(_ notification: UILocalNotification, forSession session: ZMUserSession) {
            (self.overlayWindow.rootViewController as! NotificationWindowRootViewController).show(notification)    
    }
}
