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

enum InvalidFeatureRemoval {

    /// We had an issue where we were creating more than one instance of
    /// `Feature` for a given name (there should be at most one). This patch
    /// is to delete all instances of `Feature` in order to have a clean start.
    /// This isn't a problem because the client creates its own default instance
    /// and quickly fetches updates from the backend.

    static func removeInvalid(in moc: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<Feature>(entityName: Feature.entityName())
        let allInstances = moc.fetchOrAssert(request: fetchRequest)
        allInstances.forEach(moc.delete)
    }

    /// The issue:
    ///
    /// On-premise backends that don't support the conference calling config endpoint
    /// will never be able to deliver a config to the client. The client however, will
    /// then use the default config, which effectively disables conference calling.
    /// Thus, on-prem customers erroneously lose conference calling.
    ///
    /// The fix:
    ///
    /// 1. Delete the local conference calling config from the database (via this patch).
    /// 2. Change the default value to enable conference calling.
    /// 3. Reinsert the config with the new default value.
    /// 4. When the user is started, it will fetch the remote config value and update the local value.
    ///
    /// This means that for on-prem backends that don't support the conference calling feature
    /// config endpoint, we will use the new 'enabled' default. For all backends that do support
    /// the endpoint, their clients will just refetch the remote value.

    static func restoreDefaultConferenceCallingConfig(in moc: NSManagedObjectContext) {
        if let existingInstance = Feature.fetch(name: .conferenceCalling, context: moc) {
            moc.delete(existingInstance)
        }

        let featureService = FeatureService(context: moc)
        featureService.storeConferenceCalling(.init())
    }

}
