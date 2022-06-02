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


@objcMembers public final class MockService: NSManagedObject, EntityNamedProtocol {

    @NSManaged public var identifier: String
    @NSManaged public var name: String
    @NSManaged public var handle: String?
    @NSManaged public var accentID: Int
    @NSManaged public var provider: String
    @NSManaged public var summary: String?
    @NSManaged public var serviceDescription: String?
    @NSManaged public var tag: String?

    @NSManaged public var assets: Set<MockAsset>?

    @NSManaged public var providerURL: String?
    @NSManaged public var providerName: String?
    @NSManaged public var providerEmail: String?
    @NSManaged public var providerDescription: String?
    
    override public func awakeFromInsert() {
        if accentID == 0 {
            accentID = 2
        }
    }

    public static var entityName = "Service"

    static public func existingService(with identifier: String, provider: String, managedObjectContext: NSManagedObjectContext) -> MockService? {
        // Fetch service
        let predicate = NSPredicate(format: "%K == %@ AND %K == %@", #keyPath(MockService.identifier), identifier, #keyPath(MockService.provider), provider)
        let result: [MockService] = MockService.fetchAll(in: managedObjectContext, withPredicate: predicate)
        
        return result.first
    }
    
    var payloadValues: [String : Any?] {
        return [
            "id": identifier,
            "name" : name,
            "handle" : handle,
            "accent_id" : accentID,
            "provider" : provider,
            "summary" : summary ?? "",
            "tag" : tag ?? "",
            "assets" : (self.assets ?? Set()).map {
                return ["type": "image",
                        "size": "preview",
                        "key": $0.identifier] as [String: String]
            }
        ]
    }
    
    var payload: ZMTransportData {
        return payloadValues as NSDictionary
    }
}

