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
import CocoaLumberjackSwift
import Classy

/// Displays the audio message with different states
public final class AudioMessageCell: ConversationCell {
    private let audioMessageView = AudioMessageView()
    private let containerView = UIView()
    private let obfuscationView = ObfuscationView(icon: .microphone)

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.layer.cornerRadius = 4
        self.containerView.cas_styleClass = "container-view"
        self.containerView.clipsToBounds = true
        
        self.audioMessageView.delegate = self
        self.obfuscationView.isHidden = true
        
        self.containerView.addSubview(self.audioMessageView)
        self.containerView.addSubview(self.obfuscationView)
        self.messageContentView.addSubview(self.containerView)
        self.createConstraints()
        
        var currentElements: [Any] = self.accessibilityElements ?? []
        let contentViewAccessibilityElements: [Any] = self.audioMessageView.accessibilityElements ?? []
        currentElements.append(contentsOf: contentViewAccessibilityElements)
        currentElements.append(contentsOf: [likeButton, toolboxView])
        self.accessibilityElements = currentElements
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var audioTrackPlayer : AudioTrackPlayer? {
        set { self.audioMessageView.audioTrackPlayer = newValue}
        get { return self.audioMessageView.audioTrackPlayer }
    }
    
    open func createConstraints() {
        constrain(self.messageContentView, self.containerView, self.audioMessageView, self.authorLabel) { (messageContentView: LayoutProxy, containerView: LayoutProxy, audioMessageView: LayoutProxy, authorLabel: LayoutProxy) -> () in
            
            containerView.left == messageContentView.leftMargin
            containerView.right == messageContentView.rightMargin
            containerView.top == messageContentView.top
            containerView.bottom == messageContentView.bottom
            containerView.height == 56
            
            audioMessageView.edges == containerView.edges
        }

        constrain(audioMessageView, obfuscationView) { audioMessageView, obfuscationView in
            obfuscationView.edges == audioMessageView.edges
        }
        
        constrain(audioMessageView, countdownContainerView) { container, countDownContainer in
            countDownContainer.top == container.top
        }
    }
    
    override public func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {

        super.configure(for: message, layoutProperties: layoutProperties)
        
        self.configureMessageView(with: message, isInitial: true)
    }
    
    override public func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.update(forMessage: changeInfo)
        
        if changeInfo.isObfuscatedChanged {
            self.audioMessageView.stopPlaying()
        }
        
        self.configureMessageView(with: message, isInitial: false)
        
        return needsLayout
    }
    
    private func configureMessageView(with message: ZMConversationMessage, isInitial: Bool) {
        self.audioMessageView.configure(for: message, isInitial: isInitial)
        self.obfuscationView.isHidden = !message.isObfuscated
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.audioMessageView.stopProximitySensor()
    }
    
    override open var tintColor: UIColor! {
        didSet {
            self.audioMessageView.tintColor = self.tintColor
        }
    }
    // MARK: - Menu

    open func setSelectedByMenu(_ selected: Bool, animated: Bool) {
        
        let animation = {
            self.messageContentView.alpha = selected ? ConversationCellSelectedOpacity : 1.0;
        }
        
        if (animated) {
            UIView.animate(withDuration: ConversationCellSelectionAnimationDuration, animations: animation)
        } else {
            animation()
        }
    }
    
    open override var selectionRect: CGRect {
        return audioMessageView.bounds
    }
    
    open override var selectionView: UIView! {
        return audioMessageView
    }
    
    override open func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = setSelectedByMenu
        
        var additionalItems = [UIMenuItem]()
        
        if message.audioCanBeSaved() {
            let menuItem = UIMenuItem(title: "content.file.save_audio".localized, action:#selector(wr_saveAudio))
            additionalItems.append(menuItem)
        }
        
        if let fileMessageData = message.fileMessageData,
            let _ = fileMessageData.fileURL {
            additionalItems.append(.forward(with: #selector(forward)))
        }
        
        properties.additionalItems = additionalItems
        
        return properties
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(wr_saveAudio) && self.message.audioCanBeSaved() {
            return true
        }
        else if action == #selector(forward(_:)) {
            if let fileMessageData = message.fileMessageData,
            let _ = fileMessageData.fileURL {
                return true
            }
            else {
                return false
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    open func wr_saveAudio() {
        if self.message.audioCanBeSaved() {
            self.delegate?.conversationCell?(self, didSelect: .save)
        }
    }
    
}

extension AudioMessageCell: TransferViewDelegate {
    public func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate.conversationCell?(self, didSelect: action)
    }
}
