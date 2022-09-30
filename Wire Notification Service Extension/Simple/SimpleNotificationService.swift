//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import UserNotifications
import WireTransport
import WireCommonComponents

final class SimpleNotificationService: UNNotificationServiceExtension, Loggable {

    // MARK: - Types

    typealias ContentHandler = (UNNotificationContent) -> Void

    // MARK: - Properties

    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared
    private var currentTasks: [String : Task<(), Never>] = [:]
    private var latestContentHandler: ContentHandler?

    // MARK: - Life cycle

    override init() {
        super.init()
    }

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping ContentHandler
    ) {
        logger.trace("\(request.identifier, privacy: .public): received request. Service is \(String(describing: self), privacy: .public)")

        guard #available(iOS 15, *) else {
            logger.error("\(request.identifier, privacy: .public): iOS 15 is not available")
            contentHandler(.debugMessageIfNeeded(message: "iOS 15 not available"))
            return
        }

        let task = Task { [weak self] in
            do {
                logger.trace("\(request.identifier, privacy: .public): initializing job")
                let job = try Job(request: request)
                let content = try await job.execute()
                logger.trace("\(request.identifier, privacy: .public): showing notification")
                contentHandler(content)
            } catch {
                let message = "\(request.identifier): failed with error: \(String(describing: error))"
                logger.error("\(message, privacy: .public)")
                contentHandler(.debugMessageIfNeeded(message: message))
            }
            self?.currentTasks[request.identifier] = nil
        }
        currentTasks[request.identifier] = task
        latestContentHandler = contentHandler
    }

    override func serviceExtensionTimeWillExpire() {
        logger.warning("extension (\(String(describing: self), privacy: .public) is expiring")
        currentTasks.values.forEach { task in
            task.cancel()
        }
        currentTasks = [:]
        latestContentHandler?(.debugMessageIfNeeded(message: "extension (\(String(describing: self)) is expiring"))
    }

}
