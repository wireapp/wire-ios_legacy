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
import CoreData

/// A helper class to automatically register and unregister an observer for a notification with
/// the notification center.
///
/// In order to receive notifications a strong reference to the token maintained.

public class ManagedObjectObserverToken: NSObject {

    // MARK: - Properties

    let token: Any

    // We keep strong reference to `object` because the notifications would not get delivered
    // if no one has references to it anymore. This could happen with faulted NSManagedObject.

    private let object: AnyObject?

    // MARK: - Life cycle

    public init(
        name: Notification.Name,
        managedObjectContext: NSManagedObjectContext,
        object: AnyObject? = nil,
        queue: OperationQueue? = nil,
        block: @escaping (NotificationInContext) -> Void
    ) {
        self.object = object
        self.token =  NotificationInContext.addObserver(
            name: name,
            context: managedObjectContext.notificationContext,
            object: object,
            queue: queue,
            using: block
        )
    }

}
