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

// MARK: - ObserverTokenStore
protocol ObserverTokenStore: AnyObject {
    func addObserverToken(_ token: NSObjectProtocol)
}

// MARK: - ApplicationStateObserving
protocol ApplicationStateObserving: ObserverTokenStore {
    func applicationDidBecomeActive()
    func applicationDidEnterBackground()
    func applicationWillEnterForeground()
}

extension ApplicationStateObserving {
    func applicationDidBecomeActive() {}
    func applicationDidEnterBackground() {}
    func applicationWillEnterForeground() {}
    
    func setupApplicationNotifications() {
        addObserverToken(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                object: nil,
                                                                queue: nil) { [weak self] _ in
            guard let observer = self else { return }
            observer.applicationDidEnterBackground()
        })
        
        addObserverToken(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                                object: nil,
                                                                queue: nil) { [weak self] _ in
            guard let observer = self else { return }
            observer.applicationDidBecomeActive()
        })

        addObserverToken(NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                object: nil,
                                                                queue: nil) { [weak self] _ in
            guard let observer = self else { return }
            observer.applicationWillEnterForeground()
        })
    }
}

// MARK: - ContentSizeCategoryObserving
protocol ContentSizeCategoryObserving: ObserverTokenStore {
    func contentSizeCategoryDidChange()
}

extension ContentSizeCategoryObserving {
    func setupContentSizeCategoryNotifications() {
        addObserverToken(NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification,
                                                                object: nil,
                                                                queue: nil) { [weak self] _ in
            guard let observer = self else { return }
            observer.contentSizeCategoryDidChange()
        })
    }
}

// MARK: - AudioPermissionsObserving
extension Notification.Name {
    static let UserGrantedAudioPermissions = Notification.Name("UserGrantedAudioPermissionsNotification")
}

protocol AudioPermissionsObserving: ObserverTokenStore {
    func userDidGrantAudioPermissions()
}

extension AudioPermissionsObserving {
    func setupAudioPermissionsNotifications() {
        addObserverToken(NotificationCenter.default.addObserver(forName: Notification.Name.UserGrantedAudioPermissions,
                                                                object: nil,
                                                                queue: nil) { [weak self] _ in
            guard let observer = self else { return }
            observer.userDidGrantAudioPermissions()
        })
    }
}
