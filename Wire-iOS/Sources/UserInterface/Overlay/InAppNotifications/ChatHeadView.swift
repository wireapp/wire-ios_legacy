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
import WireSyncEngine
import Cartography
import PureLayout

class ChatHeadView: UIView {
    
    private let title: String?
    private let body: String
    private let userID: UUID
    private let sender: ZMUser?
    private let userInfo: NotificationUserInfo?
    private let isEphemeral: Bool
    
    private var userImageView: ContrastUserImageView?
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel!
    private var labelContainer: UIView!

    private let imageDiameter: CGFloat = 28
    private let padding: CGFloat = 10
    
    private let titleRegularAttributes: [NSAttributedString.Key: AnyObject] = [
        .font: FontSpec(.medium, .none).font!.withSize(14),
        .foregroundColor: UIColor(scheme: .chatHeadTitleText)
    ]
    private let titleMediumAttributes: [NSAttributedString.Key: AnyObject] = [
        .font: FontSpec(.medium, .medium).font!.withSize(14),
        .foregroundColor: UIColor(scheme: .chatHeadTitleText)
    ]
    
    private lazy var bodyFont: UIFont = {
        let font = FontSpec(.medium, .regular).font!
        if self.isEphemeral { return UIFont(name: "RedactedScript-Regular", size: font.pointSize)! }
        else { return font }
    }()
    
    public var onSelect: (() -> Void)?
    
    override var intrinsicContentSize: CGSize {
        let height = imageDiameter + 2 * padding
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    init(title: String?, body: String, userID: UUID, sender: ZMUser?, userInfo: NotificationUserInfo? = nil, isEphemeral: Bool = false) {
        self.title = title
        self.body = body
        self.userID = userID
        self.sender = sender
        self.userInfo = userInfo
        self.isEphemeral = isEphemeral
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = UIColor(scheme: .chatHeadBackground)
        layer.cornerRadius = 6
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(scheme: .chatHeadBorder).cgColor
        
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
            let label = UILabel()
            label.backgroundColor = .clear
            label.isUserInteractionEnabled = false
            label.attributedText = attributedTitleText(title)
            label.textColor = UIColor(scheme: .chatHeadTitleText)
            label.lineBreakMode = .byTruncatingTail
            titleLabel = label
            labelContainer.addSubview(label)
        }
        
        subtitleLabel = UILabel()
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.isUserInteractionEnabled = false
        
        let bodyAttributes = (!isEphemeral && titleLabel == nil) ? titleMediumAttributes : [
            .font: bodyFont,
            .foregroundColor: UIColor(scheme: .chatHeadSubtitleText)
        ]
        
        subtitleLabel.attributedText = NSAttributedString(string: body, attributes: bodyAttributes)
        subtitleLabel.lineBreakMode = .byTruncatingTail
        labelContainer.addSubview(subtitleLabel)
    }
    
    private func createImageView() {
        if let sender = sender {
            let imageView = ContrastUserImageView()
            imageView.initials.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.light)
            imageView.userSession = SessionManager.shared?.backgroundUserSessions[userID]
            imageView.isUserInteractionEnabled = false
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.user = sender
            imageView.accessibilityIdentifier = "ChatheadAvatarImage"
            addSubview(imageView)
            userImageView = imageView
        }
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
            // subtitle fills container
            constrain(labelContainer, subtitleLabel) { container, subtitleLabel in
                subtitleLabel.edges == container.edges
            }
        }
        
        if let userImageView = userImageView {
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
        else {
            // labels fills view
            constrain(self, labelContainer) { selfView, labelContainer in
                labelContainer.edges == inset(selfView.edges, 0, padding, 0, padding)
            }
        }
    }
    
    private func attributedTitleText(_ title: String) -> NSAttributedString {
        let attrText = NSMutableAttributedString(string: title, attributes: titleRegularAttributes)
        var ranges = [NSRange]()
        
        // title contains at conversation name and/or team name, and these
        // components should be rendered in medium font
        if let conversationName = userInfo?.conversationName {
            ranges.append((title as NSString).range(of: conversationName))
        }
        
        if let teamName = userInfo?.teamName {
            ranges.append((title as NSString).range(of: teamName))
        }
        
        ranges.forEach {
            if $0.location != NSNotFound { attrText.setAttributes(titleMediumAttributes, range: $0) }
        }
        
        return attrText
    }
    
    // MARK: - Actions
    
    @objc private func didTapInAppNotification(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .recognized {
            onSelect?()
        }
    }
}
