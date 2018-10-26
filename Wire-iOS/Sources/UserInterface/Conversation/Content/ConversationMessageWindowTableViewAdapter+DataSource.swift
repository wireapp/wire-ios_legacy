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

extension ConversationMessageWindowTableViewAdapter {
    
    @objc func registerTableCellClasses() {
        tableView.register(ConnectionRequestCell.self, forCellReuseIdentifier: ConversationConnectionRequestCellId)
        tableView.register(ConversationNewDeviceCell.self, forCellReuseIdentifier: ConversationNewDeviceCellId)
        tableView.register(MissingMessagesCell.self, forCellReuseIdentifier: ConversationMissingMessagesCellId)
        tableView.register(ConversationIgnoredDeviceCell.self, forCellReuseIdentifier: ConversationIgnoredDeviceCellId)
        tableView.register(CannotDecryptCell.self, forCellReuseIdentifier: ConversationCannotDecryptCellId)

        tableView.register(ParticipantsCell.self, forCellReuseIdentifier: ParticipantsCell.zm_reuseIdentifier)

        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: ConversationImageCellId)
        tableView.register(FileTransferCell.self, forCellReuseIdentifier: ConversationFileTransferCellId)
        tableView.register(VideoMessageCell.self, forCellReuseIdentifier: ConversationVideoMessageCellId)
        tableView.register(AudioMessageCell.self, forCellReuseIdentifier: ConversationAudioMessageCellId)
    }
}

extension ConversationMessageWindowTableViewAdapter: UITableViewDataSource {

    @objc(buildSectionControllerForMessage:)
    func buildSectionController(for message: ZMConversationMessage) -> ConversationMessageSectionController {
        return messageWindow.sectionController(for: message, firstUnreadMessage: firstUnreadMessage)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.messageWindow.messages.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionController = self.sectionController(at: section, in: tableView)!
        return sectionController.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)!
        return sectionController.makeCell(for: tableView, at: indexPath)
    }
}

extension ZMConversationMessage {
    var cellIdentifier: String {
        var cellIdentifier = ConversationUnknownMessageCellId

        if isVideo {
            cellIdentifier = ConversationVideoMessageCellId
        } else if isAudio {
            cellIdentifier = ConversationAudioMessageCellId
        } else if isFile {
            cellIdentifier = ConversationFileTransferCellId
        } else if isImage {
            cellIdentifier = ConversationImageCellId
        } else if isSystem, let systemMessageType = systemMessageData?.systemMessageType {
            switch systemMessageType {
            case .connectionRequest:
                cellIdentifier = ConversationConnectionRequestCellId
            case .connectionUpdate:
                break
            case .newClient, .usingNewDevice:
                cellIdentifier = ConversationNewDeviceCellId
            case .ignoredClient:
                cellIdentifier = ConversationIgnoredDeviceCellId
            case .potentialGap, .reactivatedDevice:
                cellIdentifier = ConversationMissingMessagesCellId
            case .decryptionFailed, .decryptionFailed_RemoteIdentityChanged:
                cellIdentifier = ConversationCannotDecryptCellId
            case .participantsAdded, .participantsRemoved, .newConversation, .teamMemberLeave:
                cellIdentifier = ParticipantsCell.zm_reuseIdentifier
            default:
                break
            }
        } else {
            cellIdentifier = ConversationUnknownMessageCellId
        }
        
        return cellIdentifier
    }
}
