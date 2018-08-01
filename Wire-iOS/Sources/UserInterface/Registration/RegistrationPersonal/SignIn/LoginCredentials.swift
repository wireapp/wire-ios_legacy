//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


@objcMembers
public class LoginCredentials : NSObject {
    
    let emailAddress : String?
    let password : String?
    let phoneNumber : String?
    let usesCompanyLogin: Bool
    
    init(emailAddress : String? = nil, phoneNumber : String? = nil, password: String? = nil, usesCompanyLogin: Bool) {
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.password = password
        self.usesCompanyLogin = usesCompanyLogin
    }
    
    convenience init?(error : NSError?) {
        
        let emailAddress = error?.userInfo[ZMEmailCredentialKey] as? String
        let password = error?.userInfo[ZMPasswordCredentialKey] as? String
        let phoneNumber = error?.userInfo[ZMPhoneCredentialKey] as? String
        let usesCompanyLogin = error?.userInfo[ZMUserUsesCompanyLoginCredentialKey] as? Bool ?? false
        
        if emailAddress != nil || phoneNumber != nil {
            self.init(emailAddress: emailAddress, phoneNumber: phoneNumber, password: password, usesCompanyLogin: usesCompanyLogin)
        } else {
            return nil
        }
    }
    
}
