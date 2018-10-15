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

class NewImageMessageCell: UIView, ConfigurableCell {
    
    typealias Content = ZMConversationMessage
    typealias Description = CommonCellDescription
    
    var senderView: SenderView?
    var burstTimestampView: ConversationCellBurstTimestampView?
    var imageView = ImageResourceView()
    var imageAspectConstraint: NSLayoutConstraint?
    var imageWidthConstraint: NSLayoutConstraint?
    var imageHeightConstraint: NSLayoutConstraint?
    
    required init(from description: CommonCellDescription) {
        super.init(frame: .zero)
        
        var layout: [(UIView, UIEdgeInsets)] = []
        
        if description.contains(.showBurstTimestamp) {
            let burstTimestampView = ConversationCellBurstTimestampView()
            layout.append((burstTimestampView, UIEdgeInsets.zero))
            self.burstTimestampView = burstTimestampView
        }
        
        if description.contains(.showSender) {
            let senderView = SenderView()
            layout.append((senderView, UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)))
            self.senderView = senderView
        }
        
        imageView.contentMode = .scaleAspectFit
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 0)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)
        imageWidthConstraint?.priority = .defaultLow
        imageHeightConstraint?.priority = .defaultLow
        
        NSLayoutConstraint.activate([imageWidthConstraint!, imageHeightConstraint!])
        
        layout.append((FlexibleContainer(imageView, flexibleInsets: FlexibleContainer.FlexibleInsets(top: false, left: false, right: true, bottom: false)), UIView.conversationLayoutMargins))
        
        layout.forEach({ (view, _) in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        })
        
        createConstraints(layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with content: ZMConversationMessage) {
        guard let imageMessageData = content.imageMessageData else { return }
        
        if let sender = content.sender {
            senderView?.configure(with: sender)
        }
        
        burstTimestampView?.label.text = Message.formattedReceivedDate(for: content).uppercased()
        burstTimestampView?.isSeparatorExpanded = true
        
        imageAspectConstraint.apply({ imageView.removeConstraint($0) })
        imageAspectConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: imageMessageData.originalSize.height / imageMessageData.originalSize.width)
        imageAspectConstraint?.isActive = true
        imageWidthConstraint?.constant = imageMessageData.originalSize.width
        imageHeightConstraint?.constant = imageMessageData.originalSize.height
        imageView.setImageResource(imageMessageData.image)
    }
}
