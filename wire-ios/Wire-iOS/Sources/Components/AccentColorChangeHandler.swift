//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

typealias AccentColorChangeHandlerBlock = (UIColor?, Any?) -> Void

final class AccentColorChangeHandler: NSObject, ZMUserObserver {

    private var handlerBlock: AccentColorChangeHandlerBlock?
    private var observer: Any?
    private var userObserverToken: Any?

    class func addObserver(_ observer: Any?, handlerBlock changeHandler: @escaping AccentColorChangeHandlerBlock) -> Self {
        return self.init(observer: observer, handlerBlock: changeHandler)
    }

    init(observer: Any?, handlerBlock changeHandler: @escaping AccentColorChangeHandlerBlock) {
        super.init()
        handlerBlock = changeHandler
        self.observer = observer

        if let selfUser = SelfUser.provider?.selfUser, let userSession = ZMUserSession.shared() {
            userObserverToken = UserChangeInfo.add(observer: self, for: selfUser, in: userSession)
        }
    }

    deinit {
        observer = nil
    }

    func userDidChange(_ change: UserChangeInfo) {
        if change.accentColorValueChanged {
            handlerBlock?(change.user.accentColor, observer)
        }
    }
}
