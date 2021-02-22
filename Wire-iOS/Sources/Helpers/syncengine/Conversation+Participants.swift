//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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


import WireSyncEngine

extension GroupDetailsConversation where Self: ZMConversation {
    var freeParticipantSlots: Int {
        return ZMConversation.maxParticipants - localParticipants.count
    }
}

extension ZMConversation {
    private enum NetworkError: Error {
        case offline
    }

    static let legacyGroupVideoParticipantLimit: Int = 4

    static let maxParticipants: Int = 500

    static var maxParticipantsExcludingSelf: Int {
        return maxParticipants - 1
    }

    func addOrShowError(participants: [UserType]) {
        guard let session = ZMUserSession.shared(),
                session.networkState != .offline else {
            self.showAlertForAdding(for: NetworkError.offline)
            return
        }

        addParticipants(participants, userSession: ZMUserSession.shared()!) { result in
            switch result {
            case .failure(let error):
                self.showAlertForAdding(for: error)
            default: break
            }
        }
    }

    func removeOrShowError(participant user: UserType, completion: ((VoidResult)->())? = nil) {
        guard let session = ZMUserSession.shared(),
            session.networkState != .offline else {
            self.showAlertForRemoval(for: NetworkError.offline)
            return
        }

        /// if the user is not in this conversation, result = .success
        self.removeParticipant(user, userSession: ZMUserSession.shared()!) { result in
            switch result {
            case .success:
                if let serviceUser = user as? ServiceUser, user.isServiceUser {
                    Analytics.shared.tagDidRemoveService(serviceUser)
                }
            case .failure(let error):
                self.showAlertForRemoval(for: error)
            }

            completion?(result)
        }
    }

    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "error.conversation.title".localized,
                                                message: message,
                                                alertAction: .ok(style: .cancel))

        UIApplication.shared.topmostViewController(onlyFullScreen: false)?.present(alertController, animated: true)
    }

    private func showAlertForAdding(for error: Error) {
        switch error {
        case ConversationAddParticipantsError.tooManyMembers:
            showErrorAlert(message: "error.conversation.too_many_members".localized)
        case NetworkError.offline:
            showErrorAlert(message: "error.conversation.offline".localized)
        default:
            showErrorAlert(message: "error.conversation.cannot_add".localized)
        }
    }

    private func showAlertForRemoval(for error: Error) {
        switch error {
        case NetworkError.offline:
            showErrorAlert(message: "error.conversation.offline".localized)
        default:
            showErrorAlert(message: "error.conversation.cannot_remove".localized)
        }
    }
}
