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
import ZMCSystem
import zmessaging

/// This class is used to retrieve specific arguments passed on the 
/// command line when running automation tests. 
/// These values typically do not need to be stored in `Settings`.
@objc final class AutomationHelper: NSObject {
    
    static let sharedHelper = AutomationHelper()
    
    ///  Whether Hockeyapp should be used
    var useHockey: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("UseHockey")
    }
    
    /// Whether to skip the first login alert
    var skipFirstLoginAlerts : Bool {
        return self.automationEmailCredentials != nil
    }
    
    /// The login credentials provides by command line
    let automationEmailCredentials: ZMEmailCredentials?
    
    /// Whether autocorrection is disabled
    let disableAutocorrection : Bool
    
    /// Whether address book upload is enabled on simulator
    let uploadAddressbookOnSimulator : Bool
    
    override init() {
        let arguments = Set(NSProcessInfo.processInfo().arguments)
        
        self.disableAutocorrection = arguments.contains(AutomationKey.DisableAutocorrection.rawValue)
        self.uploadAddressbookOnSimulator = arguments.contains(AutomationKey.EnableAddressBookOnSimulator.rawValue)
        self.automationEmailCredentials = AutomationHelper.credentialsFromCommandLine()
        if arguments.contains(AutomationKey.LogNetwork.rawValue) {
            ZMLogSetLevelForTag(.Debug, "Network")
        }
        
        super.init()
    }
    
    private enum AutomationKey: String {
        case Email = "--loginemail="
        case Password = "--loginpassword="
        case LogNetwork = "--debug-log-network"
        case DisableAutocorrection = "--disable-autocorrection"
        case EnableAddressBookOnSimulator = "--addressbook-on-simulator"
    }
    
    /// Gets the login email and password from command line arguments
    /// - returns: the credentials, or nil if credentials were not found
    private static func credentialsFromCommandLine() -> ZMEmailCredentials? {
        let arguments = NSProcessInfo.processInfo().arguments
        var email: String?
        var password: String?
        
        arguments.forEach { arg in
            let emailKey = AutomationKey.Email.rawValue
            if arg.hasPrefix(emailKey) {
                email = arg.substringFromIndex(emailKey.startIndex.advancedBy(emailKey.characters.count))
            }
            
            let passwordKey = AutomationKey.Password.rawValue
            if arg.hasPrefix(passwordKey) {
                password = arg.substringFromIndex(passwordKey.startIndex.advancedBy(passwordKey.characters.count))
            }
        }
        
        guard let mail = email, secret = password else { return nil }
        return ZMEmailCredentials(email: mail, password: secret)
    }
}
