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

class MockPresentationDelegate: PresentationDelegate {

    var showConversationCalls: [ZMConversation] = []
    var showConversationListCalls: Int = 0
    var showUserProfileCalls: [UserType] = []
    var showConnectionRequestCalls: [UUID] = []
    var failedToPerformActionCalls: [(URLAction, Error)] = []
    var shouldPerformActionCalls: [URLAction] = []
    var completedURLActionCalls: [URLAction] = []
    var isPerformingActions = true

    func failedToPerformAction(_ action: URLAction, error: Error) {
        failedToPerformActionCalls.append((action, error))
    }

    func shouldPerformAction(_ action: URLAction, decisionHandler: @escaping (Bool) -> Void) {
        shouldPerformActionCalls.append(action)
        decisionHandler(isPerformingActions)
    }

    func shouldPerformActionWithMessage(_ message: String, action: URLAction, decisionHandler: @escaping (Bool) -> Void) {
        shouldPerformActionCalls.append(action)
        decisionHandler(isPerformingActions)
    }

    func completedURLAction(_ action: URLAction) {
        completedURLActionCalls.append(action)
    }

    func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?) {
        showConversationCalls.append(conversation)
    }

    func showConversationList() {
        showConversationListCalls += 1
    }

    func showUserProfile(user: UserType) {
        showUserProfileCalls.append(user)
    }

    func showConnectionRequest(userId: UUID) {
        showConnectionRequestCalls.append(userId)
    }

}
