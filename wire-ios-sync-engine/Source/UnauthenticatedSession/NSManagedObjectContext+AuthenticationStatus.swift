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

private let cookieLabelKey = "ZMCookieLabel"
private let registeredOnThisDeviceKey = "ZMRegisteredOnThisDevice"

@objc extension NSManagedObjectContext {

    public var registeredOnThisDevice: Bool {
        get {
            return self.metadataBoolValueForKey(registeredOnThisDeviceKey)
        }
        set {
            self.setBooleanMetadataOnBothContexts(newValue, key: registeredOnThisDeviceKey)
        }
    }

    private func metadataBoolValueForKey(_ key: String) -> Bool {
        return (self.persistentStoreMetadata(forKey: key) as? NSNumber)?.boolValue ?? false
    }

    private func setBooleanMetadataOnBothContexts(_ newValue: Bool, key: String) {
        precondition(self.zm_isSyncContext)
        let value = NSNumber(value: newValue)
        self.setPersistentStoreMetadata(value, key: key)
        guard let uiContext = self.zm_userInterface else { return }
        uiContext.performGroupedBlock {
            uiContext.setPersistentStoreMetadata(value, key: key)
        }
    }

    public var legacyCookieLabel: String? {
        return self.persistentStoreMetadata(forKey: cookieLabelKey) as? String
    }
}
