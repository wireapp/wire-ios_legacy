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
import WireDataModel
import WireSyncEngine

final class SimpleNotificationService: UNNotificationServiceExtension, Loggable {

    // MARK: - Types

    typealias ContentHandler = (UNNotificationContent) -> Void

    // MARK: - Properties

    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared
    private var currentTasks: [String : Task<(), Never>] = [:]
    private var latestContentHandler: ContentHandler?
    private var coreDataStacksByAccountID: [String: CoreDataStack] = [:]

//    private var

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
                guard let accountID = request.content.accountID else { throw NotificationServiceError.noAccount }
                let coreDataStack = try await dataStackForAccount(accountID: accountID)
                let eventDecoder =   EventDecoder(eventMOC: coreDataStack.eventContext, syncMOC: coreDataStack.syncContext)
                let job = try Job(request: request, eventDecoder: eventDecoder)
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

private extension SimpleNotificationService {

    func dataStackForAccount(accountID: UUID) async throws -> CoreDataStack {
        guard let groupID = Bundle.main.applicationGroupIdentifier else {
            throw NotificationServiceError.noAppGroupID
        }
        if let stack = coreDataStacksByAccountID[accountID.uuidString] {
            return stack
        }

        let sharedContainerURL = FileManager.sharedContainerDirectory(for: groupID)
        let accountManager = AccountManager(sharedDirectory: sharedContainerURL)
        guard let account = accountManager.account(with: accountID) else {
            throw NotificationServiceError.noAccount
        }
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL
        )
        coreDataStacksByAccountID[accountID.uuidString] = coreDataStack
        try await coreDataStack.loadStores()
        return coreDataStack
    }
}

extension CoreDataStack {

    func loadStores() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            loadStores {
                if let error = $0 {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume(with: .success(()))
                }
            }
        }
    }

}
