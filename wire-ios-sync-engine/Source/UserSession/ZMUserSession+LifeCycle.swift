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

extension ZMUserSession {

    public func application(_ application: ZMApplication, didFinishLaunching launchOptions: [UIApplication.LaunchOptionsKey: Any?]) {
        startEphemeralTimers()
    }

    public func application(_ application: ZMApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void ) {
        BackgroundActivityFactory.shared.resume()

        syncManagedObjectContext.performGroupedBlock {
            self.applicationStatusDirectory?.operationStatus.startBackgroundFetch(withCompletionHandler: completionHandler)
        }
    }

    public func application(_ application: ZMApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    @objc
    public func applicationDidEnterBackground(_ note: Notification?) {
        notifyThirdPartyServices()
        stopEphemeralTimers()
        lockDatabase()
    }

    @objc
    public func applicationWillEnterForeground(_ note: Notification?) {

        hasNotifiedThirdPartyServices = false

        mergeChangesFromStoredSaveNotificationsIfNeeded()
        startEphemeralTimers()
        deleteOldEphemeralMessages()
        processPendingEvents()
    }

    func processPendingEvents() {
        syncManagedObjectContext.performGroupedBlock {
            self.processEvents()
        }
    }

    func deleteOldEphemeralMessages() {
        // In the case that an ephemeral was sent via the share extension, we need
        // to ensure that they have timers running or are deleted/obfuscated if
        // needed. Note: ZMMessageTimer will only create a new timer for a message
        // if one does not already exist.
        syncManagedObjectContext.performGroupedBlock {
            ZMMessage.deleteOldEphemeralMessages(self.syncManagedObjectContext)
        }
    }

    func mergeChangesFromStoredSaveNotificationsIfNeeded() {
        let storedNotifications = storedDidSaveNotifications.storedNotifications
        storedDidSaveNotifications.clear()

        guard !storedNotifications.isEmpty else { return }

        for changes in storedNotifications {
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [managedObjectContext])

            syncManagedObjectContext.performGroupedBlock {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.syncManagedObjectContext])
            }
        }

        // we only process pending changes on sync context bc changes on the
        // ui context will be processed when we do the save.
        syncManagedObjectContext.performGroupedBlock {
            self.syncManagedObjectContext.processPendingChanges()
        }

        self.managedObjectContext.saveOrRollback()
    }

}
