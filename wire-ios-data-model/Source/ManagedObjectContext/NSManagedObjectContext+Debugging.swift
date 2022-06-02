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

private let errorOnSaveCallbackKey = "zm_errorOnSaveCallback"

extension NSManagedObjectContext {

    public typealias ErrorOnSaveCallback = (NSManagedObjectContext, NSError) -> Void

    // Callback invoked when an error is generated during save
    public var errorOnSaveCallback: ErrorOnSaveCallback? {
        get {
            return self.userInfo[errorOnSaveCallbackKey] as? ErrorOnSaveCallback
        }
        set {
            self.userInfo[errorOnSaveCallbackKey] = newValue
        }
    }

    /// Report an error during save
    @objc public func reportSaveError(error: NSError) {
        if let callback = self.errorOnSaveCallback {
            callback(self, error)
        }
    }
}
