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
import os.log

/// Represents an entry to be logged.
@objcMembers
public class ZMSLogEntry: NSObject {
    public let text: String
    public let timestamp: Date

    internal init(text: String, timestamp: Date) {
        self.text = text
        self.timestamp = timestamp
    }
}

/// A logging facility based on tags to switch on and off certain logs
///
/// - Note:
/// Usage. Add:
///
///     ```
///     private let zmLog = ZMLog(tag: "Networking")
///     ```
///
/// at the top of your .swift file and log with:
///     
///     zmLog.debug("Debug information")
///     zmLog.warn("A serious warning!")
///
@objc
public class ZMSLog : NSObject {

    public typealias LogHook = (_ level: ZMLogLevel_t, _ tag: String?, _ message: String) -> (Void)
    public typealias LogEntryHook = (
        _ level: ZMLogLevel_t,
        _ tag: String?,
        _ message: ZMSLogEntry,
        _ isSafe: Bool) -> (Void)

    /// Tag to use for this logging facility
    fileprivate let tag: String

    /// FileHandle instance used for updating the log
    fileprivate static var updatingHandle: FileHandle?

    /// Log observers
    fileprivate static var logHooks : [UUID : LogEntryHook] = [:]
    
    @objc public init(tag: String) {
        self.tag = tag
        logQueue.sync {
            ZMSLog.register(tag: tag)
        }
    }
    
    /// Wait for all log operations to be completed
    @objc
    public static func sync() {
        logQueue.sync {
            // no op
        }
    }
}

// MARK: - Emit logs
extension ZMSLog {
    
    public func safePublic(_ message: @autoclosure () -> SanitizedString,
                           level: ZMLogLevel_t = .info,
                           file: String = #file,
                           line: UInt = #line) {
        let entry = ZMSLogEntry(text: message().value, timestamp: Date())
        ZMSLog.logEntry(entry, level: level, isSafe: true, tag: tag, file: file, line: line)
    }
    
    public func error(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.error, message: message(), tag: self.tag, file: file, line:line)
    }
    public func warn(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.warn, message: message(), tag: self.tag, file: file, line:line)
    }
    public func info(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.info, message: message(), tag: self.tag, file: file, line:line)
    }
    public func debug(_ message: @autoclosure () -> String, file: String = #file, line: UInt = #line) {
        ZMSLog.logWithLevel(.debug, message: message(), tag: self.tag, file: file, line:line)
    }
}

// MARK: - Conditional execution
// These let us run code only if the log level is set correspondingly. That can be usefull when creating the logging is expensive.
//
// zmLog.ifError {
//     // do expensive calculation of 'foo' here
//     zmLog.error("foo: \(foo)")
// }
extension ZMSLog {

