//
//  UserConnectionView.swift
//  Wire-iOS
//
//  Created by Mihail Gerasimenko on 11/17/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import Cartography

final public class UserConnectionView: UIView {
    private let nameInfoLabel = UILabel()
    private let userImageView = UserImageView()
    private let incomingConnectionFooter = UIView()
    private let acceptButton = Button(style: .full)
    private let ignoreButton = Button(style: .empty)
    
    private let outgoingConnectionFooter = UIView()
    private let cancelConnectionButton = IconButton.iconButtonDefaultDark()
    private let blockButton = IconButton.iconButtonDefaultDark()
    
    let user: ZMUser
    var onAccept: ((ZMUser)->())? = .none
    var onIgnore: ((ZMUser)->())? = .none
    var onCancelConnection: ((ZMUser)->())? = .none
    var onBlock: ((ZMUser)->())? = .none
    
    init(user: ZMUser) {
        self.user = user
        super.init(frame: .zero)
        
        self.setup()
        self.createConstraints()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.nameInfoLabel.numberOfLines = 0
        self.setupLabel()
        
        self.acceptButton.setTitle("inbox.connection_request.connect_button_title".localized.uppercased(), for: .normal)
        self.acceptButton.addTarget(self, action: #selector(UserConnectionView.onAcceptButton(sender:)), for: .touchUpInside)
        
        self.ignoreButton.setTitle("inbox.connection_request.ignore_button_title".localized.uppercased(), for: .normal)
        self.ignoreButton.addTarget(self, action: #selector(UserConnectionView.onIgnoreButton(sender:)), for: .touchUpInside)
        
        self.cancelConnectionButton.setIcon(.redo, with: .tiny, for: .normal)
        self.cancelConnectionButton.setTitle("profile.cancel_connection_button_title".localized.uppercased(), for: .normal)
        self.cancelConnectionButton.addTarget(self, action: #selector(UserConnectionView.onCancelConnectionButton(sender:)), for: .touchUpInside)

        self.blockButton.setIcon(.block, with: .tiny, for: .normal)
        self.blockButton.addTarget(self, action: #selector(UserConnectionView.onBlockButton(sender:)), for: .touchUpInside)

        self.userImageView.shouldDesaturate = false
        self.userImageView.suggestedImageSize = .big
        self.userImageView.user = self.user
        
        self.incomingConnectionFooter.addSubview(self.acceptButton)
        self.incomingConnectionFooter.addSubview(self.ignoreButton)
        
        self.outgoingConnectionFooter.addSubview(self.cancelConnectionButton)
        self.outgoingConnectionFooter.addSubview(self.blockButton)
        
        if let connection = self.user.connection {
            self.incomingConnectionFooter.isHidden = connection.status != .pending
            self.outgoingConnectionFooter.isHidden = connection.status != .sent
        }
        else {
            self.incomingConnectionFooter.isHidden = true
            self.outgoingConnectionFooter.isHidden = true
        }

        
        [self.nameInfoLabel, self.userImageView, self.incomingConnectionFooter, self.outgoingConnectionFooter].forEach(self.addSubview)
    }
    
    private func setupLabel() {
        
    }
    
    private func createConstraints() {
        constrain(self.incomingConnectionFooter, self.acceptButton, self.ignoreButton) { incomingConnectionFooter, acceptButton, ignoreButton in
            acceptButton.left == incomingConnectionFooter.left + 24
            acceptButton.top == incomingConnectionFooter.top + 12
            acceptButton.bottom == incomingConnectionFooter.bottom - 12
            acceptButton.height == 40
            
            ignoreButton.right == incomingConnectionFooter.right - 24
            ignoreButton.centerY == acceptButton.centerY
            ignoreButton.height == acceptButton.height
        }
        
        constrain(self.outgoingConnectionFooter, self.cancelConnectionButton, self.blockButton) { outgoingConnectionFooter, cancelConnectionButton, blockButton in
            cancelConnectionButton.left == outgoingConnectionFooter.left + 24
            cancelConnectionButton.top == outgoingConnectionFooter.top + 12
            cancelConnectionButton.bottom == outgoingConnectionFooter.bottom - 12
            
            blockButton.centerY == cancelConnectionButton.centerY
            blockButton.right == outgoingConnectionFooter.right - 24
        }
        
        constrain(self, self.nameInfoLabel, self.incomingConnectionFooter, self.outgoingConnectionFooter, self.userImageView) { selfView, nameInfoLabel, incomingConnectionFooter, outgoingConnectionFooter, userImageView in
            nameInfoLabel.centerX == selfView.centerX
            nameInfoLabel.top == selfView.top + 12
            nameInfoLabel.left >= selfView.left
            nameInfoLabel.bottom <= userImageView.top
            
            userImageView.center == selfView.center
            userImageView.left == selfView.left + 54
            
            outgoingConnectionFooter.top >= userImageView.bottom
            outgoingConnectionFooter.left == selfView.left
            outgoingConnectionFooter.bottom == selfView.bottom
            outgoingConnectionFooter.right == selfView.right
            
            incomingConnectionFooter.top >= userImageView.bottom
            incomingConnectionFooter.left == selfView.left
            incomingConnectionFooter.bottom == selfView.bottom
            incomingConnectionFooter.right == selfView.right
        }
    }
    
    // MARK: - Actions
    
    @objc func onAcceptButton(sender: AnyObject!) {
        self.onAccept?(self.user)
    }
    
    @objc func onIgnoreButton(sender: AnyObject!) {
        self.onIgnore?(self.user)
    }
    
    @objc func onCancelConnectionButton(sender: AnyObject!) {
        self.onCancelConnection?(self.user)
    }
    
    @objc func onBlockButton(sender: AnyObject!) {
        self.onBlock?(self.user)
    }
}
