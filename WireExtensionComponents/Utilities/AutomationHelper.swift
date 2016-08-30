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
@objc public final class AutomationHelper: NSObject {
    
    static public let sharedHelper = AutomationHelper()
    
    ///  Whether Hockeyapp should be used
    public var useHockey: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("UseHockey")
    }
    
    /// Whether to skip the first login alert
    public var skipFirstLoginAlerts : Bool {
        return self.automationEmailCredentials != nil
    }
    
    /// The login credentials provides by command line
    public let automationEmailCredentials: ZMEmailCredentials?
    
    /// Whether autocorrection is disabled
    public let disableAutocorrection : Bool
    
    /// Whether address book upload is enabled on simulator
    public let uploadAddressbookOnSimulator : Bool
    
    /// Delay in address book remote search override
    public let delayInAddressBookRemoteSearch : NSTimeInterval?
    
    override init() {
        let arguments = Arguments()
        
        self.disableAutocorrection = arguments.hasFlag(AutomationKey.DisableAutocorrection.rawValue)
        self.uploadAddressbookOnSimulator = arguments.hasFlag(AutomationKey.EnableAddressBookOnSimulator.rawValue)
        self.automationEmailCredentials = AutomationHelper.credentials(arguments)
        if arguments.hasFlag(AutomationKey.LogNetwork.rawValue) {
            ZMLogSetLevelForTag(.Debug, "Network")
        }
        self.delayInAddressBookRemoteSearch = AutomationHelper.addressBookSearchDelay(arguments)
        super.init()
    }
    
    private enum AutomationKey: String {
        case Email = "loginemail"
        case Password = "loginpassword"
        case LogNetwork = "debug-log-network"
        case DisableAutocorrection = "disable-autocorrection"
        case EnableAddressBookOnSimulator = "addressbook-on-simulator"
        case AddressBookRemoteSearchDelay = "addressbook-search-delay"
    }
    
    /// Returns the login email and password credentials if set in the given arguments
    private static func credentials(arguments: Arguments) -> ZMEmailCredentials? {
        guard let email = arguments.flagValueIfPresent(AutomationKey.Email.rawValue),
            let password = arguments.flagValueIfPresent(AutomationKey.Password.rawValue) else {
            return nil
        }
        return ZMEmailCredentials(email: email, password: password)
    }
    
    /// Returns the custom time interval for address book search delay if it set in the given arguments
    private static func addressBookSearchDelay(arguments: Arguments) -> NSTimeInterval? {
        guard let delayString = arguments.flagValueIfPresent(AutomationKey.AddressBookRemoteSearchDelay.rawValue),
            let delay = Int(delayString) else {
                return nil
        }
        return NSTimeInterval(delay)
    }
}

// MARK: - Helpers

/// Command line arguments
private struct Arguments {
    
    let flagPrefix = "--"
    
    /// Argument strings
    let commandLineArguments : Set<String>
    
    /// Returns whether the flag is set
    func hasFlag(name: String) -> Bool {
        return self.commandLineArguments.contains(flagPrefix + name)
    }
    
    /// Returns the value of a flag, if present
    func flagValueIfPresent(commandLineArgument: String) -> String? {
        for argument in self.commandLineArguments {
            let searchString = "--" + commandLineArgument + "="
            if argument.hasPrefix(searchString) {
                return argument.substringFromIndex(searchString.startIndex.advancedBy(searchString.characters.count))
            }
        }
        return nil
    }
    
    init() {
        self.commandLineArguments = Set(NSProcessInfo.processInfo().arguments)
    }
}