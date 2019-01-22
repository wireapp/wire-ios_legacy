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

final class RestrictedButton: IconButton, Restricted {
    var requiredPermissions: Permissions = []

    override public var isHidden: Bool {
        get {
            return shouldHide || super.isHidden
        }

        set {
            if shouldHide {
                super.isHidden = true
            } else {
                super.isHidden = newValue
            }
        }
    }

    private var shouldHide: Bool {
        return ZMUser.selfUser().isTeamMember && !selfUserIsAuthorized
    }

    init(requiredPermissions: Permissions) {
        super.init()

        self.requiredPermissions = requiredPermissions
        if shouldHide {
            isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // this is for fixing running crash for init(frame:) method not find.
    // rewrite parent class to Swift and then remove this.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}
