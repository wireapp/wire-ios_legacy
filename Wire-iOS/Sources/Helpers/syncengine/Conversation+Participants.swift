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

        addParticipants(participants) { (result) in
            switch result {
            case .failure(let error):
                self.showAlertForAdding(for: error)
            default:
                break
            }
        }
    }

    func removeOrShowError(participant user: UserType, completion: ((VoidResult) -> Void)? = nil) {
        guard let session = ZMUserSession.shared(),
            session.networkState != .offline else {
            self.showAlertForRemoval(for: NetworkError.offline)
            return
        }

        removeParticipant(user) { (result) in
            switch result {
            case .success:
                if let serviceUser = user as? ServiceUser, user.isServiceUser {
                    Analytics.shared.tagDidRemoveService(serviceUser)
                }
                completion?(.success)
            case .failure(let error):
                self.showAlertForRemoval(for: error)
                completion?(.failure(error))
            }
        }
    }

    private func showAlertForAdding(for error: Error) {
        typealias ConversationError = L10n.Localizable.Error.Conversation

        switch error {
        case ConversationAddParticipantsError.tooManyMembers:
            UIAlertController.showErrorAlert(title: ConversationError.title, message: ConversationError.tooManyMembers)
        case NetworkError.offline:
            UIAlertController.showErrorAlert(title: ConversationError.title, message: ConversationError.offline)
        case ConversationAddParticipantsError.missingLegalHoldConsent:
            UIAlertController.showErrorAlert(title: ConversationError.title, message: ConversationError.missingLegalholdConsent)
        default:
            UIAlertController.showErrorAlert(title: ConversationError.title, message: ConversationError.cannotAdd)
        }
    }

    private func showAlertForRemoval(for error: Error) {
        typealias ConversationError = L10n.Localizable.Error.Conversation

        switch error {
        case NetworkError.offline:
            UIAlertController.showErrorAlert(title: ConversationError.title, message: ConversationError.offline.localized)
        default:
            UIAlertController.showErrorAlert(title: ConversationError.title, message: ConversationError.cannotRemove.localized)
        }
    }
}
