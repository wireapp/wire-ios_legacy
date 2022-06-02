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
import WireRequestStrategy
import WireDataModel

public class MockApplicationStatus: NSObject, ApplicationStatus {

    public var requestCancellation: ZMRequestCancellation {
        return self.mockTaskCancellationDelegate
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        return self.mockClientRegistrationStatus
    }

    public var mockSynchronizationState: SynchronizationState = .unauthenticated
    public let mockTaskCancellationDelegate = MockTaskCancellationDelegate()
    public var mockClientRegistrationStatus = MockClientRegistrationStatus()

    public var synchronizationState: SynchronizationState {
        return mockSynchronizationState
    }

    public var mockOperationState: OperationState = .foreground

    public var operationState: OperationState {
        return mockOperationState
    }

    public var cancelledIdentifiers: [ZMTaskIdentifier] {
        return mockTaskCancellationDelegate.cancelledIdentifiers
    }

    public var deletionCalls: Int {
        return mockClientRegistrationStatus.deletionCalls
    }

    public var slowSyncWasRequested = false
    public func requestSlowSync() {
        slowSyncWasRequested = true
    }

}

public class MockTaskCancellationDelegate: NSObject, ZMRequestCancellation {
    public var cancelledIdentifiers = [ZMTaskIdentifier]()

    public func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }
}

public class MockClientRegistrationStatus: NSObject, ClientRegistrationDelegate {

    public var deletionCalls: Int = 0

    /// Notify that the current client was deleted remotely
    public func didDetectCurrentClientDeletion() {
        deletionCalls += 1
    }

    public var clientIsReadyForRequests: Bool {
        return true
    }
}

class MockPushMessageHandler: NSObject, PushMessageHandler {

    public func didFailToSend(_ message: ZMMessage) {
        failedToSend.append(message)
    }

    fileprivate(set) var failedToSend: [ZMMessage] = []
}

class MockSyncProgress: NSObject, SyncProgress {

    var currentSyncPhase: SyncPhase = .done

    var didFinishCurrentSyncPhase: SyncPhase?
    func finishCurrentSyncPhase(phase: SyncPhase) {
        didFinishCurrentSyncPhase = phase
    }

    var didFailCurrentSyncPhase: SyncPhase?
    func failCurrentSyncPhase(phase: SyncPhase) {
        didFailCurrentSyncPhase = phase
    }

}
