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

extension MockUserClient {

    @objc public func attributedRemoteIdentifier(_ attributes: [NSAttributedString.Key : AnyObject], boldAttributes: [NSAttributedString.Key : AnyObject], uppercase: Bool = false) -> NSAttributedString {
        let displayIdentifier = "0011223344556677"

        let identifierPrefixString = NSLocalizedString("registration.devices.id", comment: "") + " "
        let identifierString = NSMutableAttributedString(string: identifierPrefixString, attributes: attributes)
        let identifier = uppercase ? displayIdentifier.uppercased() : displayIdentifier
        let attributedRemoteIdentifier = identifier.fingerprintStringWithSpaces().fingerprintString(attributes: attributes,
                                                                                                    boldAttributes:boldAttributes)
        identifierString.append(attributedRemoteIdentifier!)
        return NSAttributedString(attributedString: identifierString)
    }
}
