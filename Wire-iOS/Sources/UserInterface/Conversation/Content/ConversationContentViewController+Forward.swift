//
//  ConversationContentViewController+Forward.swift
//  Wire-iOS
//
//  Created by Mihail Gerasimenko on 11/8/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import zmessaging


extension UITableViewCell: UITableViewDelegate, UITableViewDataSource {
    func wrapInTableView() -> UITableView {
        let tableView = UITableView(frame: self.bounds, style: .plain)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.layoutMargins = self.layoutMargins
        
        let size = self.systemLayoutSizeFitting(CGSize(width: 320.0, height: 0.0) , withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
        self.layoutSubviews()
        
        self.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        self.contentView.bounds = self.bounds
        
        tableView.reloadData()
        tableView.bounds = self.bounds
        tableView.layoutIfNeeded()
        CASStyler.default().styleItem(self)
        self.layoutSubviews()
        return tableView
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.size.height
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self
    }
}


extension ZMConversation: ShareDestination {
}

extension ZMMessage: Shareable {
    public func share<ZMConversation>(to: [ZMConversation]) {
        if let imageMessageData = self.imageMessageData {
            ZMUserSession.shared().performChanges {
                to.forEach({ conversation in
                    let imageData = imageMessageData.imageData
//                                        conversation.appendMessage(withImageData: imageData)
                })
            }
        }
    }

    public typealias I = ZMConversation

    public func previewView() -> UIView {
        let cell: ConversationCell
        if Message.isTextMessage(self) {
            cell = TextMessageCell(style: .default, reuseIdentifier: "")
        }
        else if Message.isImageMessage(self) {
            cell = ImageMessageCell(style: .default, reuseIdentifier: "")
        }
        else if Message.isVideoMessage(self) {
            cell = VideoMessageCell(style: .default, reuseIdentifier: "")
        }
        else if Message.isAudioMessage(self) {
            cell = AudioMessageCell(style: .default, reuseIdentifier: "")
        }
        else if Message.isLocationMessage(self) {
            cell = LocationMessageCell(style: .default, reuseIdentifier: "")
        }
        else if Message.isFileTransferMessage(self) {
            cell = FileTransferCell(style: .default, reuseIdentifier: "")
        }
        else {
            fatal("Cannot create preview for \(self)")
        }
        
        
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender       = false
        layoutProperties.showUnreadMarker = false
        layoutProperties.showBurstTimestamp = false
        layoutProperties.topPadding       = 0
        layoutProperties.alwaysShowDeliveryState = false
        
        if Message.isTextMessage(self) {
            layoutProperties.linkAttachments = Message.linkAttachments(self.textMessageData!)
        }
        
        cell.configure(for: self, layoutProperties: layoutProperties)
        
        return cell.wrapInTableView()
    }
}

extension ConversationContentViewController {
    @objc public func showForwardFor(message: ZMConversationMessage) {
        let conversations = SessionObjectCache.shared().allConversations.map { $0 as! ZMConversation }
        let shareViewController = ShareViewController(shareable: message as! ZMMessage, destinations: conversations)
        
        if self.parent?.parent?.wr_splitViewController.layoutSize == .compact {
            shareViewController.modalPresentationStyle = .overCurrentContext
        }
        else {
            shareViewController.modalPresentationStyle = .formSheet
        }
       
        shareViewController.onDismiss = { shareController in
            shareController.presentingViewController?.dismiss(animated: true, completion: .none)
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(shareViewController, animated: true, completion: .none)
    }
}
