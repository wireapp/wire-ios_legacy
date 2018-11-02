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

open class LayerHostView<LayerType: CALayer>: UIView {
    var hostedLayer: LayerType {
        return self.layer as! LayerType
    }
    override open class var layerClass : AnyClass {
        return LayerType.self
    }
}


class ShapeView: LayerHostView<CAShapeLayer> {
    public var pathGenerator: ((CGSize) -> (UIBezierPath))? {
        didSet {
            self.updatePath()
        }
    }

    private var lastBounds: CGRect = .zero
    
    private func updatePath() {
        guard let generator = self.pathGenerator else {
            return
        }
        
        self.hostedLayer.path = generator(bounds.size).cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !lastBounds.equalTo(self.bounds) {
            lastBounds = self.bounds
            
            self.updatePath()
        }
    }
}

public protocol AccountViewType {
    var collapsed: Bool { get set }
    var hasUnreadMessages: Bool { get }
    var onTap: ((Account?) -> ())? { get set }
    func update()
    var account: Account { get }
}

public final class AccountViewFactory {
    public static func viewFor(account: Account, user: ZMUser? = nil) -> BaseAccountView {
        return account.teamName == nil ? PersonalAccountView(account: account, user: user)
            : TeamAccountView(account: account, user: user)
    }
}

public enum AccountUnreadCountStyle {
    /// Do not display an unread count.
    case none
    /// Display unread count only considering current account.
    case current
    /// Display unread count only considering other accounts.
    case others
}

public class BaseAccountView: UIView, AccountViewType {
    public var autoUpdateSelection: Bool = true
    
    internal let imageViewContainer = UIView()
    fileprivate let outlineView = UIView()
    fileprivate let dotView : DotView
    fileprivate let selectionView = ShapeView()
    fileprivate var unreadCountToken : Any?
    fileprivate var selfUserObserver: NSObjectProtocol!
    public let account: Account
    
    public var unreadCountStyle : AccountUnreadCountStyle = .none {
        didSet {
            updateAppearance()
        }
    }
    
    public var selected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    public var collapsed: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    public var hasUnreadMessages: Bool {
        switch unreadCountStyle {
        case .none:
            return false
        case .current:
            return account.unreadConversationCount > 0
        case .others:
            return ((SessionManager.shared?.accountManager.totalUnreadCount ?? 0) - account.unreadConversationCount) > 0
        }
    }
    
    func updateAppearance() {
        
        selectionView.isHidden = !selected || collapsed
        dotView.hasUnreadMessages = hasUnreadMessages
        selectionView.hostedLayer.strokeColor = UIColor.accent().cgColor
        self.layoutSubviews()
    }
    
    public var onTap: ((Account?) -> ())? = .none
    
    public var accessibilityState: String {
        return ("conversation_list.header.self_team.accessibility_value." + (self.selected ? "active" : "inactive")).localized +
                (self.hasUnreadMessages ? (" " + "conversation_list.header.self_team.accessibility_value.has_new_messages".localized) : "")
    }
    
    init(account: Account, user: ZMUser? = nil) {
        self.account = account
        
        dotView = DotView(user: user)
        dotView.hasUnreadMessages = account.unreadConversationCount > 0
        
        super.init(frame: .zero)
        
        if let userSession = SessionManager.shared?.activeUserSession {
            selfUserObserver = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(inUserSession: userSession), userSession: userSession)
        }

        selectionView.hostedLayer.strokeColor = UIColor.accent().cgColor
        selectionView.hostedLayer.fillColor = UIColor.clear.cgColor
        selectionView.hostedLayer.lineWidth = 1.5
        
        [imageViewContainer, outlineView, selectionView, dotView].forEach(self.addSubview)
        
        constrain(imageViewContainer, selectionView) { imageViewContainer, selectionView in
            selectionView.edges == inset(imageViewContainer.edges, -1, -1)
        }

        let dotSize: CGFloat = 9

        constrain(imageViewContainer, dotView) { imageViewContainer, dotView in
            dotView.centerX == imageViewContainer.trailing - 3
            dotView.centerY == imageViewContainer.centerY - 6
            
            dotView.width == dotView.height
            dotView.height == dotSize
        }
        
        let containerInset: CGFloat = 6
        
        constrain(self, imageViewContainer, dotView) { selfView, imageViewContainer, dotView in
            imageViewContainer.top == selfView.top + containerInset
            imageViewContainer.centerX == selfView.centerX
            selfView.width >= imageViewContainer.width
            selfView.trailing >= dotView.trailing
            
            imageViewContainer.width == 32
            imageViewContainer.height == imageViewContainer.width
            
            imageViewContainer.bottom == selfView.bottom - containerInset
            imageViewContainer.leading == selfView.leading + containerInset
            imageViewContainer.trailing == selfView.trailing - containerInset
            selfView.width <= 128
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.addGestureRecognizer(tapGesture)
        
        
        self.unreadCountToken = NotificationCenter.default.addObserver(forName: .AccountUnreadCountDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateAppearance()
        }
        
        updateAppearance()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update() {
        if self.autoUpdateSelection {
            self.selected = SessionManager.shared?.accountManager.selectedAccount == self.account
        }
    }
    
    @objc public func didTap(_ sender: UITapGestureRecognizer!) {
        self.onTap?(self.account)
    }
}

extension BaseAccountView: ZMConversationListObserver {
    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        updateAppearance()
    }
    
    public func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        updateAppearance()
    }
}

extension BaseAccountView: ZMUserObserver {
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.accentColorValueChanged {
            updateAppearance()
        }
    }
}

