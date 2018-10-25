//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public let UIWindowLevelNotification: UIWindow.Level = UIWindow.Level.statusBar - 1
public let UIWindowLevelCallOverlay: UIWindow.Level = UIWindowLevelNotification - 1

final class CallWindow: PassthroughWindow {
    let callController = CallWindowRootViewController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        rootViewController = callController
        backgroundColor = .clear
        accessibilityIdentifier = "ZClientCallWindow"
        accessibilityViewIsModal = true
        windowLevel = UIWindowLevelCallOverlay
    }
    
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
