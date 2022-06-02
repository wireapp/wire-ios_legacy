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

// MARK: - Error on context save debugging

public enum ContextType: String {
    case UI
    case Sync
    case Search
    case Other
}

extension NSManagedObjectContext {

    var type: ContextType {
        if self.zm_isSyncContext {
            return .Sync
        }
        if self.zm_isUserInterfaceContext {
            return .UI
        }
        if self.zm_isSearchContext {
            return .Search
        }
        return .Other
    }
}

extension ZMUserSession {

    public typealias SaveFailureCallback = (_ metadata: [String: Any], _ type: ContextType, _ error: NSError, _ userInfo: [String: Any]) -> Void

    /// Register a handle for monitoring when one of the manage object contexts fails
    /// to save and is rolled back. The call is invoked on the context queue, so it might not be on the main thread
    public func registerForSaveFailure(handler: @escaping SaveFailureCallback) {
        self.managedObjectContext.errorOnSaveCallback = { (context, error) in
            let metadata: [String: Any] = context.persistentStoreCoordinator!.persistentStores[0].metadata as [String: Any]
            let type = context.type
            let userInfo: [String: Any] = context.userInfo.asDictionary() as! [String: Any]
            handler(metadata, type, error, userInfo)
        }
        self.syncManagedObjectContext.performGroupedBlock {
            self.syncManagedObjectContext.errorOnSaveCallback = { (context, error) in
                let metadata: [String: Any] = context.persistentStoreCoordinator!.persistentStores[0].metadata as [String: Any]
                let type = context.type
                let userInfo: [String: Any] = context.userInfo.asDictionary() as! [String: Any]
                handler(metadata, type, error, userInfo)
            }
        }
    }
}
