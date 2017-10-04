//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import UIKit
import Cartography
import PureLayout

class ChatHeadView: UIView {

    private var userImageView: ContrastUserImageView!
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel!
    private var labelContainer: UIView!
    
    private let title: NSAttributedString?
    private let content: NSAttributedString
    private let sender: ZMUser
    private let conversation: ZMConversation
    private let account: Account
    
    private let imageDiameter: CGFloat = 28
    private let padding: CGFloat = 10
    
    public var onSelect: ((ZMConversation, Account) -> Void)?
    
    override var intrinsicContentSize: CGSize {
        let height = imageDiameter + 2 * padding
        return CGSize(width: UIViewNoIntrinsicMetric, height: height)
    }
    
    private func color(withName name: String) -> UIColor {
        return ColorScheme.default().color(withName: name)
    }
    
    init(title: NSAttributedString?, content: NSAttributedString, sender: ZMUser, conversation: ZMConversation, account: Account) {
        self.title = title
        self.content = content
        self.sender = sender
        self.conversation = conversation
        self.account = account
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = color(withName: ColorSchemeColorChatHeadBackground)
        layer.cornerRadius = 6
        layer.borderWidth = 0.5
        layer.borderColor = color(withName: ColorSchemeColorChatHeadBorder).cgColor
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 8.0
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.masksToBounds = false
        
        createLabels()
        createImageView()
        createConstraints()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapInAppNotification(_:)))
        addGestureRecognizer(tap)
    }
    
    private func createLabels() {
        
        labelContainer = UIView()
        addSubview(labelContainer)
        
        if let title = title {
            titleLabel = UILabel()
            titleLabel!.backgroundColor = .clear
            titleLabel!.isUserInteractionEnabled = false
            titleLabel!.attributedText = title
            titleLabel!.textColor = color(withName: ColorSchemeColorChatHeadTitleText)
            titleLabel!.lineBreakMode = .byTruncatingTail
            labelContainer.addSubview(titleLabel!)
        }
        
        subtitleLabel = UILabel()
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.isUserInteractionEnabled = false
        subtitleLabel.attributedText = content
        subtitleLabel.textColor = color(withName: ColorSchemeColorChatHeadSubtitleText)
        subtitleLabel.lineBreakMode = .byTruncatingTail
        labelContainer.addSubview(subtitleLabel)
    }
    
    private func createImageView() {
        userImageView = ContrastUserImageView(magicPrefix: "notifications")
        userImageView.userSession = ZMUserSession.shared()
        userImageView.isUserInteractionEnabled = false
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.user = self.sender
        userImageView.accessibilityIdentifier = "ChatheadAvatarImage"
        addSubview(userImageView)
    }
    
    private func createConstraints() {
        
        if let titleLabel = titleLabel {
            // title above subtitle
            constrain(labelContainer, titleLabel, subtitleLabel) { container, titleLabel, subtitleLabel in
                titleLabel.leading == container.leading
                titleLabel.trailing == container.trailing
                titleLabel.bottom == container.centerY
                
                subtitleLabel.leading == container.leading
                subtitleLabel.top == container.centerY
                subtitleLabel.trailing == container.trailing
            }
        } else {
            // subtitle centered
            constrain(labelContainer, subtitleLabel) { container, subtitleLabel in
                subtitleLabel.leading == container.leading
                subtitleLabel.trailing == container.trailing
                subtitleLabel.centerY == container.centerY
            }
        }
        
        // image view left, labels right
        constrain(self, userImageView, labelContainer) { selfView, imageView, labelContainer in
            imageView.height == imageDiameter
            imageView.width == imageView.height
            imageView.leading == selfView.leading + padding
            imageView.centerY == selfView.centerY
            
            labelContainer.leading == imageView.trailing + padding
            labelContainer.trailing == selfView.trailing - padding
            labelContainer.height == selfView.height
            labelContainer.centerY == selfView.centerY
        }
    }
    
    
    // MARK: - Actions
    
    @objc private func didTapInAppNotification(_ gestureRecognizer: UITapGestureRecognizer) {
        if let onSelect = onSelect, gestureRecognizer.state == .recognized {
            onSelect(conversation, account)
        }
    }
}
