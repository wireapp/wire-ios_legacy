//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import XCTest
@testable import Wire

final class MockAddressBookHelper: NSObject, AddressBookHelperProtocol {
    var addressBookSearchPerformedAtLeastOnce : Bool = true
    var isAddressBookAccessDisabled : Bool = true
    var accessStatusDidChangeToGranted: Bool = true
    var addressBookSearchWasPostponed : Bool = true
    
    /// Configuration override (used for testing)
    var configuration : AddressBookHelperConfiguration! = nil
    
    static var sharedHelper : AddressBookHelperProtocol = MockAddressBookHelper()
    
    
    func persistCurrentAccessStatus() {
        
    }
    
    var isAddressBookAccessGranted: Bool {
        return false
    }
    
    var isAddressBookAccessUnknown: Bool {
        return true
    }
    
    func startRemoteSearch(_ onlyIfEnoughTimeSinceLast: Bool) {
        //no-op
    }
    
    func requestPermissions(_ callback: ((Bool) -> ())?) {
        //no-op
        callback?(false)
    }
}