@objcMembers public final class PersonalAccountView: BaseAccountView {
    internal let userImageView: AvatarImageView = {
        let avatarImageView = AvatarImageView(frame: .zero)
        avatarImageView.container.backgroundColor = .from(scheme: .background, variant: .light)

        avatarImageView.initialsFont = .smallSemiboldFont
        avatarImageView.initialsColor = .from(scheme: .textForeground, variant: .light)

        return avatarImageView
    }()

    private var conversationListObserver: NSObjectProtocol!
    private var connectionRequestObserver: NSObjectProtocol!
    
    public override var collapsed: Bool {
        didSet {
            self.userImageView.isHidden = collapsed
        }
    }
    
    override init(account: Account, user: ZMUser? = nil) {
        super.init(account: account, user: user)
        
        
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.shouldGroupAccessibilityChildren = true
        self.accessibilityIdentifier = "personal team"
        
        selectionView.pathGenerator = {
            return UIBezierPath(ovalIn: CGRect(origin: .zero, size: $0))
        }

        if let userSession = ZMUserSession.shared() {
            conversationListObserver = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.conversations(inUserSession: userSession), userSession: userSession)
            connectionRequestObserver = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.pendingConnectionConversations(inUserSession: userSession), userSession: userSession)
        }
        
        self.imageViewContainer.addSubview(userImageView)
        constrain(imageViewContainer, userImageView) { imageViewContainer, userImageView in
            userImageView.edges == inset(imageViewContainer.edges, 2, 2)
        }
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        self.accessibilityValue = String(format: "conversation_list.header.self_team.accessibility_value".localized, self.account.userName) + " " + accessibilityState
        if let imageData = self.account.imageData {
            userImageView.avatar = UIImage(data: imageData).map(AvatarImageView.Avatar.image)
        }
        else {
            let personName = PersonName.person(withName: self.account.userName, schemeTagger: nil)
            userImageView.avatar = .text(personName.initials)
        }
    }
}

extension PersonalAccountView {
    override public func userDidChange(_ changeInfo: UserChangeInfo) {
        super.userDidChange(changeInfo)
        if changeInfo.nameChanged || changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged  {
            update()
        }
    }
}

@objcMembers public final class TeamImageView: UIImageView {
    public enum TeamImageViewStyle {
        case small
        case big
    }
    
    private let account: Account
    
    private var lastLayoutBounds: CGRect = .zero
    private let maskLayer = CALayer()
    internal let initialLabel = UILabel()
    public var style: TeamImageViewStyle = .small {
        didSet {
            switch (self.style) {
            case .big:
                initialLabel.font = .largeThinFont
            case .small:
                applySmallStyle()
            }
        }
    }

    func applySmallStyle() {
        initialLabel.font = .smallSemiboldFont
        initialLabel.textColor = .from(scheme: .textForeground, variant: .light)
        backgroundColor = .from(scheme: .background, variant: .light)
    }
    
    init(account: Account) {
        self.account = account
        super.init(frame: .zero)
        layer.mask = maskLayer
        
        initialLabel.textAlignment = .center
        self.addSubview(self.initialLabel)
        self.accessibilityElements = [initialLabel]
        
        constrain(self, initialLabel) { selfView, initialLabel in
            initialLabel.centerY == selfView.centerY
            initialLabel.centerX == selfView.centerX
        }
        
        maskLayer.contentsScale = UIScreen.main.scale
        maskLayer.contentsGravity = .center
        self.updateClippingLayer()
        self.updateImage()

        applySmallStyle()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateClippingLayer() {
        guard bounds.size.height != 0 && bounds.size.width != 0 else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, maskLayer.contentsScale)
        WireStyleKit.drawSpace(frame: bounds, resizing: .aspectFit, color: .black)
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            
            maskLayer.frame = layer.bounds
            maskLayer.contents = image.cgImage
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !bounds.equalTo(lastLayoutBounds) {
            updateClippingLayer()
            lastLayoutBounds = self.bounds
        }
    }
    
    fileprivate func updateImage() {
        if let teamImageData = self.account.teamImageData {
            self.image = UIImage(data: teamImageData)
            self.initialLabel.text = ""
        }
        else if let name = self.account.teamName {
            self.image = nil
            self.initialLabel.text = String(name[..<name.index(after: name.startIndex)])
        }
    }
}

@objcMembers internal class TeamAccountView: BaseAccountView {
    
    public override var collapsed: Bool {
        didSet {
            self.imageView.isHidden = collapsed
        }
    }
    
    
    private let imageView: TeamImageView
    
    private var teamObserver: NSObjectProtocol!
    private var conversationListObserver: NSObjectProtocol!
    
    override init(account: Account, user: ZMUser? = nil) {
        
        imageView = TeamImageView(account: account)
        
        super.init(account: account, user: user)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        shouldGroupAccessibilityChildren = true
        
        imageView.contentMode = .scaleAspectFill
        
        imageViewContainer.addSubview(imageView)
        
        self.selectionView.pathGenerator = { size in
            
            let path = WireStyleKit.pathForTeamSelection()!
            let scale = (size.width - 3) / path.bounds.width
            path.apply(CGAffineTransform(scaleX: scale, y: scale))
            return path
        }
        
        constrain(imageViewContainer, imageView) { imageViewContainer, imageView in
            imageView.edges == inset(imageViewContainer.edges, 2, 2)
        }

        update()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        imageView.updateImage()
        accessibilityValue = String(format: "conversation_list.header.self_team.accessibility_value".localized, self.account.teamName ?? "") + " " + accessibilityState
        accessibilityIdentifier = "\(self.account.teamName ?? "") team"
    }
    
    
    static let ciContext: CIContext = {
        return CIContext()
    }()
}

extension TeamAccountView: TeamObserver {
    func teamDidChange(_ changeInfo: TeamChangeInfo) {
        self.update()
    }
}
