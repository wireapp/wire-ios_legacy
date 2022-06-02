//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import Starscream

@available(iOSApplicationExtension 13.0, iOS 13.0, *)
@objcMembers
class StarscreamPushChannel: NSObject, PushChannelType {

    var webSocket: WebSocket?
    var workQueue: OperationQueue
    let environment: BackendEnvironmentProvider
    let scheduler: ZMTransportRequestScheduler
    weak var consumer: ZMPushChannelConsumer?
    var consumerQueue: ZMSGroupQueue?
    var pingTimer: ZMTimer?

    var clientID: String? {
        didSet {
            Logging.pushChannel.debug("Setting client ID")
            scheduleOpen()
        }
    }

    var accessToken: AccessToken? {
        didSet {
            Logging.pushChannel.debug("Setting access token")
        }
    }

    var keepOpen: Bool = false {
        didSet {
            if keepOpen {
                scheduleOpen()
            } else {
                self.close()
            }
        }
    }

    var canOpenConnection: Bool {
        return keepOpen && websocketURL != nil && consumer != nil
    }

    var websocketURL: URL? {
        let url = environment.backendWSURL.appendingPathComponent("/await")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "client", value: clientID)]

        return urlComponents?.url
    }

    required init(scheduler: ZMTransportRequestScheduler,
                  userAgentString: String,
                  environment: BackendEnvironmentProvider, queue: OperationQueue) {
        self.environment = environment
        self.scheduler = scheduler
        self.workQueue = queue
    }

    func reachabilityDidChange(_ reachability: ReachabilityProvider) {
        let didGoOnline = reachability.mayBeReachable && !reachability.oldMayBeReachable
        guard didGoOnline else { return }

        scheduleOpen()
    }

    func setPushChannelConsumer(_ consumer: ZMPushChannelConsumer?, queue: ZMSGroupQueue) {
        self.consumerQueue = queue
        self.consumer = consumer

        if consumer == nil {
            close()
        } else {
            scheduleOpen()
        }
    }

    func close() {
        Logging.pushChannel.debug("Push channel was closed")

        scheduler.performGroupedBlock {
            self.webSocket?.disconnect()
        }
    }

    func open() {
        guard
            keepOpen,
            webSocket == nil,
            let accessToken = accessToken,
            let websocketURL = websocketURL
        else {
            return
        }

        var connectionRequest = URLRequest(url: websocketURL)
        connectionRequest.setValue("\(accessToken.type) \(accessToken.token)", forHTTPHeaderField: "Authorization")

        let certificatePinning = StarscreamCertificatePinning(environment: environment)
        webSocket = WebSocket(request: connectionRequest, certPinner: certificatePinning, useCustomEngine: true)
        webSocket?.delegate = self
        if let queue = workQueue.underlyingQueue {
            webSocket?.callbackQueue = queue
        }
        webSocket?.connect()

        Logging.pushChannel.debug("Connecting websocket..")
    }

    func scheduleOpen() {
        scheduler.performGroupedBlock { [weak self] in
            self?.scheduleOpenInternal()
        }
    }

    private func scheduleOpenInternal() {
        guard canOpenConnection else {
            Logging.pushChannel.debug("Conditions for scheduling opening not fulfilled, waiting...")
            return
        }
        Logging.pushChannel.debug("Schedule opening..")
        scheduler.add(ZMOpenPushChannelRequest())
    }

    fileprivate func onClose() {
        webSocket = nil
        stopPingTimer()

        consumerQueue?.performGroupedBlock {
            self.consumer?.pushChannelDidClose()
        }

        if keepOpen {
            scheduleOpen()
        }
    }

    fileprivate func onOpen() {
        startPingTimer()

        consumerQueue?.performGroupedBlock({
            self.consumer?.pushChannelDidOpen()
        })
    }

    private func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    fileprivate func schedulePingTimer() {
        stopPingTimer()
        startPingTimer()
    }

    fileprivate func startPingTimer() {
        let timer = ZMTimer(target: self, operationQueue: workQueue)
        timer?.fire(afterTimeInterval: 30)
        pingTimer = timer
    }
}

@available(iOSApplicationExtension 13.0, iOS 13.0, *)
extension StarscreamPushChannel: ZMTimerClient {

    func timerDidFire(_ timer: ZMTimer!) {
        Logging.pushChannel.debug("Sending ping")
        webSocket?.write(ping: Data())
        schedulePingTimer()
    }

}

@available(iOSApplicationExtension 13.0, iOS 13.0, *)
extension StarscreamPushChannel: WebSocketDelegate {

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {

        case .connected(_):
            Logging.pushChannel.debug("Sending ping")
            onOpen()
        case .disconnected(_, _):
            Logging.pushChannel.debug("Websocket disconnected")
            onClose()
        case .text(_):
            break
        case .binary(let data):
            Logging.pushChannel.debug("Received data")
            guard
                let transportData = try? JSONSerialization.jsonObject(with: data, options: []) as? ZMTransportData
            else { break }

            consumerQueue?.performGroupedBlock { [weak self] in
                self?.consumer?.pushChannelDidReceive(transportData)
            }
        case .pong(_):
            break
        case .ping(_):
            break
        case .error(_):
            onClose()
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            onClose()
        }
    }

}

class StarscreamCertificatePinning: CertificatePinning {

    let environment: BackendEnvironmentProvider

    init(environment: BackendEnvironmentProvider) {
        self.environment = environment
    }

    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ())) {
        if environment.verifyServerTrust(trust: trust, host: domain) {
            completion(.success)
        } else {
            completion(.failed(nil))
        }
    }

}
