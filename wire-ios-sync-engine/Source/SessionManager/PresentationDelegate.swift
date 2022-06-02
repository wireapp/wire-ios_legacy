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

public protocol PresentationDelegate: AnyObject {
    /// Called when a conversation at one particular message should be shown
    /// - parameter conversation: Conversation which will be performed.
    /// - parameter message: Message which the conversation will be opened at.
    func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?)

    /// Called when the conversation list should be shown
    func showConversationList()

    /// Called when an user profile screen should be presented
    /// - parameter user: The user which the profile will belong to.
    func showUserProfile(user: UserType)

    /// Called when the connection screen for a centain user shold be presented
    /// - parameter userId: The userId which will be connected to.
    func showConnectionRequest(userId: UUID)

    /// Called when an attempt was made to process a URLAction but failed
    ///
    /// - parameter action: Action which failed to be performed.
    /// - parameter error: Error describing why the action failed.
    func failedToPerformAction(_ action: URLAction, error: Error)

    /// Called before attempt is made to process a URLAction, this is a opportunity for asking the user
    /// to confirm the action. The answer is provided via the decisionHandler.
    ///
    /// - parameter action: Action which will be performed.
    /// - parameter decisionHandler: Block which should be executed when the decision has been to perform the action or not.
    /// - parameter shouldPerformAction: **true**: perform the action, **false**: abort the action
    func shouldPerformAction(_ action: URLAction, decisionHandler: @escaping (_ shouldPerformAction: Bool) -> Void)

    /// Called before attempt is made to process a URLAction, this is a opportunity for asking the user
    /// to confirm the action. The answer is provided via the decisionHandler.
    ///
    /// - parameter message: The string to be used for the warning message.
    /// - parameter action: Action which will be performed.
    /// - parameter decisionHandler: Block which should be executed when the decision has been to perform the action or not.
    /// - parameter shouldPerformAction: **true**: perform the action, **false**: abort the action

    func shouldPerformActionWithMessage(_ message: String, action: URLAction, decisionHandler: @escaping (_ shouldPerformAction: Bool) -> Void)

    /// Called when an URLAction was successfully performed.
    func completedURLAction(_ action: URLAction)
}
