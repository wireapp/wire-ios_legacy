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
import WireShareEngine


public final class SendableBatchObserver: SendableObserver {

    public let sendables: [Sendable]
    private var observers = [(Sendable, SendableObserverToken)]()

    public var sentHandler: (() -> Void)?
    public var progressHandler: ((Float) -> Void)?

    init(sendables: [Sendable]) {
        self.sendables = sendables
        setupObservers(for: sendables)
    }

    deinit {
        observers.forEach { (sendable, token) in
            sendable.remove(token)
        }

        observers = []
    }

    public var allSendablesSent: Bool {
        return observers.reduce(true) { (result, observer) -> Bool in
            return result && (observer.0.deliveryState == .sent || observer.0.deliveryState == .delivered)
        }
    }

    private func setupObservers(for sendables: [Sendable]) {
        sendables.forEach {
            observers.append(($0, ($0.registerObserverToken(self))))
        }
    }

    public func onDeliveryChanged() {
        if allSendablesSent {
            DispatchQueue.main.async { [weak self] in
                self?.sentHandler?()
            }
        }

        updateProgress()
    }

    private func updateProgress() {
        var totalProgress: Float = 0

        observers.forEach { (message, _) in
            if message.deliveryState == .sent || message.deliveryState == .delivered {
                totalProgress = totalProgress + 1.0 / Float(observers.count)
            } else {
                let messageProgress = (message.deliveryProgress ?? 0)
                totalProgress = totalProgress +  messageProgress / Float(observers.count)
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.progressHandler?(totalProgress)
        }
    }

}
