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

import WireUtilities

@objc (ZMLocationData) @objcMembers
final public class LocationData: NSObject {

    public let latitude, longitude: Float
    public let name: String?
    public let zoomLevel: Int32

    public class func locationData(withLatitude latitude: Float, longitude: Float, name: String?, zoomLevel: Int32) -> LocationData {
        return LocationData(latitude: latitude, longitude: longitude, name: name, zoomLevel: zoomLevel)
    }

    init(latitude: Float, longitude: Float, name: String?, zoomLevel: Int32) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name?.removingExtremeCombiningCharacters
        self.zoomLevel = zoomLevel
        super.init()
    }
}
