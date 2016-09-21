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

private let latitudeKey = "LastLocationLatitudeKey"
private let longitudeKey = "LastLocationLongitudeKey"
private let zoomLevelKey = "LastLocationZoomLevelKey"

public extension LocationData {

    func toDictionary() -> [String : AnyObject] {
        return [
            latitudeKey: latitude as AnyObject,
            longitudeKey: longitude as AnyObject,
            zoomLevelKey: Int(zoomLevel) as AnyObject
        ]
    }

    static func locationData(fromDictionary dict: [String : AnyObject]) -> LocationData? {
        guard let latitude = dict[latitudeKey] as? Float,
            let longitude = dict[longitudeKey] as? Float,
            let zoomLevel = dict[zoomLevelKey] as? Int else { return nil }
        return .locationData(withLatitude: latitude, longitude: longitude, name: nil, zoomLevel: Int32(zoomLevel))
    }
    
}
