//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel

/// A object that can be sent, in progress, or failed, optionally tracking the sending progress
public protocol Sendable {

    /// The state of the delivery
    var isSent: Bool { get }

    /// Whether the sendable is currently blocked because of missing clients
    var blockedBecauseOfMissingClients: Bool { get }

    /// The progress of the delivery, from 0 to 1.
    /// It will be nil if the progress can not be tracked.
    /// It will be 1 when the delivery is completed.
    var deliveryProgress: Float? { get }

    /// Expire message sending
    func cancel()
}
