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

protocol CollectionCellDelegate: class {
    func collectionCell(_ cell: CollectionCell, performAction: MessageAction)
}

protocol CollectionCellMessageChangeDelegate: class {
    func messageDidChange(_ cell: CollectionCell, changeInfo: MessageChangeInfo)
}

open class CollectionCell: UICollectionViewCell, Reusable {
    var messageObserverToken: NSObjectProtocol? = .none
    weak var delegate: CollectionCellDelegate?
    // Cell forwards the message changes to the delegate
    weak var messageChangeDelegate: CollectionCellMessageChangeDelegate?
    
    var message: ZMConversationMessage? = .none {
        didSet {
            self.messageObserverToken = nil
            if let newMessage = message {
                self.messageObserverToken = MessageChangeInfo.add(observer: self, for: newMessage)
            }
            self.updateForMessage(changeInfo: .none)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadContents()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadContents()
    }
    
    public var desiredWidth: CGFloat? = .none
    public var desiredHeight: CGFloat? = .none
    
    override open var intrinsicContentSize: CGSize {
        get {
            let width = self.desiredWidth ?? UIViewNoIntrinsicMetric
            let height = self.desiredHeight ?? UIViewNoIntrinsicMetric
            
            return CGSize(width: width, height: height)
        }
    }
    
    private var cachedSize: CGSize? = .none
    
    public func flushCachedSize() {
        cachedSize = .none
    }
    
    override open func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if let cachedSize = self.cachedSize {
            var newFrame = layoutAttributes.frame
            newFrame.size.width = cachedSize.width
            newFrame.size.height = cachedSize.height
            layoutAttributes.frame = newFrame
        }
        else {
            setNeedsLayout()
            layoutIfNeeded()
            var desiredSize = layoutAttributes.size
            if let desiredWidth = self.desiredWidth {
                desiredSize.width = desiredWidth
            }
            if let desiredHeight = self.desiredHeight {
                desiredSize.height = desiredHeight
            }
            
            let size = contentView.systemLayoutSizeFitting(desiredSize)
            var newFrame = layoutAttributes.frame
            newFrame.size.width = CGFloat(ceilf(Float(size.width)))
            newFrame.size.height = CGFloat(ceilf(Float(size.height)))
            
            if let desiredWidth = self.desiredWidth {
                newFrame.size.width = desiredWidth
            }
            if let desiredHeight = self.desiredHeight {
                newFrame.size.height = desiredHeight
            }
            
            layoutAttributes.frame = newFrame
            self.cachedSize = newFrame.size
        }
        
        return layoutAttributes
    }
    
    func loadContents() {
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.cornerRadius = 4
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(CollectionCell.onLongPress(_:)))
        
        self.contentView.addGestureRecognizer(longPressGestureRecognizer)
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        self.cachedSize = .none
        self.message = .none
    }
    
    func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer!) {
        if gestureRecognizer.state == .began {
            self.showMenu()
        }
    }
    
    func menuConfigurationProperties() -> MenuConfigurationProperties? {
        let properties = MenuConfigurationProperties()
        properties.targetRect = self.contentView.bounds
        properties.targetView = self.contentView
        if message?.canBeLiked == true {
            properties.additionalItems = [UIMenuItem.like(for: message, with: #selector(like))]
        }

        return properties
    }
    
    func showMenu() {
        guard let menuConfigurationProperties = self.menuConfigurationProperties(), let message = self.message else {
            return
        }
        /**
         *  The reason why we are touching the window here is to workaround a bug where,
         *  After dismissing the webplayer, the window would fail to become the first responder,
         *  preventing us to show the menu at all.
         *  We now force the window to be the key window and to be the first responder to ensure that we can
         *  show the menu controller.
         */
        self.window?.makeKey()
        self.window?.becomeFirstResponder()
        self.becomeFirstResponder()
        
        let menuController = UIMenuController.shared
        menuController.menuItems = menuConfigurationProperties.additionalItems + [.forward(with:  #selector(forward)), .reveal(with: #selector(showInConversation))]
        menuController.setTargetRect(menuConfigurationProperties.targetRect, in: menuConfigurationProperties.targetView)
        menuController.setMenuVisible(true, animated: true)
        
        Analytics.shared()?.tagCollectionOpenItemMenu(for: message.conversation!, itemType: CollectionItemType(message: message))
    }
    
    override open var canBecomeFirstResponder: Bool {
        return true
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(forward), #selector(showInConversation):
            return true
        case #selector(like):
            return message?.canBeLiked == true
        default:
            return false
        }
    }
    
    /// To be implemented in the subclass
    func updateForMessage(changeInfo: MessageChangeInfo?) {
        // no-op
    }

    func like(_ sender: AnyObject!) {
        guard let message = message else { return }
        Message.setLikedMessage(message, liked: !message.liked)
    }

    func forward(_ sender: AnyObject!) {
        self.delegate?.collectionCell(self, performAction: .forward)
        guard let message = self.message else {
            return
        }
        Analytics.shared()?.tagCollectionDidItemAction(for: message.conversation!, itemType: CollectionItemType(message: message), action: .forward)
    }
    
    func showInConversation(_ sender: AnyObject!) {
        self.delegate?.collectionCell(self, performAction: .showInConversation)
        guard let message = self.message else {
            return
        }
        Analytics.shared()?.tagCollectionDidItemAction(for: message.conversation!, itemType: CollectionItemType(message: message), action: .goto)
    }
}

extension CollectionCell: ZMMessageObserver {
    public func messageDidChange(_ changeInfo: MessageChangeInfo) {
        self.updateForMessage(changeInfo: changeInfo)
        self.messageChangeDelegate?.messageDidChange(self, changeInfo: changeInfo)
    }
}
