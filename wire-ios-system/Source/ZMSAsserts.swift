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

/// Reports an error and terminates the application
public func fatal(_ message: String,
                  file: StaticString = #file,
                  line: UInt = #line) -> Never  {
    ZMAssertionDump_NSString("Swift assertion", "\(file)", Int32(line), message)
    fatalError(message, file: file, line: line)
}

/// If the condition is not true, reports an error and terminates the application
public func require(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if(!condition) {
        fatal(message, file: file, line: line)
    }
}

@objc public enum Environment: UInt8 {
    case appStore, `internal`, debug, develop, unknown

    static var current: Environment {
        guard let identifier = Bundle.main.bundleIdentifier else { return .unknown }
        switch identifier {
        case "com.wearezeta.zclient.ios": return .appStore
        case "com.wearezeta.zclient-alpha": return .debug
        case "com.wearezeta.zclient.ios-internal": return .internal
        case "com.wearezeta.zclient.ios-development": return .develop
        default: return .unknown
        }
    }

    var isAppStore: Bool {
        return self == .appStore
    }
}

/// Termiantes the application if the condition is `false` and the current build is not an AppsStore build
public func requireInternal(_ condition: Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    guard !Environment.current.isAppStore, !condition else { return }
    fatal(message(), file: file, line: line)
}

/// Termiantes the application if the current build is not an AppsStore build
public func requireInternalFailure(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    guard !Environment.current.isAppStore else { return }
    fatal(message(), file: file, line: line)
}
