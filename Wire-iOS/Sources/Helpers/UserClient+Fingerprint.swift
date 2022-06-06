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
import UIKit
import WireDataModel

// TODO: merge to UserClientType or stay in UI project? It is depends on localized string resource
protocol UserClientTypeAttributedString {
    func attributedRemoteIdentifier(_ attributes: [NSAttributedString.Key: AnyObject], boldAttributes: [NSAttributedString.Key: AnyObject], uppercase: Bool) -> NSAttributedString
}

private let UserClientIdentifierMinimumLength = 16

extension Sequence where Element: UserClientType {

    func sortedByRelevance() -> [UserClientType] {
        return sorted { (lhs, rhs) -> Bool in

            if lhs.deviceClass == .legalHold {
                return true
            } else if rhs.deviceClass == .legalHold {
                return false
            } else {
                return lhs.remoteIdentifier < rhs.remoteIdentifier
            }
        }
    }

}

extension UserClientType {

    public func attributedRemoteIdentifier(_ attributes: [NSAttributedString.Key: AnyObject], boldAttributes: [NSAttributedString.Key: AnyObject], uppercase: Bool = false) -> NSAttributedString {
        let identifierPrefixString = NSLocalizedString("registration.devices.id", comment: "") + " "
        let identifierString = NSMutableAttributedString(string: identifierPrefixString, attributes: attributes)
        let identifier = uppercase ? displayIdentifier.localizedUppercase : displayIdentifier
        let attributedRemoteIdentifier = identifier.fingerprintStringWithSpaces.fingerprintString(attributes: attributes, boldAttributes: boldAttributes)

        identifierString.append(attributedRemoteIdentifier)

        return NSAttributedString(attributedString: identifierString)
    }

    /// This should be used when showing the identifier in the UI
    /// We manually add a padding if there was a leading zero

    public var displayIdentifier: String {
        guard let remoteIdentifier = self.remoteIdentifier else {
            return ""
        }

        var paddedIdentifier = remoteIdentifier

        while paddedIdentifier.count < UserClientIdentifierMinimumLength {
            paddedIdentifier = "0" + paddedIdentifier
        }

        return paddedIdentifier
    }
}

extension DeviceType {

    var localizedDescription: String {
        typealias DeviceType = L10n.Localizable.Device.`Type`
        switch self {
        case .permanent:
            return DeviceType.permanent
        case .temporary:
            return DeviceType.temporary
        case .legalHold:
            return DeviceType.legalhold
        default:
            return DeviceType.unknown
        }
    }

}

extension DeviceClass {

    var localizedDescription: String {
        typealias DeviceType = L10n.Localizable.Device.Class
        switch self {
        case .phone:
            return DeviceType.phone
        case .desktop:
            return DeviceType.desktop
        case .tablet:
            return DeviceType.tablet
        case .legalHold:
            return DeviceType.legalhold
        default:
            return DeviceType.unknown
        }
    }

}
