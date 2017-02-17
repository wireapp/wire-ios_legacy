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
import Classy

// Cell that disaplys the file transfer and it's states
public final class FileTransferCell: ConversationCell {
    private let fileTransferView = FileTransferView(frame: .zero)
    private let containerView = UIView()
    private let obfuscationView = ObfuscationView(icon: .paperclip)

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.layer.cornerRadius = 4
        self.containerView.cas_styleClass = "container-view"
        self.containerView.clipsToBounds = true
        
        self.fileTransferView.delegate = self
        self.fileTransferView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(self.fileTransferView)
        self.obfuscationView.isHidden = true
        self.containerView.addSubview(self.obfuscationView)
        
        self.messageContentView.addSubview(self.containerView)
        
        self.createConstraints()
        
        var currentElements: [Any] = self.accessibilityElements ?? []
        let contentViewAccessibilityElements: [Any] = self.fileTransferView.accessibilityElements ?? []
        currentElements.append(contentsOf: contentViewAccessibilityElements)
        currentElements.append(contentsOf: [likeButton, toolboxView])
        self.accessibilityElements = currentElements
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints() {
        constrain(messageContentView, self.containerView, fileTransferView, self.authorLabel) { messageContentView, containerView, fileTransferView, authorLabel in
            containerView.left == authorLabel.left
            containerView.right == messageContentView.rightMargin
            containerView.top == messageContentView.top
            containerView.bottom == messageContentView.bottom ~ 100
            containerView.height == 56
            
            fileTransferView.edges == containerView.edges
        }
        
        constrain(fileTransferView, countdownContainerView, obfuscationView) { fileTransferView, countDownContainer, obfuscationView in
            countDownContainer.top == fileTransferView.top
            obfuscationView.edges == fileTransferView.edges
        }
    }
    
    open override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.update(forMessage: changeInfo)
        self.configureForFileTransferMessage(self.message, initialConfiguration: false)

        return needsLayout
    }
    
    override open func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        
        if Message.isFileTransferMessage(message) {
            self.configureForFileTransferMessage(message, initialConfiguration: true)
        }
    }
    
    fileprivate func configureForFileTransferMessage(_ message: ZMConversationMessage, initialConfiguration: Bool) {
        self.fileTransferView.configure(for: message, isInitial: initialConfiguration)
        self.obfuscationView.isHidden = !message.isObfuscated
    }

    public func actionButton() -> UIButton? {
        return self.fileTransferView.actionButton
    }
    
    override open var tintColor: UIColor! {
        didSet {
            self.fileTransferView.tintColor = self.tintColor
        }
    }
    
    // MARK: - Selection
    
    open override var selectionView: UIView! {
        return fileTransferView
    }
    
    open override var selectionRect: CGRect {
        return fileTransferView.bounds
    }
    
    // MARK: - Delete
    
    override open func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = { [weak self] selected, animated in
            UIView.animate(withDuration: animated ? ConversationCellSelectionAnimationDuration : 0) {
                self?.messageContentView.alpha = selected ? ConversationCellSelectedOpacity : 1.0
            }
        }
        
        var additionalItems = [UIMenuItem]()
        
        if let fileMessageData = message.fileMessageData,
            let _ = fileMessageData.fileURL {
            let openItem = UIMenuItem(title:"content.message.open".localized, action:#selector(open))
            let saveItem = UIMenuItem(title:"content.message.save".localized, action:#selector(save))
            let forwardItem = UIMenuItem(title:"content.message.forward".localized, action:#selector(forward))
            additionalItems.append(contentsOf: [openItem, saveItem, forwardItem])
        }
        
        properties.additionalItems = additionalItems
        
        return properties
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(forward), #selector(save):
            if let fileMessageData = message.fileMessageData,
                let _ = fileMessageData.fileURL {
                return true
            }
        case #selector(open):
            return true
        default: break
        }

        return super.canPerformAction(action, withSender: sender)
    }

    func open(_ sender: Any) {
        showsMenu = false
        delegate?.conversationCell?(self, didSelect: .present)
    }

    func save(_ sender: Any) {
        delegate?.conversationCell?(self, didSelect: .save)
    }
    
    override open func messageType() -> MessageType {
        return .file
    }
}

extension FileTransferCell: TransferViewDelegate {
    public func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate.conversationCell?(self, didSelect: action)
    }
}
