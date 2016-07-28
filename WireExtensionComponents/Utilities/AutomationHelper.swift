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
    
    ///  - returns: The value specified for the `UseHockey` key in `NSUserDefaults`
    var useHockey: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("UseHockey")
    }
    
    ///  - returns: `true` if values for `--loginemail=` and --`loginpassword=` have been provided on the command line
    private(set) var skipFirstLoginAlerts = false
    
    ///  - returns: The `ZMEmailCredentials` specified with the `--loginemail=` and --`loginpassword=` arguments on the command line
    private(set) var automationEmailCredentials: ZMEmailCredentials? = nil
    
    ///  - returns: The value specified for the `--disable-autocorrection` argument on the command line
    private(set) var disableAutocorrection = false
    
    override init() {
        super.init()
        checkCommandLineArguments()
    }
    
    private enum AutomationKey: String {
        case Email = "--loginemail="
        case Password = "--loginpassword="
        case LogNetwork = "--debug-log-network"
        case DisableAutocorrection = "--disable-autocorrection"
    }
    
    private func checkCommandLineArguments() {
        let arguments = NSProcessInfo.processInfo().arguments
        var email: String?
        var password: String?
        
        arguments.forEach { arg in
            if arg == AutomationKey.LogNetwork.rawValue {
                ZMLogSetLevelForTag(.Debug, "Network")
            }
            
            if arg == AutomationKey.DisableAutocorrection.rawValue {
                disableAutocorrection = true
            }
            
            let emailKey = AutomationKey.Email.rawValue
            if arg.hasPrefix(emailKey) {
                email = arg.substringFromIndex(emailKey.startIndex.advancedBy(emailKey.characters.count))
            }
            
            let passwordKey = AutomationKey.Password.rawValue
            if arg.hasPrefix(passwordKey) {
                password = arg.substringFromIndex(passwordKey.startIndex.advancedBy(passwordKey.characters.count))
            }
        }
        
        guard let mail = email, secret = password else { return }
        skipFirstLoginAlerts = true
        automationEmailCredentials = ZMEmailCredentials(email: mail, password: secret)
    }
    
}