    /// Executes the closure only if the log level is Warning or higher
    public func ifWarn(_ closure: () -> Void) -> Void {
        if ZMLogLevel_t.warn.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
    
    /// Executes the closure only if the log level is Info or higher
    public func ifInfo(_ closure: () -> Void) -> Void {
        if ZMLogLevel_t.info.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
    /// Executes the closure only if the log level is Debug or higher
    public func ifDebug(_ closure: () -> Void) -> Void {
        if ZMLogLevel_t.debug.rawValue <= ZMSLog.getLevel(tag: self.tag).rawValue {
            closure()
        }
    }
}

// NOTE:
// I could use NotificationCenter for this, but I would have to deal with
// passing and extracting (and downcasting and wrapping) the parameters from the user info dictionary
// I prefer handling my own delegates

/// Opaque token to unregister observers
@objc(ZMSLogLogHookToken)
public final class LogHookToken : NSObject {

    /// Internal identifier
    fileprivate let token : UUID
    
    override init() {
        self.token = UUID()
        super.init()
    }
}

// MARK: - Hooks (log observing)
extension ZMSLog {
    
    /// Notify all hooks of a new log
    fileprivate static func notifyHooks(level: ZMLogLevel_t,
                                        tag: String?,
                                        entry: ZMSLogEntry,
                                        isSafe: Bool) {
        self.logHooks.forEach { (_, hook) in
            hook(level, tag, entry, isSafe)
        }
    }

    // MARK: - Rich Hooks

    /// Adds a log hook
    @objc static public func addEntryHook(logHook: @escaping LogEntryHook) -> LogHookToken {
        var token : LogHookToken! = nil
        logQueue.sync {
            token = self.nonLockingAddEntryHook(logHook: logHook)
        }
        return token
    }

    /// Adds a log hook without locking
    @objc static public func nonLockingAddEntryHook(logHook: @escaping LogEntryHook) -> LogHookToken {
        let token = LogHookToken()
        self.logHooks[token.token] = logHook
        return token
    }

    
    /// Remove a log hook
    @objc static public func removeLogHook(token: LogHookToken) {
        logQueue.sync {
            _ = self.logHooks.removeValue(forKey: token.token)
        }
    }
    
    /// Remove all log hooks
    @objc static public func removeAllLogHooks() {
        logQueue.sync {
            self.logHooks = [:]
        }
    }
}

extension ZMLogLevel_t {
    @available(iOS 10.0, *)
    var logLevel: OSLogType {
        switch self {
        case .public, .error, .warn:
            return .error
        case .info:
            return .info
        case .debug:
            return .debug
        @unknown default:
            return .error
        }
    }
}

// MARK: - Internal stuff
extension ZMSLog {
    
    @objc static public func logWithLevel(_ level: ZMLogLevel_t, message:  @autoclosure () -> String, tag: String?, file: String = #file, line: UInt = #line) {
        let entry = ZMSLogEntry(text: message(), timestamp: Date())
        logEntry(entry, level: level, isSafe: false, tag: tag, file: file, line: line)
    }
    
    static private func logEntry(
        _ entry: ZMSLogEntry,
        level: ZMLogLevel_t,
        isSafe: Bool,
        tag: String?,
        file: String = #file,
        line: UInt = #line)
    {
        logQueue.async {
            if let tag = tag {
                self.register(tag: tag)
            }
        
            if tag == nil || level.rawValue <= ZMSLog.getLevelNoLock(tag: tag!).rawValue {
                os_log("%{public}@", log: self.logger(tag: tag), type: level.logLevel, entry.text)
                self.notifyHooks(level: level, tag: tag, entry: entry, isSafe: isSafe)
            }
        }
    }
}

// MARK: - Save on disk & file management
extension ZMSLog {
    
    @objc static public var previousLog: Data? {
        guard let previousLogPath = self.previousLogPath else { return nil }
        return readFile(at: previousLogPath)
    }
    
    @objc static public var currentLog: Data? {
        guard let currentLogPath = self.currentLogPath else { return nil }
        return readFile(at: currentLogPath)
    }

    static private func readFile(at url: URL) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        
        try? handle.wr_synchronizeFile()
        
        return handle.readDataToEndOfFile()
    }
    
    @objc static public let previousLogPath: URL? = cachesDirectory?.appendingPathComponent("previous.log")
    
    @objc static public let currentLogPath: URL? = cachesDirectory?.appendingPathComponent("current.log")
    
    @objc public static func clearLogs() {
        guard let previousLogPath = previousLogPath, let currentLogPath = currentLogPath else { return }
        logQueue.async {
            closeHandle()
            let manager = FileManager.default
            try? manager.removeItem(at: previousLogPath)
            try? manager.removeItem(at: currentLogPath)
        }
    }
    
    @objc public static func switchCurrentLogToPrevious() {
        guard let previousLogPath = previousLogPath, let currentLogPath = currentLogPath else { return }
        logQueue.async {
            closeHandle()
            let manager = FileManager.default
            try? manager.removeItem(at: previousLogPath)
            try? manager.moveItem(at: currentLogPath, to: previousLogPath)
        }
    }
    
    static var cachesDirectory: URL? {
        let manager = FileManager.default
        return manager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    static public var pathsForExistingLogs: [URL] {
        var paths: [URL] =  []
        if let currentPath = currentLogPath, currentLog != nil {
            paths.append(currentPath)
        }
        if let previousPath = previousLogPath, previousLog != nil  {
            paths.append(previousPath)
        }
        return paths
    }

    static private func closeHandle() {
        updatingHandle?.closeFile()
        updatingHandle = nil
    }

    static func appendToCurrentLog(_ string: String) {
        
        guard let currentLogURL = self.currentLogPath else { return }
        let currentLogPath = currentLogURL.path
        let manager = FileManager.default
        
        if !manager.fileExists(atPath: currentLogPath) {
            manager.createFile(atPath: currentLogPath, contents: nil, attributes: nil)
        }
        
        if updatingHandle == nil {
            updatingHandle = FileHandle(forUpdatingAtPath: currentLogPath)
            updatingHandle?.seekToEndOfFile()
        }
        
        let data = Data(string.utf8)
        
        do {
            try updatingHandle?.wr_write(data)
        } catch {
            updatingHandle = nil
        }
    }
}

/// Synchronization queue
let logQueue = DispatchQueue(label: "ZMSLog")
