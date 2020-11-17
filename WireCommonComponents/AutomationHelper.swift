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

final public class AutomationEmailCredentials: NSObject {
    public var email: String
    public var password: String
    
    init(email: String, password: String) {
        self.email = email
        self.password = password
        super.init()
    }
}

/// This class is used to retrieve specific arguments passed on the 
/// command line when running automation tests. 
/// These values typically do not need to be stored in `Settings`.
public final class AutomationHelper: NSObject {
    
    static public let sharedHelper = AutomationHelper()
    
    private var useAppCenterLaunchOption: Bool?
    
    /// Whether AppCenter should be used
    /// Launch option `--use-app-center` overrides user defaults setting.
    public var useAppCenter: Bool {
        // useAppCenterLaunchOption has higher priority
        if let useAppCenterLaunchOption = useAppCenterLaunchOption {
            return useAppCenterLaunchOption
        }
        
        if UserDefaults.standard.object(forKey: "UseAppCenter") != nil {
            return UserDefaults.standard.bool(forKey: "UseAppCenter")
        }

        //when UserDefaults's useAppCenter is not set, default is true to allow app center start
        return true
    }
    
    /// Whether analytics should be used
    public var useAnalytics: Bool {
        //TODO: get it from xcconfig?
//        return UserDefaults.standard.bool(forKey: "UseAnalytics")
        return true
    }
    
    /// Whether to skip the first login alert
    public var skipFirstLoginAlerts : Bool {
        return self.automationEmailCredentials != nil
    }
    
    /// The login credentials provides by command line
    public let automationEmailCredentials: AutomationEmailCredentials?
    
    /// Whether we push notification permissions alert is disabled
    public let disablePushNotificationAlert : Bool
    
    /// Whether autocorrection is disabled
    public let disableAutocorrection : Bool
    
    /// Whether address book upload is enabled on simulator
    public let uploadAddressbookOnSimulator : Bool

    /// Whether we should disable the call quality survey.
    public let disableCallQualitySurvey: Bool
    
    /// Whether we should disable dismissing the conversation input bar keyboard by dragging it downwards.
    public let disableInteractiveKeyboardDismissal: Bool
    
    /// Delay in address book remote search override
    public let delayInAddressBookRemoteSearch : TimeInterval?
    
    /// Debug data to install in the share container
    public let debugDataToInstall: URL?

    /// The name of the arguments file in the /tmp directory
    private let fileArgumentsName = "wire_arguments.txt"

    /// Whether the backend environment type should be persisted as a setting.
    public let shouldPersistBackendType: Bool

    override init() {
        let url = URL(string: NSTemporaryDirectory())?.appendingPathComponent(fileArgumentsName)
        let arguments: ArgumentsType = url.flatMap(FileArguments.init) ?? CommandLineArguments()

        disablePushNotificationAlert = arguments.hasFlag(AutomationKey.disablePushNotificationAlert)
        disableAutocorrection = arguments.hasFlag(AutomationKey.disableAutocorrection)
        uploadAddressbookOnSimulator = arguments.hasFlag(AutomationKey.enableAddressBookOnSimulator)
        disableCallQualitySurvey = arguments.hasFlag(AutomationKey.disableCallQualitySurvey)
        shouldPersistBackendType = arguments.hasFlag(AutomationKey.persistBackendType)
        disableInteractiveKeyboardDismissal = arguments.hasFlag(AutomationKey.disableInteractiveKeyboardDismissal)
        
        if let value = arguments.flagValueIfPresent(AutomationKey.useAppCenter.rawValue) {
            useAppCenterLaunchOption = (value != "0")
        }

        automationEmailCredentials = AutomationHelper.credentials(arguments)
        if arguments.hasFlag(AutomationKey.logNetwork) {
            ZMSLog.set(level: .debug, tag: "Network")
        }
        if arguments.hasFlag(AutomationKey.logCalling) {
            ZMSLog.set(level: .debug, tag: "calling")
        }
        AutomationHelper.enableLogTags(arguments)
        if let debugDataPath = arguments.flagValueIfPresent(AutomationKey.debugDataToInstall.rawValue),
            FileManager.default.fileExists(atPath: debugDataPath)
        {
            self.debugDataToInstall = URL(fileURLWithPath: debugDataPath)
        } else {
            self.debugDataToInstall = nil
        }
        
        self.delayInAddressBookRemoteSearch = AutomationHelper.addressBookSearchDelay(arguments)
        super.init()
    }
    
