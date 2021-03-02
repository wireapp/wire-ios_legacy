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
import WireSyncEngine
import AppCenterCrashes

enum DebugActions {

    /// Shows an alert with the option to copy text to the clipboard
    static func alert(
        _ message: String,
        title: String = "",
        textToCopy: String? = nil) {
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let textToCopy = textToCopy {
            alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { _ in
                UIPasteboard.general.string = textToCopy
            }))
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        controller.present(alert, animated: false)
    }

    /// Check if there is any unread conversation, if there is, show an alert with the name and ID of the conversation
    static func findUnreadConversationContributingToBadgeCount(_ type: SettingsCellDescriptorType) {
        guard let userSession = ZMUserSession.shared() else { return }
        let predicate = ZMConversation.predicateForConversationConsideredUnread()!

        let uiMOC = userSession.managedObjectContext
        let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        let allConversations = uiMOC.fetchOrAssert(request: fetchRequest)

        if let convo = allConversations.first(where: { predicate.evaluate(with: $0) }) {

            let message = ["Found an unread conversation:",
                       "\(convo.displayName)",
                        "<\(convo.remoteIdentifier?.uuidString ?? "n/a")>"
                ].joined(separator: "\n")
            let textToCopy = convo.remoteIdentifier?.uuidString
            alert(message, textToCopy: textToCopy)
        } else {
            alert("No unread conversation")
        }
    }

    /// Shows the user ID of the self user
    static func showUserId(_ type: SettingsCellDescriptorType) {
        guard let userSession = ZMUserSession.shared(),
            let selfUser = (userSession.selfUser as? ZMUser)
        else { return }

        alert(
            selfUser.remoteIdentifier.uuidString,
            title: "User Id",
            textToCopy: selfUser.remoteIdentifier.uuidString
        )
    }

    /// Check if there is any unread conversation, if there is, show an alert with the name and ID of the conversation
    static func findUnreadConversationContributingToBackArrowDot(_ type: SettingsCellDescriptorType) {
        guard let userSession = ZMUserSession.shared() else { return }
        let predicate = ZMConversation.predicateForConversationConsideredUnreadExcludingSilenced()!

        if let convo = (ZMConversationList.conversations(inUserSession: userSession) as! [ZMConversation])
            .first(where: predicate.evaluate) {
            let message = ["Found an unread conversation:",
                             "\(convo.displayName)",
                "<\(convo.remoteIdentifier?.uuidString ?? "n/a")>"
                ].joined(separator: "\n")
            let textToCopy = convo.remoteIdentifier?.uuidString
            alert(message, textToCopy: textToCopy)

        } else {
            alert("No unread conversation")
        }
    }

    /// Sends a message that will fail to decode on every other device, on the first conversation of the list
    static func sendBrokenMessage(_ type: SettingsCellDescriptorType) {
        guard
            let userSession = ZMUserSession.shared(),
            let conversation = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession).firstObject as? ZMConversation
            else {
                return
        }

        var external = External()
        if let otr = "broken_key".data(using: .utf8) {
             external.otrKey = otr
        }
        let genericMessage = GenericMessage(content: external)

        userSession.enqueue {
            try! conversation.appendClientMessage(with: genericMessage, expires: false, hidden: false)
        }
    }

    /// Sends a number of messages to the top conversation in the list, in an asynchronous fashion
    static func spamWithMessages(amount: Int) {
        guard
            amount > 0,
            let userSession = ZMUserSession.shared(),
            let conversation = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession).firstObject as? ZMConversation
            else {
                return
        }
        let nonce = UUID()

        func sendNext(count: Int) {
            userSession.enqueue {
                try! conversation.appendText(content: "Message #\(count+1), series \(nonce)")
            }
            guard count + 1 < amount else { return }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.4,
                execute: { sendNext(count: count + 1) }
            )
        }

        sendNext(count: 0)
    }

    static func triggerSlowSync(_ type: SettingsCellDescriptorType) {
        ZMUserSession.shared()?.syncManagedObjectContext.performGroupedBlock {
            ZMUserSession.shared()?.requestSlowSync()
        }
    }

    static func showAnalyticsIdentifier(_ type: SettingsCellDescriptorType) {
        guard
            let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false),
            let userSession = ZMUserSession.shared()
        else {
            return
        }

        let selfUser = ZMUser.selfUser(inUserSession: userSession)

        let alert = UIAlertController(
            title: "Analytics identifier",
            message: "\(selfUser.analyticsIdentifier ?? "nil")",
            alertAction: .ok(style: .cancel)
        )

        controller.present(alert, animated: true)
    }

    static func generateTestCrash(_ type: SettingsCellDescriptorType) {
        MSCrashes.generateTestCrash()
    }

    static func reloadUserInterface(_ type: SettingsCellDescriptorType) {
        guard let appRootRouter = (UIApplication.shared.delegate as? AppDelegate)?.appRootRouter else {
            return
        }

        appRootRouter.reload()
    }

    static func resetCallQualitySurveyMuteFilter(_ type: SettingsCellDescriptorType) {
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) else { return }

        CallQualityController.resetSurveyMuteFilter()

        let alert = UIAlertController(title: "Success",
                                      message: "The call quality survey will be displayed after the next call.",
                                      alertAction: .ok(style: .cancel))

        controller.present(alert, animated: true)
    }

    /// Accepts a debug command
    static func enterDebugCommand(_ type: SettingsCellDescriptorType) {
        askString(title: "Debug command") { _ in
            alert("Command not recognized")
        }
    }

    static func appendMessagesToDatabase(count: Int) {
        let userSession = ZMUserSession.shared()!
        let conversation = ZMConversationList.conversations(inUserSession: userSession).firstObject! as! ZMConversation
        let conversationId = conversation.objectID

        let syncContext = userSession.syncManagedObjectContext
        syncContext.performGroupedBlock {
            let syncConversation = try! syncContext.existingObject(with: conversationId) as! ZMConversation
            let messages: [ZMClientMessage] = (0...count).map { i in
                let nonce = UUID()
                let genericMessage = GenericMessage(content: Text(content: "Debugging message \(i): Append many messages to the top conversation; Append many messages to the top conversation;"), nonce: nonce)
                let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: syncContext)
                try! clientMessage.setUnderlyingMessage(genericMessage)
                clientMessage.sender = ZMUser.selfUser(in: syncContext)

                clientMessage.expire()
                clientMessage.linkPreviewState = .done

                return clientMessage
            }
            syncConversation.mutableMessages.addObjects(from: messages)
            userSession.syncManagedObjectContext.saveOrRollback()
        }
    }

    static func recalculateBadgeCount(_ type: SettingsCellDescriptorType) {
        guard let userSession = ZMUserSession.shared() else { return }
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) else { return }

        var conversations: [ZMConversation]?
        userSession.syncManagedObjectContext.performGroupedBlock {
            conversations = try? userSession.syncManagedObjectContext.fetch(NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName()))
            conversations?.forEach({ _ = $0.estimatedUnreadCount })
        }
        userSession.syncManagedObjectContext.dispatchGroup.wait(forInterval: 5)
        userSession.syncManagedObjectContext.performGroupedBlockAndWait {
            conversations = nil
            userSession.syncManagedObjectContext.saveOrRollback()
        }

        let alertController = UIAlertController(title: "Updated", message: "Badge count  has been re-calculated", alertAction: .ok(style: .cancel))
        controller.show(alertController, sender: nil)
    }

    static func askNumber(title: String, _ callback: @escaping (Int) -> Void) {
        askString(title: title) {
            if let number = NumberFormatter().number(from: $0) {
                callback(number.intValue)
            } else {
              alert("ERROR: not a number")
            }
        }
    }

    static func askString(title: String, _ callback: @escaping (String) -> Void) {
        guard let controllerToPresentOver = UIApplication.shared.topmostViewController(onlyFullScreen: false) else { return }

        let controller = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "general.ok".localized, style: .default) { [controller] _ in
            callback(controller.textFields?.first?.text ?? "")
        }

        controller.addTextField()

        controller.addAction(.cancel { })
        controller.addAction(okAction)
        controllerToPresentOver.present(controller, animated: true, completion: nil)
    }

    static func appendMessagesInBatches(count: Int) {
        var left = count
        let step = 10_000

        repeat {
            let toAppendInThisStep = left < step ? left : step

            left -= toAppendInThisStep

            appendMessages(count: toAppendInThisStep)
        }
        while(left > 0)
    }

    static func appendMessages(count: Int) {
        let batchSize = 5_000

        var currentCount = count

        repeat {
            let thisBatchCount = currentCount > batchSize ? batchSize : currentCount

            appendMessagesToDatabase(count: thisBatchCount)

            currentCount -= thisBatchCount
        }
        while (currentCount > 0)
    }
}
