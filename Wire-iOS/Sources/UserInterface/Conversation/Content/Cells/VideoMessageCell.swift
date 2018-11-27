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

private let zmLog = ZMSLog(tag: "UI")

/// Displays the video message@objc  with different states
public final class VideoMessageCell: ConversationCell {
    
    private let videoMessageView = VideoMessageView()
    private let obfuscationView = ObfuscationView(icon: .videoMessage)

    public var videoViewHeight : CGFloat = PreviewHeightCalculator.videoViewHeight

    private var topMargin: NSLayoutConstraint!
        
    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.videoMessageView)
        self.videoMessageView.delegate = self
        
        self.contentView.addSubview(self.obfuscationView)
        
        self.createConstraints()
        videoMessageView.clipsToBounds = true
        
        var currentElements: [Any] = self.accessibilityElements ?? []
        let contentViewAccessibilityElements: [Any] = self.videoMessageView.accessibilityElements ?? []
        currentElements.append(contentsOf: contentViewAccessibilityElements)
        currentElements.append(toolboxView)
        self.accessibilityElements = currentElements

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createConstraints() {
        constrain(self.messageContentView, self.videoMessageView, self.obfuscationView) { messageContentView, videoMessageView, obfuscationView in
            topMargin = videoMessageView.top == messageContentView.top
            videoMessageView.bottom == messageContentView.bottom
            videoMessageView.leading == messageContentView.leadingMargin
            videoMessageView.trailing == messageContentView.trailingMargin
            videoMessageView.height == videoViewHeight
            obfuscationView.edges == videoMessageView.edges
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        videoMessageView.layer.cornerRadius = 4
    }
    
    public override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.update(forMessage: changeInfo)
        self.obfuscationView.isHidden = !message.isObfuscated

        if let fileMessageData = self.message.fileMessageData {
            self.configureForVideoMessage(fileMessageData, isInitial: false)
        }

        return needsLayout
    }
    
    override public func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        self.obfuscationView.isHidden = !message.isObfuscated

        if message.isVideo, let fileMessageData = message.fileMessageData {
            self.configureForVideoMessage(fileMessageData, isInitial: true)
        }
        else {
            fatalError("Wrong message type: \(type(of: message)): \(String(describing: message))")
        }
    }
    
    private func configureForVideoMessage(_ fileMessageData: ZMFileMessageData, isInitial: Bool) {
        self.videoMessageView.configure(for: message, isInitial: isInitial)
        
        topMargin?.constant = layoutProperties.showSender ? 12 : 0
    }
    
    override public var tintColor: UIColor! {
        didSet {
            self.videoMessageView.tintColor = self.tintColor
        }
    }
    
    // MARK: - Selection
    
    public override var selectionView: UIView! {
        return videoMessageView
    }
    
    public override var selectionRect: CGRect {
        return videoMessageView.bounds
    }
    
    // MARK: - Menu

    public override func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        return properties
    }
            
    @objc override func prepareLayoutForPreview(message: ZMConversationMessage?) -> CGFloat {
        super.prepareLayoutForPreview(message: message)
        return PreviewHeightCalculator.heightForVideo()
    }
    
    @objc func download(_ sender: Any) {
        delegate?.conversationCell?(self, didSelect: .download, for: self.message)
    }
}


extension VideoMessageCell: TransferViewDelegate {
    public func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate.conversationCell?(self, didSelect: action, for: self.message)
    }
}
