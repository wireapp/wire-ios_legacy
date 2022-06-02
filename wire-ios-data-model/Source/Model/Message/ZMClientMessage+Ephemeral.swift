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

extension ZMClientMessage {
    @objc
    override public var isEphemeral: Bool {
        return destructionDate != nil
            || ephemeral != nil
            || isObfuscated
    }

    var ephemeral: Ephemeral? {
        return dataSet.lazy
            .compactMap { ($0 as? ZMGenericMessageData)?.underlyingMessage }
            .first(where: { (message) -> Bool in
                guard case .ephemeral? = message.content else {
                    return false
                }
                return true
            })?.ephemeral
    }

    @objc
    override public var deletionTimeout: TimeInterval {
        guard let ephemeral = self.ephemeral else {
            return -1
        }
        return TimeInterval(ephemeral.expireAfterMillis / 1000)
    }
}
