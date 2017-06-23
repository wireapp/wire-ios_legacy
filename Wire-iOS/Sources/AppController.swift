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
import WireSyncEngine
import avs

extension AppController {
    
    @objc
    public func loadAccount() {
        
        let bundle = Bundle.main
        let appVersion = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
        let groupIdentifier = "group.\(bundle.bundleIdentifier!)"
        
        if let sharedContainerURL = ZMUserSession.sharedContainerDirectory(forApplicationGroup: groupIdentifier) {
            fileBackupExcluder.excludeLibraryFolderInSharedContainer(sharedContainerURL: sharedContainerURL)
        }
    
        let mediaManager = AVSMediaManager.sharedInstance()
        let analytics = Analytics.shared()
        accountManager = AccountManager(appGroupIdentifier: groupIdentifier, appVersion: appVersion!, mediaManager: mediaManager!, analytics: analytics, delegate: self)
    }
    
}


extension AppController : AccountStateDelegate {
    
    public func unauthenticatedSessionCreated(session: UnauthenticatedSession) {
        
    }
    
    public func userSessionCreated(session: ZMUserSession) {
        setupUserSession(session)
    }
        
}
