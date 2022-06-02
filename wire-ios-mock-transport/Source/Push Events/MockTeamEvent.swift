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

@objcMembers public class MockTeamEvent: NSObject {
    
    public enum Kind: String {
        case delete = "team.delete"
        case update = "team.update"
    }
    
    public let data: [String : Any?]
    public let teamIdentifier: String
    public let kind: Kind
    public let timestamp = Date()
    
    public static func updated(team: MockTeam, changedValues: [String: Any]) -> MockTeamEvent? {
        var data = [String : String?]()
        
        let nameKey = #keyPath(MockTeam.name)
        if changedValues[nameKey] != nil {
            data["name"] = team.name
        }
        
        let pictureAssetIdKey = #keyPath(MockTeam.pictureAssetId)
        if changedValues[pictureAssetIdKey] != nil {
            data["icon"] = team.pictureAssetId
        }
        
        let pictureAssetKeyKey = #keyPath(MockTeam.pictureAssetKey)
        if changedValues[pictureAssetKeyKey] != nil {
            data["icon_key"] = team.pictureAssetKey
        }
        
        if data.isEmpty {
            // No changes to team
            return nil
        }
        return MockTeamEvent(kind: .update, team: team, data: data)
    }
    
    public static func deleted(team: MockTeam) -> MockTeamEvent {
        return MockTeamEvent(kind: .delete, team: team, data: [:])
    }
    
    public init(kind: Kind, team: MockTeam, data: [String : Any?]) {
        self.kind = kind
        self.teamIdentifier = team.identifier
        self.data = data
    }
    
    @objc public var payload: ZMTransportData {
        return [
            "team" : teamIdentifier,
            "time" : timestamp.transportString(),
            "type" : kind.rawValue,
            "data" : data
            ] as ZMTransportData
    }
    
    public override var debugDescription: String {
        return "<\(type(of: self))> = \(kind.rawValue) team \(teamIdentifier)"
    }
}
