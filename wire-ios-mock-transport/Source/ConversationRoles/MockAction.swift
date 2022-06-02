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
import CoreData

@objc public final class MockAction: NSManagedObject, EntityNamedProtocol {
    @NSManaged public var name: String
    @NSManaged public var roles: Set<MockRole>
    
    public static var entityName = "Action"
}

extension MockAction {
    @objc
    public static func insert(in context: NSManagedObjectContext, name: String) -> MockAction {
        let action: MockAction = insert(in: context)
        action.name = name
        
        return action
    }
    
    var payload: ZMTransportData {
        return name as NSString
    }
}

