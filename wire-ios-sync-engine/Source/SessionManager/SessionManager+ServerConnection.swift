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

@objc
public protocol ServerConnectionObserver {

    @objc(serverConnectionDidChange:)
    func serverConnection(didChange serverConnection: ServerConnection)

}

@objc
public protocol ServerConnection {

    var isMobileConnection: Bool { get }
    var isOffline: Bool { get }

    func addServerConnectionObserver(_ observer: ServerConnectionObserver) -> Any
}

extension SessionManager {

    @objc public var serverConnection: ServerConnection? {
        return self
    }

}

extension SessionManager: ServerConnection {

    public var isOffline: Bool {
        return !reachability.mayBeReachable
    }

    public var isMobileConnection: Bool {
        return reachability.isMobileConnection
    }

    /// Add observer of server connection. Returns a token for de-registering the observer.
    public func addServerConnectionObserver(_ observer: ServerConnectionObserver) -> Any {

        return reachability.addReachabilityObserver(on: .main) { [weak self, weak observer] _ in
            guard let `self` = self else { return }
            observer?.serverConnection(didChange: self)
        }
    }

}
