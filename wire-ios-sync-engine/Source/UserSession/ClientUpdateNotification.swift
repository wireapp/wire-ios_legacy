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

import WireDataModel

@objc public enum ZMClientUpdateNotificationType: Int {
    case fetchCompleted
    case fetchFailed
    case deletionCompleted
    case deletionFailed
}

@objc public class ZMClientUpdateNotification: NSObject {

    private static let name = Notification.Name(rawValue: "ZMClientUpdateNotification")

    private static let clientObjectIDsKey = "clientObjectIDs"
    private static let typeKey = "notificationType"
    private static let errorKey = "error"

    @objc public static func addObserver(context: NSManagedObjectContext, block: @escaping (ZMClientUpdateNotificationType, [NSManagedObjectID], NSError?) -> Void) -> Any {
        return NotificationInContext.addObserver(name: self.name,
                                                 context: context.notificationContext) { note in
            guard let type = note.userInfo[self.typeKey] as? ZMClientUpdateNotificationType else { return }
            let clientObjectIDs = (note.userInfo[self.clientObjectIDsKey] as? [NSManagedObjectID]) ?? []
            let error = note.userInfo[self.errorKey] as? NSError
            block(type, clientObjectIDs, error)
        }
    }

    static func notify(type: ZMClientUpdateNotificationType, context: NSManagedObjectContext, clients: [UserClient] = [], error: NSError? = nil) {
        NotificationInContext(name: self.name, context: context.notificationContext, userInfo: [
            errorKey: error as Any,
            clientObjectIDsKey: clients.objectIDs,
            typeKey: type
        ]).post()
    }

    @objc
    public static func notifyFetchingClientsCompleted(userClients: [UserClient], context: NSManagedObjectContext) {
        self.notify(type: .fetchCompleted, context: context, clients: userClients)
    }

    @objc
    public static func notifyFetchingClientsDidFail(error: NSError, context: NSManagedObjectContext) {
        self.notify(type: .fetchFailed, context: context, error: error)
    }

    @objc
    public static func notifyDeletionCompleted(remainingClients: [UserClient], context: NSManagedObjectContext) {
        self.notify(type: .deletionCompleted, context: context, clients: remainingClients)
    }

    @objc
    public static func notifyDeletionFailed(error: NSError, context: NSManagedObjectContext) {
        self.notify(type: .deletionFailed, context: context, error: error)
    }
}

extension Array where Element: NSManagedObject {

    var objectIDs: [NSManagedObjectID] {
        return self.compactMap { obj in
            guard !obj.objectID.isTemporaryID else { return nil }
            return obj.objectID
        }
    }
}