    fileprivate enum AutomationKey: String {
        case email = "loginemail"
        case password = "loginpassword"
        case logNetwork = "debug-log-network"
        case logCalling = "debug-log-calling"
        case logTags = "debug-log"
        case disablePushNotificationAlert = "disable-push-alert"
        case disableAutocorrection = "disable-autocorrection"
        case enableAddressBookOnSimulator = "addressbook-on-simulator"
        case addressBookRemoteSearchDelay = "addressbook-search-delay"
        case debugDataToInstall = "debug-data-to-install"
        case disableCallQualitySurvey = "disable-call-quality-survey"
        case persistBackendType = "persist-backend-type"
        case disableInteractiveKeyboardDismissal = "disable-interactive-keyboard-dismissal"
        case useAppCenter = "use-app-center"
    }
    
    /// Returns the login email and password credentials if set in the given arguments
    fileprivate static func credentials(_ arguments: ArgumentsType) -> AutomationEmailCredentials? {
        guard let email = arguments.flagValueIfPresent(AutomationKey.email.rawValue),
            let password = arguments.flagValueIfPresent(AutomationKey.password.rawValue) else {
            return nil
        }
        return AutomationEmailCredentials(email: email, password: password)
    }
    
    // Switches on all flags that you would like to log listed after `--debug-log=` tags should be separated by comma
    fileprivate static func enableLogTags(_ arguments: ArgumentsType) {
        guard let tagsString = arguments.flagValueIfPresent(AutomationKey.logTags.rawValue) else { return }
        let tags = tagsString.components(separatedBy: ",")
        tags.forEach{ ZMSLog.set(level: .debug, tag: $0) }
    }
    
    /// Returns the custom time interval for address book search delay if it set in the given arguments
    fileprivate static func addressBookSearchDelay(_ arguments: ArgumentsType) -> TimeInterval? {
        guard let delayString = arguments.flagValueIfPresent(AutomationKey.addressBookRemoteSearchDelay.rawValue),
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

//MARK: - default implementation
extension ArgumentsType {

    var flagPrefix: String { return "--" }

    func hasFlag(_ name: String) -> Bool {
        return self.arguments.contains(flagPrefix + name)
    }

    func hasFlag<Flag: RawRepresentable>(_ flag: Flag) -> Bool where Flag.RawValue == String {
        return hasFlag(flag.rawValue)
    }

    func flagValueIfPresent(_ commandLineArgument: String) -> String? {
        for argument in arguments {
            let searchString = flagPrefix + commandLineArgument + "="
            if argument.hasPrefix(searchString) {
                return String(argument[searchString.index(searchString.startIndex, offsetBy: searchString.count)...])
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


// MARK: - Debug
extension AutomationHelper {
    
    /// Takes all files in the folder pointed at by `debugDataToInstall` and installs them
    /// in the shared folder, erasing any other file in that folder.
   public func installDebugDataIfNeeded() {
        
        guard let packageURL = self.debugDataToInstall,
            let appGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return }
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
        
        // DELETE
        let filesToDelete = try! FileManager.default.contentsOfDirectory(atPath: sharedContainerURL.path)
        filesToDelete.forEach {
            try! FileManager.default.removeItem(atPath: sharedContainerURL.appendingPathComponent($0).path)
        }
        
        // COPY
        try! FileManager.default.copyFolderRecursively(from: packageURL, to: sharedContainerURL, overwriteExistingFiles: true)
    }
    
}
