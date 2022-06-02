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

public typealias BackgroundFetchHandler = (_ fetchResult: UIBackgroundFetchResult) -> Void

public typealias BackgroundTaskHandler = (_ taskResult: BackgroundTaskResult) -> Void

private let zmLog = ZMSLog(tag: "OperationStatus")

@objc(ZMOperationStatusDelegate)
public protocol OperationStatusDelegate: AnyObject {

    @objc(operationStatusDidChangeState:)
    func operationStatus(didChangeState state: SyncEngineOperationState)
}

@objc(ZMBackgroundTaskResult)
public enum BackgroundTaskResult: UInt {
    case finished
    case failed
}

@objc public enum SyncEngineOperationState: UInt, CustomStringConvertible {
    case background
    case backgroundCall
    case backgroundFetch
    case backgroundTask
    case foreground

    public var description: String {
        switch self {
        case .background:
            return "background"
        case .backgroundCall:
            return "backgroundCall"
        case .backgroundFetch:
            return "backgroundFetch"
        case .backgroundTask:
            return "backgroundTask"
        case .foreground:
            return "foreground"
        }
    }
}

@objcMembers
public class OperationStatus: NSObject {

    public weak var delegate: OperationStatusDelegate?

    private var backgroundFetchTimer: Timer?
    private var backgroundTaskTimer: Timer?

    private var backgroundFetchHandler: BackgroundFetchHandler? {
        didSet {
            updateOperationState()
        }
    }

    private var backgroundTaskHandler: BackgroundTaskHandler? {
        didSet {
            updateOperationState()
        }
    }

    public var isInBackground = true {
        didSet {
            updateOperationState()
        }
    }

    public var hasOngoingCall = false {
        didSet {
            updateOperationState()
        }
    }

    public private(set) var operationState: SyncEngineOperationState = .background {
        didSet {
            delegate?.operationStatus(didChangeState: operationState)
        }
    }

    public func startBackgroundFetch(withCompletionHandler completionHandler: @escaping BackgroundFetchHandler) {
        startBackgroundFetch(timeout: 30.0, withCompletionHandler: completionHandler)
    }

    public func startBackgroundFetch(timeout: TimeInterval, withCompletionHandler completionHandler: @escaping BackgroundFetchHandler) {
        guard backgroundFetchHandler == nil else {
            return completionHandler(.failed)
        }

        backgroundFetchHandler = completionHandler
        backgroundFetchTimer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(backgroundFetchTimeout), userInfo: nil, repeats: false)
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

    public func startBackgroundTask(withCompletionHandler completionHandler: @escaping BackgroundTaskHandler) {
        startBackgroundTask(timeout: 30.0, withCompletionHandler: completionHandler)
    }

    public func startBackgroundTask(timeout: TimeInterval, withCompletionHandler completionHandler: @escaping BackgroundTaskHandler) {
        guard backgroundTaskHandler == nil, isInBackground else {
            return completionHandler(.failed)
        }

        backgroundTaskHandler = completionHandler
        backgroundTaskTimer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(backgroundTaskTimeout), userInfo: nil, repeats: false)
    }

    func backgroundFetchTimeout() {
        finishBackgroundFetch(withFetchResult: .failed)
    }

    func backgroundTaskTimeout() {
        finishBackgroundTask(withTaskResult: .failed)
    }

    public func finishBackgroundFetch(withFetchResult result: UIBackgroundFetchResult) {
        backgroundFetchTimer?.invalidate()
        backgroundFetchTimer = nil
        DispatchQueue.main.async {
            self.backgroundFetchHandler?(result)
            self.backgroundFetchHandler = nil
        }
    }

    public func finishBackgroundTask(withTaskResult result: BackgroundTaskResult) {
        backgroundTaskTimer?.invalidate()
        backgroundTaskTimer = nil
        DispatchQueue.main.async {
            self.backgroundTaskHandler?(result)
            self.backgroundTaskHandler = nil
        }
    }

    fileprivate func updateOperationState() {
        let oldOperationState = operationState
        let newOperationState = calculatedOperationState

        if newOperationState != oldOperationState {
            zmLog.debug("operation state changed from \(oldOperationState) to \(newOperationState)")
            operationState = newOperationState
        }
    }

    fileprivate var calculatedOperationState: SyncEngineOperationState {
        if isInBackground {
            if hasOngoingCall {
                return .backgroundCall
            }

            if backgroundFetchHandler != nil {
                return .backgroundFetch
            }

            if backgroundTaskHandler != nil {
                return .backgroundTask
            }

            return .background
        } else {
            return .foreground
        }
    }

}
