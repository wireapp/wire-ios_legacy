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

import WireSyncEngine

protocol CallStateExtending {
    var isConnected: Bool { get }
    var isTerminating: Bool { get }
    var canAccept: Bool { get }
}

extension CallStateExtending {
    func isEqual(toCallState other: CallStateExtending) -> Bool {
        return isConnected == other.isConnected &&
            isTerminating == other.isTerminating &&
            canAccept == other.canAccept
    }
}

extension CallState: CallStateExtending {
    var isConnected: Bool {
        switch self {
        case .established, .establishedDataChannel: return true
        default: return false
        }
    }
    
    var isTerminating: Bool {
        switch self {
        case .terminating, .incoming(video: _, shouldRing: false, degraded: _): return true
        default: return false
        }
    }
    
    var canAccept: Bool {
        switch self {
        case .incoming(video: _, shouldRing: true, degraded: _): return true
        default: return false
        }
    }
}
