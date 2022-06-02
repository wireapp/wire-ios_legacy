//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireSystem
import WireUtilities

public enum Logging {

    /// For logs related to processing message data, which may included
    /// work related to `GenericMessage` profotobuf data or the `ZMClientMessage`
    /// and `ZMAssetClientMessage` container types.

    public static let messageProcessing = ZMSLog(tag: "Message Processing")

    /// For logs related to processing update events.

    public static let eventProcessing = ZMSLog(tag: "event-processing")

    /// For logs related to network requests.

    public static let network = ZMSLog(tag: "Network")

    /// For logs related to push notifications.

    public static let push = ZMSLog(tag: "Push")

    /// For logs related to encryption at rest.

    public static let EAR = ZMSLog(tag: "EAR")

}
