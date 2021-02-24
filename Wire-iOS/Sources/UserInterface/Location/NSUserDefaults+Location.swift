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

private let latitudeKey = "LastLocationLatitudeKey"
private let longitudeKey = "LastLocationLongitudeKey"
private let zoomLevelKey = "LastLocationZoomLevelKey"

extension LocationData {

    func toDictionary() -> [String: Any] {
        return [
            latitudeKey: latitude,
            longitudeKey: longitude,
            zoomLevelKey: Int(zoomLevel)
        ]
    }

    static func locationData(fromDictionary dict: [String: Any]) -> LocationData? {
        guard let latitude = dict[latitudeKey],
            let longitude = dict[longitudeKey],
            let zoomLevel = dict[zoomLevelKey] as? Int else { return nil }

        let latitudeFloat: Float
        let longitudeFloat: Float

        if let latitudeFloatUnwrap = latitude as? Float,
            let longitudeFloatUnwrap = longitude as? Float {
            latitudeFloat = latitudeFloatUnwrap
            longitudeFloat = longitudeFloatUnwrap
        }
        else if let latitudeDoubleUnwrap = latitude as? Double,
                let longitudeDoubleUnwrap = longitude as? Double {
            latitudeFloat = Float(latitudeDoubleUnwrap)
            longitudeFloat = Float(longitudeDoubleUnwrap)
        }
        else {
            return nil
        }

        return .locationData(withLatitude: latitudeFloat, longitude: longitudeFloat, name: nil, zoomLevel: Int32(zoomLevel))
    }

}
