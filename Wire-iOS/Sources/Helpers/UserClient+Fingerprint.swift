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

extension UserClient {
    
    public func attributedRemoteIdentifier(_ attributes: [String : AnyObject], boldAttributes: [String : AnyObject], uppercase: Bool = false) -> NSAttributedString {
        let identifierPrefixString = NSLocalizedString("registration.devices.id", comment: "") + " "
        let identifierString = NSMutableAttributedString(string: identifierPrefixString, attributes: attributes)
        let identifier = uppercase ? displayIdentifier.uppercased() : displayIdentifier
        let attributedRemoteIdentifier = identifier.fingerprintStringWithSpaces().fingerprintString(attributes: attributes,
            boldAttributes:boldAttributes)
        identifierString.append(attributedRemoteIdentifier!)
        return NSAttributedString(attributedString: identifierString)
    }
    
    public func localizedDeviceClass() -> String? {
        switch self.deviceClass {
        case .some("desktop"):
            return NSLocalizedString("device.class.desktop", comment: "")

        case .some("phone"):
            return NSLocalizedString("device.class.phone", comment: "")
            
        case .some("tablet"):
            return NSLocalizedString("device.class.tablet", comment: "")
            
        default:
            return .none
        }
    }
}

private let UserClientIdentifierMinimumLength = 16

extension UserClient {
    
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
