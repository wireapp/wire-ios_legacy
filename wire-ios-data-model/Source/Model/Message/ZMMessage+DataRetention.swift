//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ZMMessage {

    class func predicateForMessagesOlderThan(_ date: Date) -> NSPredicate {
        return NSPredicate(format: "%K < %@", ZMMessageServerTimestampKey, date as NSDate)
    }

    public class func deleteMessagesOlderThan(_ date: Date, context: NSManagedObjectContext) throws {
        context.zm_fileAssetCache.deleteAssetsOlderThan(date)
        try context.batchDeleteEntities(named: ZMMessage.entityName(), matching: predicateForMessagesOlderThan(date))
    }

}
