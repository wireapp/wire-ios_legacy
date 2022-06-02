//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@objc
public protocol TransportSessionType: class, ZMBackgroundable, ZMRequestCancellation, TearDownCapable {
    
    var reachability: ReachabilityProvider & TearDownCapable { get }
    
    var pushChannel: ZMPushChannel { get }
    
    var cookieStorage: ZMPersistentCookieStorage { get }
    
    var requestLoopDetectionCallback: ((_ path: String) -> Void)? { get set }
    
    @objc(enqueueOneTimeRequest:) 
    func enqueueOneTime(_ request: ZMTransportRequest)
    
    @objc(attemptToEnqueueSyncRequestWithGenerator:)
    func attemptToEnqueueSyncRequest(generator: ZMTransportRequestGenerator) -> ZMTransportEnqueueResult
    
    @objc(setAccessTokenRenewalFailureHandler:)
    func setAccessTokenRenewalFailureHandler(handler: @escaping ZMCompletionHandlerBlock)
    
    func setNetworkStateDelegate(_ delegate: ZMNetworkStateDelegate?)
    
    @objc(addCompletionHandlerForBackgroundSessionWithIdentifier:handler:)
    func addCompletionHandlerForBackgroundSession(identifier: String, handler: @escaping () -> Void)
    
    @objc(configurePushChannelWithConsumer:groupQueue:)
    func configurePushChannel(consumer: ZMPushChannelConsumer, groupQueue: ZMSGroupQueue)
    
}

extension ZMTransportSession: TransportSessionType {}
