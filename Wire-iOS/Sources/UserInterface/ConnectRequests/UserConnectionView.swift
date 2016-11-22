//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography

public final class UserConnectionView: UIView, Copyable {
    
    public convenience init(instance: UserConnectionView) {
        self.init(user: instance.user)
        self.onAccept = instance.onAccept
        self.onIgnore = instance.onIgnore
        self.onCancelConnection = instance.onCancelConnection
        self.onBlock = instance.onBlock
        self.showUserName = instance.showUserName
    }
    
    public typealias User = ZMBareUser & ZMBareUserConnection & ZMSearchableUser
    private let nameInfoLabel = UILabel()
    private let userImageView = UserImageView()
    private let incomingConnectionFooter = UIView()
    private let acceptButton = Button(style: .full)
    private let ignoreButton = Button(style: .empty)
    
    private let outgoingConnectionFooter = UIView()
    private let cancelConnectionButton = IconButton.iconButtonCircular()
    private let blockButton = IconButton.iconButtonDefaultDark()
    
    public var user: User {
        didSet {
            self.updateForUser()
            self.userImageView.user = self.user
        }
    }
    public var commonConnectionsCount: UInt = 0 {
        didSet {
            self.setupLabelText()
        }
    }
    public var onAccept: ((User)->())? = .none
    public var onIgnore: ((User)->())? = .none
    public var onCancelConnection: ((User)->())? = .none
    public var onBlock: ((User)->())? = .none
    public var showUserName: Bool = false {
        didSet {
            self.setupLabelText()
        }
    }

    public init(user: User) {
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
        self.nameInfoLabel.textAlignment = .center
        
        self.acceptButton.accessibilityLabel = "accept"
        self.acceptButton.setTitle("inbox.connection_request.connect_button_title".localized.uppercased(), for: .normal)
        self.acceptButton.addTarget(self, action: #selector(UserConnectionView.onAcceptButton(sender:)), for: .touchUpInside)
        
        self.ignoreButton.accessibilityLabel = "ignore"
        self.ignoreButton.setTitle("inbox.connection_request.ignore_button_title".localized.uppercased(), for: .normal)
        self.ignoreButton.addTarget(self, action: #selector(UserConnectionView.onIgnoreButton(sender:)), for: .touchUpInside)
        
        self.cancelConnectionButton.accessibilityLabel = "cancel connection"
        self.cancelConnectionButton.setIcon(.redo, with: .tiny, for: .normal)
        self.cancelConnectionButton.setTitle("profile.cancel_connection_button_title".localized.uppercased(), for: .normal)
        self.cancelConnectionButton.titleLabel?.font = UIFont(magicIdentifier: "style.text.small.font_spec_light")
        self.cancelConnectionButton.setTitleColor(ColorScheme.default().color(withName: ColorSchemeColorTextForeground), for: .normal)
        self.cancelConnectionButton.setTitleImageSpacing(12, horizontalMargin: 0)
        self.cancelConnectionButton.addTarget(self, action: #selector(UserConnectionView.onCancelConnectionButton(sender:)), for: .touchUpInside)

        self.blockButton.accessibilityLabel = "block user"
        self.blockButton.setIcon(.block, with: .tiny, for: .normal)
        self.blockButton.addTarget(self, action: #selector(UserConnectionView.onBlockButton(sender:)), for: .touchUpInside)

        self.userImageView.accessibilityLabel = "user image"
        self.userImageView.shouldDesaturate = false
        self.userImageView.suggestedImageSize = .big
        self.userImageView.user = self.user
        
        self.incomingConnectionFooter.addSubview(self.acceptButton)
        self.incomingConnectionFooter.addSubview(self.ignoreButton)
        
        self.outgoingConnectionFooter.addSubview(self.cancelConnectionButton)
        self.outgoingConnectionFooter.addSubview(self.blockButton)
        
        [self.nameInfoLabel, self.userImageView, self.incomingConnectionFooter, self.outgoingConnectionFooter].forEach(self.addSubview)
        
        self.updateForUser()
    }
    
    private func updateForUser() {
        self.setupLabelText()
        
        self.incomingConnectionFooter.isHidden = self.user.isConnected || self.user.isPendingApprovalByOtherUser
        self.outgoingConnectionFooter.isHidden = !self.user.isPendingApprovalByOtherUser
    }
    
    private func setupLabelText() {

        var name: NSAttributedString = NSAttributedString()
        
        if self.showUserName {
            let nameStyle = [NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground),
                             NSFontAttributeName: UIFont(magicIdentifier: "style.text.normal.font_spec_bold")] as [String : AnyObject]
            
            name = (self.user.name + "\n\n") && nameStyle
        }
        
        let labelStyle = [NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextDimmed),
                          NSFontAttributeName: UIFont(magicIdentifier: "style.text.small.font_spec_light")] as [String : AnyObject]
        
        let labelStyleBold = [NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextDimmed),
                              NSFontAttributeName: UIFont(magicIdentifier: "style.text.small.font_spec_bold")] as [String : AnyObject]
        
        var inAddressBook = false
        var addressBookNameMatchFullName = false
        
        if let zmUser = self.user as? ZMUser,
            let contact = zmUser.contact() {
            inAddressBook = true
            addressBookNameMatchFullName = contact.name.lowercased() == self.user.name
        }
        
        let hasCommonConnections = self.commonConnectionsCount > 0
        
        var remoteIdentifier: UUID?
        
        if let zmUser = self.user as? ZMUser {
            remoteIdentifier = zmUser.remoteIdentifier
        }
        
        let username = ZMUser.autoUsername(forName: self.user.name, remoteIdentifier: remoteIdentifier) && labelStyle
        
        var secondLine: NSAttributedString? = .none
        
        if inAddressBook {
            if addressBookNameMatchFullName {
                secondLine = "conversation.connection_view.in_address_book".localized && labelStyle
            }
            else {
                secondLine = (self.user.name && labelStyleBold) + " " + ("conversation.connection_view.in_address_book".localized && labelStyle)
            }
        }
        else if hasCommonConnections {
            secondLine = (String(format: "%ld", self.commonConnectionsCount) && labelStyleBold) + " " + ("conversation.connection_view.common_connections".localized && labelStyle)
        }
        
        self.nameInfoLabel.attributedText = name + username + (secondLine != .none ? "\n" + secondLine! : "" && labelStyle)
    }
    
    private func createConstraints() {
        constrain(self.incomingConnectionFooter, self.acceptButton, self.ignoreButton) { incomingConnectionFooter, acceptButton, ignoreButton in
            acceptButton.left == incomingConnectionFooter.left + 24
            acceptButton.top == incomingConnectionFooter.top + 12
            acceptButton.bottom == incomingConnectionFooter.bottom - 24
            acceptButton.height == 40
            acceptButton.width >= 140
            
            ignoreButton.right == incomingConnectionFooter.right - 24
            ignoreButton.centerY == acceptButton.centerY
            ignoreButton.height == acceptButton.height
            ignoreButton.width >= 140
        }
        
        constrain(self.outgoingConnectionFooter, self.cancelConnectionButton, self.blockButton) { outgoingConnectionFooter, cancelConnectionButton, blockButton in
            cancelConnectionButton.left == outgoingConnectionFooter.left + 24
            cancelConnectionButton.top == outgoingConnectionFooter.top + 12
            cancelConnectionButton.bottom == outgoingConnectionFooter.bottom - 24
            
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
            userImageView.width == userImageView.height
            
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
