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

extension ZMOperationLoop: ZMPushChannelConsumer {

    public func pushChannelDidReceive(_ data: ZMTransportData) {
        Logging.network.info("Push Channel:\n\(data)")

        if let events = ZMUpdateEvent.eventsArray(fromPushChannelData: data), !events.isEmpty {
            Logging.eventProcessing.info("Received \(events.count) events from push channel")
            events.forEach({ $0.appendDebugInformation("from push channel (web socket)")})
            self.updateEventProcessor.storeAndProcessUpdateEvents(events, ignoreBuffer: false)
        }
    }

    public func pushChannelDidClose() {
        NotificationInContext(name: ZMOperationLoop.pushChannelStateChangeNotificationName,
                              context: syncMOC.notificationContext,
                              object: self,
                              userInfo: [ ZMPushChannelIsOpenKey: false]).post()

        syncStatus.pushChannelDidClose()
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    public func pushChannelDidOpen() {
        NotificationInContext(name: ZMOperationLoop.pushChannelStateChangeNotificationName,
                              context: syncMOC.notificationContext,
                              object: self,
                              userInfo: [ ZMPushChannelIsOpenKey: true]).post()

        syncStatus.pushChannelDidOpen()
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

}
