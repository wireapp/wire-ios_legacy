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


import Foundation

extension ZMConversation {
    private enum NetworkError: Error {
        case offline
    }
    
    @objc static let maxVideoCallParticipants: Int = 4
    
    @objc static let maxParticipants: Int = 300
    
    @objc static var maxParticipantsExcludingSelf: Int {
        return maxParticipants - 1
    }
    
    @objc static var maxVideoCallParticipantsExcludingSelf: Int {
        return maxVideoCallParticipants - 1
    }
    
    @objc var freeParticipantSlots: Int {
        return type(of: self).maxParticipants - activeParticipants.count
    }
    
    @objc(addParticipantsOrShowError:)
    func addOrShowError(participants: Set<ZMUser>) {
        guard let session = ZMUserSession.shared(),
                session.networkState != .offline else {
            self.showAlertForAdding(for: NetworkError.offline)
            return
        }
        
        self.addParticipants(participants,
                             userSession: ZMUserSession.shared()!) { result in
                                switch result {
                                case .failure(let error):
                                    self.showAlertForAdding(for: error)
                                default: break
                                }
        }
    }
    
    @objc (removeParticipantOrShowError:)
    func removeOrShowError(participnant user: ZMUser) {
        removeOrShowError(participnant: user, completion: nil)
    }
    
    func removeOrShowError(participnant user: ZMUser, completion: ((VoidResult)->())? = nil) {
        guard let session = ZMUserSession.shared(),
            session.networkState != .offline else {
            self.showAlertForRemoval(for: NetworkError.offline)
            return
        }
        
        self.removeParticipant(user,
                               userSession: ZMUserSession.shared()!) { result in
                                switch result {
                                case .success:
                                    if user.isServiceUser {
                                        Analytics.shared().tagDidRemoveService(user)
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
                                                cancelButtonTitle: "general.ok".localized)
        
        UIApplication.shared.wr_topmostController(onlyFullScreen: false)?.present(alertController, animated: true)
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
