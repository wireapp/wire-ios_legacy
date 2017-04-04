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
import WireSystem
import WireSyncEngine

/// This class is used to retrieve specific arguments passed on the 
/// command line when running automation tests. 
/// These values typically do not need to be stored in `Settings`.
@objc public final class AutomationHelper: NSObject {
    
    static public let sharedHelper = AutomationHelper()
    
    ///  Whether Hockeyapp should be used
    public var useHockey: Bool {
        return UserDefaults.standard.bool(forKey: "UseHockey")
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
    public let delayInAddressBookRemoteSearch : TimeInterval?

    /// The name of the arguments file in the /tmp directory
    private let fileArgumentsName = "wire_arguments.txt"

    override init() {
        let url = URL(string: NSTemporaryDirectory())?.appendingPathComponent(fileArgumentsName)
        let arguments: ArgumentsType = url.flatMap(FileArguments.init) ?? CommandLineArguments()

        self.disableAutocorrection = arguments.hasFlag(AutomationKey.DisableAutocorrection.rawValue)
        self.uploadAddressbookOnSimulator = arguments.hasFlag(AutomationKey.EnableAddressBookOnSimulator.rawValue)
        self.automationEmailCredentials = AutomationHelper.credentials(arguments)
        if arguments.hasFlag(AutomationKey.LogNetwork.rawValue) {
            ZMSLog.set(level: .debug, tag: "Network")
        }
        AutomationHelper.enableLogTags(arguments)
        self.delayInAddressBookRemoteSearch = AutomationHelper.addressBookSearchDelay(arguments)
        super.init()
    }
    
    fileprivate enum AutomationKey: String {
        case Email = "loginemail"
        case Password = "loginpassword"
        case LogNetwork = "debug-log-network"
        case LogTags = "debug-log"
        case DisableAutocorrection = "disable-autocorrection"
        case EnableAddressBookOnSimulator = "addressbook-on-simulator"
        case AddressBookRemoteSearchDelay = "addressbook-search-delay"
    }
    
    /// Returns the login email and password credentials if set in the given arguments
    fileprivate static func credentials(_ arguments: ArgumentsType) -> ZMEmailCredentials? {
        guard let email = arguments.flagValueIfPresent(AutomationKey.Email.rawValue),
            let password = arguments.flagValueIfPresent(AutomationKey.Password.rawValue) else {
            return nil
        }
        return ZMEmailCredentials(email: email, password: password)
    }
    
    // Switches on all flags that you would like to log listed after `--debug-log=` tags should be separated by comma
    fileprivate static func enableLogTags(_ arguments: ArgumentsType) {
        guard let tagsString = arguments.flagValueIfPresent(AutomationKey.LogTags.rawValue) else { return }
        let tags = tagsString.components(separatedBy: ",")
        tags.forEach{ ZMSLog.set(level: .debug, tag: $0) }
    }
    
    /// Returns the custom time interval for address book search delay if it set in the given arguments
    fileprivate static func addressBookSearchDelay(_ arguments: ArgumentsType) -> TimeInterval? {
        guard let delayString = arguments.flagValueIfPresent(AutomationKey.AddressBookRemoteSearchDelay.rawValue),
            let delay = Int(delayString) else {
                return nil
        }
        return TimeInterval(delay)
    }
}

// MARK: - Helpers

protocol ArgumentsType {

    var flagPrefix: String { get }

    /// Argument strings
    var arguments: Set<String> { get }

    /// Returns whether the flag is set
    func hasFlag(_ name: String) -> Bool

    /// Returns the value of a flag, if present
    func flagValueIfPresent(_ commandLineArgument: String) -> String?
}

extension ArgumentsType {

    var flagPrefix: String { return "--" }

    func hasFlag(_ name: String) -> Bool {
        return self.arguments.contains(flagPrefix + name)
    }

    func flagValueIfPresent(_ commandLineArgument: String) -> String? {
        for argument in self.arguments {
            let searchString = "--" + commandLineArgument + "="
            if argument.hasPrefix(searchString) {
                return argument.substring(from: searchString.characters.index(searchString.startIndex, offsetBy: searchString.characters.count))
            }
        }
        return nil
    }
}

/// Command line arguments
private struct CommandLineArguments: ArgumentsType {

    let arguments: Set<String>

    init() {
        arguments = Set(ProcessInfo.processInfo.arguments)
    }
}

/// Arguments read from a file on disk
private struct FileArguments: ArgumentsType {

    let arguments: Set<String>

    init?(url: URL) {
        guard let argumentsString = try? String(contentsOfFile: url.path, encoding: .utf8) else { return nil }
        arguments = Set(argumentsString.components(separatedBy: .whitespaces))
    }
}
