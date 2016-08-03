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

private enum PermissionsType: String {
    case AddressBook = "addressBook"
}

private enum PermissionEvent: String {
    case Preflight = "onboarding.proceeded_from_contacts_screen"
    case System = "onboarding.changed_contacts_permssion"
}

private enum PermissionKey: String {
    case Category = "category"
    case State = "state"
}

private extension Bool {
    var preflightDescription: String {
        return self ? "ask_for_permission" : "not_now"
    }
}

private extension Bool {
    var grantedDescription: String {
        return self ? "granted" : "denied"
    }
}

public extension AnalyticsTracker {
    
    /// Tracks how the address book upload `preflight` permissions on the `nag screens` was answered
    @objc public func tagAddressBookSystemPermissions(granted: Bool) {
        tagSystemPermissions(ofType: .AddressBook, granted: granted)
    }

    /// Tracks how the address book upload `preflight` permissions on the `nag screens` was answered
    @objc public  func tagAddressBookPreflightPermissions(shouldAsk: Bool) {
        tagPreflightPermissions(ofType: .AddressBook, shouldAsk: shouldAsk)
    }
    
    /// Used to track the answer of the `nag screens` shown before asking the OS for permissions
    private func tagPreflightPermissions(ofType type: PermissionsType, shouldAsk: Bool) {
        let attributes = [
            PermissionKey.Category.rawValue: type.rawValue,
            PermissionKey.State.rawValue: shouldAsk.preflightDescription
        ]
        
        tagEvent(PermissionEvent.Preflight.rawValue, attributes: attributes)
    }
    
    /// Used to track the answer of the `nag screens` shown before asking the OS for permissions
    private func tagSystemPermissions(ofType type: PermissionsType, granted: Bool) {
        let attributes = [
            PermissionKey.Category.rawValue: type.rawValue,
            PermissionKey.State.rawValue: granted.grantedDescription
        ]

        tagEvent(PermissionEvent.System.rawValue, attributes: attributes)
    }
    
}
