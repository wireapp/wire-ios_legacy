//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
class RecordingMockTransportSession: NSObject, TransportSessionType {

    var pushChannel: ZMPushChannel
    var cookieStorage: ZMPersistentCookieStorage
    var requestLoopDetectionCallback: ((String) -> Void)?

    let mockReachability = MockReachability()
    var reachability: ReachabilityProvider & TearDownCapable {
        return mockReachability
    }

    init(cookieStorage: ZMPersistentCookieStorage, pushChannel: ZMPushChannel) {
        self.pushChannel = pushChannel
        self.cookieStorage = cookieStorage

        super.init()
    }

    func tearDown() { }

    var didCallEnterBackground = false
    func enterBackground() {
        didCallEnterBackground = true
    }

    var didCallEnterForeground = false
    func enterForeground() {
        didCallEnterForeground = true
    }

    func prepareForSuspendedState() { }

    func cancelTask(with taskIdentifier: ZMTaskIdentifier) { }

    var lastEnqueuedRequest: ZMTransportRequest?
    func enqueueOneTime(_ request: ZMTransportRequest) {
        lastEnqueuedRequest = request
    }

    func attemptToEnqueueSyncRequest(generator: () -> ZMTransportRequest?) -> ZMTransportEnqueueResult {
        guard let request = generator() else {
            return ZMTransportEnqueueResult(didHaveLessRequestsThanMax: true, didGenerateNonNullRequest: false)
        }

        lastEnqueuedRequest = request

        return ZMTransportEnqueueResult(didHaveLessRequestsThanMax: true, didGenerateNonNullRequest: true)
    }

    func setAccessTokenRenewalFailureHandler(handler: @escaping ZMCompletionHandlerBlock) { }

    var didCallSetNetworkStateDelegate: Bool = false
    func setNetworkStateDelegate(_ delegate: ZMNetworkStateDelegate?) {
        didCallSetNetworkStateDelegate = true
    }

    func addCompletionHandlerForBackgroundSession(identifier: String, handler: @escaping () -> Void) { }

    var didCallConfigurePushChannel = false
    func configurePushChannel(consumer: ZMPushChannelConsumer, groupQueue: ZMSGroupQueue) {
        didCallConfigurePushChannel = true
    }

}
