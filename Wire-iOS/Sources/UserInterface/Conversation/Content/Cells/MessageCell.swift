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

typealias ViewLayout = (UIView, UIEdgeInsets)

class MessageCell: UIView {
    
    let contentView: UIView
    var senderView: SenderCellComponent?
    var burstTimestampView: ConversationCellBurstTimestampView?
    let toolboxView: MessageToolboxView = MessageToolboxView()
    let ephemeralCountdownView: DestructionCountdownView = DestructionCountdownView()
    
    var isSelected: Bool = false {
        didSet {
            toolboxView.setHidden(!isSelected, animated: true)
        }
    }
    
    init(from configuration: MessageCellConfiguration, content: UIView, fullWidthContent: UIView? = nil) {
        contentView = content
        
        super.init(frame: .zero)
        
        var layout: [(UIView, UIEdgeInsets)] = []
        
        if configuration.contains(.showBurstTimestamp) {
            let burstTimestampView = ConversationCellBurstTimestampView()
            layout.append((burstTimestampView, UIEdgeInsets.zero))
            self.burstTimestampView = burstTimestampView
        }
        
        if configuration.contains(.showSender) {
            let senderView = SenderCellComponent()
            layout.append((senderView, UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)))
            self.senderView = senderView
        }
        
        layout.append((content, UIView.conversationLayoutMargins))
        
        if let fullWithContent = fullWidthContent {
            layout.append((fullWithContent, .zero))
        }
        
        layout.append((toolboxView, UIView.conversationLayoutMargins))
        
        layout.forEach({ (view, _) in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        })
        
        let ephemeralCountdownContainer = UIView()
        ephemeralCountdownContainer.translatesAutoresizingMaskIntoConstraints = false
        ephemeralCountdownContainer.addSubview(ephemeralCountdownView)
        addSubview(ephemeralCountdownContainer)
        
        ephemeralCountdownView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ephemeralCountdownContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            ephemeralCountdownContainer.trailingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ephemeralCountdownContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4), // TODO jacob
            ephemeralCountdownView.centerXAnchor.constraint(equalTo: ephemeralCountdownContainer.centerXAnchor),
            ephemeralCountdownView.topAnchor.constraint(equalTo: ephemeralCountdownContainer.topAnchor),
            ephemeralCountdownView.bottomAnchor.constraint(equalTo: ephemeralCountdownContainer.bottomAnchor),
            ephemeralCountdownView.widthAnchor.constraint(equalToConstant: 8),
            ephemeralCountdownView.heightAnchor.constraint(equalToConstant: 8)])
        
        createConstraints(layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func configure(with message: ZMConversationMessage) {
        if let sender = message.sender {
            senderView?.configure(with: sender)
        }
                
        burstTimestampView?.label.text = Message.formattedReceivedDate(for: message).uppercased()
        burstTimestampView?.isSeparatorExpanded = true
        toolboxView.configureForMessage(message, forceShowTimestamp: false, animated: false)
        toolboxView.setHidden(!isSelected, animated: false)
        ephemeralCountdownView.isHidden = !message.isEphemeral
    }
    
}
