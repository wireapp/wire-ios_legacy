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


import MapKit

extension CLLocationCoordinate2D {
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
}

extension CLPlacemark {
    
    func formattedAddress(includeCountry: Bool) -> String? {
        let lines = addressDictionary?["FormattedAddressLines"] as? [String]
        return includeCountry ? lines?.joinWithSeparator(", ") : lines?.dropLast().joinWithSeparator(", ")
    }
    
}

extension MKMapView {
    
    var zoomLevel: Int {
        get {
            let float = log2(360 * (Double(frame.height / 256) / region.span.longitudeDelta))
            // MKMapView does not like NaN and Infinity, so we return 16 as a default, as 0 would represent the whole world
            guard float.isNormal else { return 16 }
            return Int(float)
        }
        
        set {
            setCenterCoordinate(centerCoordinate, zoomLevel: newValue)
        }
    }
    
    func setCenterCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool = false) {
        let span = MKCoordinateSpanMake(360 / pow(2, Double(zoomLevel)) * Double(frame.height) / 256, 0)
        setRegion(MKCoordinateRegionMake(coordinate, span), animated: animated)
    }

}

extension LocationData {

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
    }

}

extension MKMapView {
    
    func locationData(name name: String?) -> LocationData {
        return .locationData(
            withLatitude: Float(centerCoordinate.latitude),
            longitude: Float(centerCoordinate.longitude),
            name: name,
            zoomLevel: Int32(zoomLevel)
        )
    }
    
    func storeLocation() {
        let location = locationData(name: nil)
        Settings.sharedSettings().lastUserLocation = location
    }
    
    func restoreLocation(animated animated: Bool) {
        guard let location = Settings.sharedSettings().lastUserLocation else { return }
        setCenterCoordinate(location.coordinate, zoomLevel: Int(location.zoomLevel), animated: animated)
    }
    
}
