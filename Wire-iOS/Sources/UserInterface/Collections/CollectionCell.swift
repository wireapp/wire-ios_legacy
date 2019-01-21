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

open class CollectionCell: UICollectionViewCell {

    var actionController: ConversationMessageActionController?
    var messageObserverToken: NSObjectProtocol? = .none
    weak var delegate: CollectionCellDelegate?
    // Cell forwards the message changes to the delegate
    weak var messageChangeDelegate: CollectionCellMessageChangeDelegate?
    
    var message: ZMConversationMessage? = .none {
        didSet {
            self.messageObserverToken = nil
            if let userSession = ZMUserSession.shared(), let newMessage = message {
                self.messageObserverToken = MessageChangeInfo.add(observer: self, for: newMessage, userSession: userSession)
            }

            actionController = message.map {
                ConversationMessageActionController(responder: self, message: $0, context: .collection)
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
            let width = self.desiredWidth ?? UIView.noIntrinsicMetric
            let height = self.desiredHeight ?? UIView.noIntrinsicMetric
            
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

        self.contentView.addSubview(secureContentsView)
        self.contentView.addSubview(obfuscationView)

        secureContentsView.autoPinEdgesToSuperviewEdges()
        obfuscationView.autoPinEdgesToSuperviewEdges()
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        self.cachedSize = .none
        self.message = .none
    }
    
    @objc func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer!) {
        if gestureRecognizer.state == .began {
            self.showMenu()
        }
    }

    // MARK: - Obfuscation

    let secureContentsView: UIView = {
        let view = UIView()
        view.backgroundColor = .from(scheme: .placeholderBackground)

        return view
    }()

    var obfuscationIcon: ZetaIconType {
        return .exclamationMarkCircle
    }

    fileprivate lazy var obfuscationView = {
        return ObfuscationView(icon: self.obfuscationIcon)
    }()

    fileprivate func updateMessageVisibility() {
        let isObfuscated = message?.isObfuscated == true || message?.hasBeenDeleted == true
        secureContentsView.isHidden = isObfuscated
        obfuscationView.isHidden = !isObfuscated
        obfuscationView.backgroundColor = .accentDimmedFlat
    }

    // MARK: - Menu
    
    func menuConfigurationProperties() -> MenuConfigurationProperties? {
        let properties = MenuConfigurationProperties()
        properties.targetRect = self.contentView.bounds
        properties.targetView = self.contentView

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
        menuController.menuItems = ConversationMessageActionController.allMessageActions
        menuController.setTargetRect(menuConfigurationProperties.targetRect, in: menuConfigurationProperties.targetView)
        menuController.setMenuVisible(true, animated: true)
    }
    
    override open var canBecomeFirstResponder: Bool {
        return true
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return actionController?.canPerformAction(action) == true
    }

    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return actionController
    }
    
    /// To be implemented in the subclass
    func updateForMessage(changeInfo: MessageChangeInfo?) {
        self.updateMessageVisibility()
        // no-op
    }

    /**
     * Copies the contents of the message.
     * - parameter pasteboard: The pasteboard to copy the contents to.
     * - note: The default implementation copies using the default implementation. Override it
     * if you want to customize the behavior of the copy (ex: only copying parts of the message).
     */

    func copyDisplayedContent(in pasteboard: UIPasteboard) {
        message?.copy(in: pasteboard)
    }
    
}

extension CollectionCell: ZMMessageObserver {
    public func messageDidChange(_ changeInfo: MessageChangeInfo) {
        self.updateForMessage(changeInfo: changeInfo)
        self.messageChangeDelegate?.messageDidChange(self, changeInfo: changeInfo)
    }
}

extension CollectionCell: MessageActionResponder {
    public func perform(action: MessageAction, for message: ZMConversationMessage!) {
        delegate?.collectionCell(self, performAction: action)
    }
}
