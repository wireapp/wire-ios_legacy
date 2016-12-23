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

open class CollectionCell: UICollectionViewCell, Reusable {
    var messageObserverToken: ZMMessageObserverOpaqueToken? = .none
    weak var delegate: CollectionCellDelegate?
    var message: ZMConversationMessage? = .none {
        didSet {
            ZMMessageNotification.removeMessageObserver(for: self.messageObserverToken)
            self.messageObserverToken = ZMMessageNotification.add(self, for: self.message)
            self.updateForMessage(changeInfo: .none)
        }
    }
    
    deinit {
        ZMMessageNotification.removeMessageObserver(for: self.messageObserverToken)
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
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(CollectionCell.onLongPress(_:)))
        
        self.contentView.addGestureRecognizer(longPressGestureRecognizer)
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        self.cachedSize = .none
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
        
        let forwardItem = UIMenuItem(title: "content.message.forward".localized, action: #selector(CollectionCell.forward(_:)))
        let goToConversation = UIMenuItem(title: "content.message.go_to_conversation".localized, action: #selector(CollectionCell.showInConversation(_:)))
        properties.additionalItems = [forwardItem, goToConversation]
        return properties
    }
    
    func showMenu() {
        guard let menuConfigurationProperties = self.menuConfigurationProperties() else {
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
        
        menuController.menuItems = menuConfigurationProperties.additionalItems
        
        menuController.setTargetRect(menuConfigurationProperties.targetRect, in: menuConfigurationProperties.targetView)
        menuController.setMenuVisible(true, animated: true)
    }
    
    override open var canBecomeFirstResponder: Bool {
        return true
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(CollectionCell.forward(_:)): fallthrough
        case #selector(CollectionCell.showInConversation(_:)):
            return false // To enable menu return `true` here
        default:
            return false
        }
    }
    
    /// To be implemented in the subclass
    func updateForMessage(changeInfo: MessageChangeInfo?) {
        // no-op
    }
    
    func forward(_ sender: AnyObject!) {
        self.delegate?.collectionCell(self, performAction: .forward)
    }
    
    func showInConversation(_ sender: AnyObject!) {
        self.delegate?.collectionCell(self, performAction: .showInConversation)
    }
}

extension CollectionCell: ZMMessageObserver {
    public func messageDidChange(_ changeInfo: MessageChangeInfo!) {
        self.updateForMessage(changeInfo: changeInfo)
    }
}
