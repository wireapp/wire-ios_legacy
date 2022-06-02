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
import CoreLocation

@objc(ZMLocationMessageData)
public protocol LocationMessageData: NSObjectProtocol {
    var latitude: Float { get }
    var longitude: Float { get }
    var name: String? { get }
    var zoomLevel: Int32 { get }
}

extension ZMClientMessage: LocationMessageData {

    public override var locationMessageData: LocationMessageData? {
        guard let content = underlyingMessage?.content else {
            return nil
        }
        switch content {
        case .location:
            return self
        case .ephemeral(let data):
            switch data.content {
            case .location?:
                return self
            default:
                return nil
            }
        default:
            return nil
        }
    }

    @objc public var latitude: Float {
        return self.underlyingMessage?.locationData?.latitude ?? 0
    }

    @objc public var longitude: Float {
        return self.underlyingMessage?.locationData?.longitude ?? 0
    }

    @objc public var name: String? {
        return self.underlyingMessage?.locationData?.name
    }

    @objc public var zoomLevel: Int32 {
        return self.underlyingMessage?.locationData?.zoom ?? 0
    }
}

public extension LocationMessageData {

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: CLLocationDegrees(latitude),
            longitude: CLLocationDegrees(longitude)
        )
    }

}
