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
import MapKit
import Contacts
import WireDataModel

extension Message {
    class func openInMaps(_ messageData: LocationMessageData) {
        messageData.openInMaps(with: MKCoordinateSpan(zoomLevel: Int(messageData.zoomLevel), viewSize: Float(UIScreen.main.bounds.height)))
    }
}

public extension LocationMessageData {

    func openInMaps(with span: MKCoordinateSpan) {
        let launchOptions = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: span)
        ]

        if let url = googleMapsURL, url.openAsLocation() {
            return
        }

        mapItem?.openInMaps(launchOptions: launchOptions)
    }

    var googleMapsURL: URL? {
        let location = "\(coordinate.latitude),\(coordinate.longitude)"
        return URL(string: "comgooglemaps://?q=\(location)&center=\(location)&zoom=\(zoomLevel)")
    }

    var mapItem: MKMapItem? {
        var addressDictionary: [String: AnyObject]? = nil
        if let name = name {
            addressDictionary = [CNPostalAddressStreetKey: name as AnyObject]
        }

        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }
}
