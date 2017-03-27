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

import UIKit
import ZMCDataModel

final class NewDevicesDot: UIView {
    let user: ZMUser
    var userObserverToken: NSObjectProtocol?
    var clientsObserverTokens: [NSObjectProtocol] = []
    
    var showIndicator: Bool {
        set { self.fadeAndHide(!newValue) }
        get { return !self.isHidden }
    }
    
    init(user: ZMUser) {
        self.user = user
        super.init(frame: .zero)
        self.backgroundColor = user.accentColorValue.color
        userObserverToken = UserChangeInfo.add(observer: self, forBareUser: user)
        self.createClientObservers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func createClientObservers() {
        clientsObserverTokens = user.clients.map { UserClientChangeInfo.add(observer: self, for: $0) }
    }
    
    fileprivate func updateIndicator() {
        showIndicator = user.clientsRequiringUserAttention?.count > 0
    }
}

// MARK: - User Observer

extension NewDevicesDot: ZMUserObserver {
    func userDidChange(_ note: UserChangeInfo) {
        guard note.trustLevelChanged || note.clientsChanged || note.accentColorValueChanged else { return }
        
        if note.accentColorValueChanged {
            self.backgroundColor = note.user.accentColorValue.color
        }
        updateIndicator()
        if note.clientsChanged {
            createClientObservers()
        }
    }
}

// MARK: - Clients observer

extension NewDevicesDot: UserClientObserver {
    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        guard changeInfo.needsToNotifyUserChanged else { return }
        updateIndicator()
    }
}

