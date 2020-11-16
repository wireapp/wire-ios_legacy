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
import WireSyncEngine
import UIKit
extension UIApplicationShortcutItem {
    static let markAllAsReadType = "com.wire.shortcut.markAllAsRead"
    static let markAllAsRead = UIApplicationShortcutItem(type: markAllAsReadType,
                                                         localizedTitle: "shortcut.mark_all_as_read.title".localized,
                                                         localizedSubtitle: nil,
                                                         icon: UIApplicationShortcutIcon(type: .taskCompleted),
                                                         userInfo: nil)
}

public final class QuickActionsManager: NSObject {
    
    // MARK: - Public Property
    var sessionManager: SessionManager?
    
    // MARK: - Initialization
    public init(sessionManager: SessionManager? = nil) {
        self.sessionManager = sessionManager
        super.init()
        updateQuickActions()
    }
    
    func updateQuickActions() {
        guard Bundle.developerModeEnabled else {
            UIApplication.shared.shortcutItems = []
            return
        }

        UIApplication.shared.shortcutItems = [.markAllAsRead]
    }
    
    @objc func performAction(for shortcutItem: UIApplicationShortcutItem, completionHandler: ((Bool)->())?) {
        switch shortcutItem.type {
        case UIApplicationShortcutItem.markAllAsReadType:
            sessionManager?.markAllConversationsAsRead {
                completionHandler?(true)
            }
        default:
            break
        }
    }
}
