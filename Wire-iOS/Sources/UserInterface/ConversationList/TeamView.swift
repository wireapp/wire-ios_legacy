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
import Classy

extension TeamType {
    func hasUnreadMessages() -> Bool {
        for conversation in self.conversations {
            if conversation.estimatedUnreadCount != 0 {
                return true
            }
        }
        
        return false
    }
}

@objc internal class DotView: UIView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = min(self.bounds.size.width / 2, self.bounds.size.height / 2)
    }
}

public protocol TeamViewType {
    var collapsed: Bool { get set }
    var onTap: ((TeamType?) -> ())? { get set }
    func update()
}

public class BaseTeamView: UIView, TeamViewType {
    
    fileprivate let imageViewContainer = UIView()
    fileprivate let outlineView = UIView()
    fileprivate let nameLabel = UILabel()
    fileprivate let dotView = DotView()
    fileprivate let nameDotView = DotView()
    
    public var collapsed: Bool = false
    public var onTap: ((TeamType?) -> ())? = .none
    
    init() {
        super.init(frame: .zero)
        
        nameLabel.textAlignment = .center
        nameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        nameLabel.lineBreakMode = .byTruncatingTail
        
        dotView.backgroundColor = .accent()
        
        nameDotView.backgroundColor = .accent()
        
        [imageViewContainer, outlineView, nameLabel, dotView, nameDotView].forEach(self.addSubview)
        
        let dotSize: CGFloat = 8
        
        constrain(self, imageViewContainer, nameLabel, dotView) { selfView, imageViewContainer, nameLabel, dotView in
            imageViewContainer.top == selfView.top + 12
            imageViewContainer.centerX == selfView.centerX
            selfView.width >= imageViewContainer.width
            selfView.right >= dotView.right
            imageViewContainer.width == imageViewContainer.height
            imageViewContainer.width == 28
            
            nameLabel.top == imageViewContainer.bottom + 4
            
            nameLabel.leading == selfView.leading
            nameLabel.trailing == selfView.trailing
            nameLabel.bottom == selfView.bottom - 4
            nameLabel.width <= 96
            
            dotView.width == dotView.height
            dotView.height == dotSize
            
            dotView.centerX == imageViewContainer.trailing - 3
            dotView.centerY == imageViewContainer.centerY - 6
            
            selfView.width <= 96
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update() {
        // no-op
    }
    
    @objc public func didTap(_ sender: UITapGestureRecognizer!) {
        self.onTap?(.none)
    }
}

public final class PersonalTeamView: BaseTeamView {
    private let userImageView = UserImageView(size: .normal)
    

    private var selfUserObserver: NSObjectProtocol!
    
    public override var collapsed: Bool {
        didSet {
            self.userImageView.isHidden = collapsed
            self.dotView.isHidden = collapsed
        }
    }
    
    override init() {
        super.init()
        userImageView.user = ZMUser.selfUser()
        selfUserObserver = UserChangeInfo.add(observer: self, forBareUser: ZMUser.selfUser())
        
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        self.nameLabel.text = ZMUser.selfUser().displayName
    }
}

extension PersonalTeamView: ZMUserObserver {
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        self.update()
    }
}

public final class TeamImageView: UIImageView {
    private var lastLayoutBounds: CGRect = .zero
    private let maskLayer = CALayer()
    private let initialLabel = UILabel()
    public let team: TeamType
    public var selected: Bool = false {
        didSet {
            
        }
    }
    
    init(team: TeamType) {
        self.team = team
        super.init(frame: .zero)
        layer.mask = maskLayer
        
        initialLabel.textAlignment = .center
        self.addSubview(self.initialLabel)
        self.accessibilityElements = [initialLabel]
        
        constrain(self, initialLabel) { selfView, initialLabel in
            initialLabel.center == selfView.center
        }
        
        maskLayer.contentsScale = UIScreen.main.scale
        maskLayer.contentsGravity = "center"
        self.updateClippingLayer()
        self.updateImage()
        
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateClippingLayer() {
        guard bounds.size != .zero else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, maskLayer.contentsScale)
        WireStyleKit.drawSpace(withFrame: bounds, resizing: WireStyleKitResizingBehaviorCenter, color: .black)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        maskLayer.frame = layer.bounds
        maskLayer.contents = image.cgImage
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !bounds.equalTo(lastLayoutBounds) {
            updateClippingLayer()
            lastLayoutBounds = self.bounds
        }
    }
    
    fileprivate func updateImage() {
        if let _ = self.team.teamPictureAssetKey {
            // TODO: SMB: load image
//            self.image = self.team.isSelected ? image : image.desaturatedImage(with: TeamView.ciContext, saturation: 0.2)
            self.initialLabel.text = ""
            self.backgroundColor = .clear
        }
        else if let name = self.team.name {
            self.image = nil
            self.initialLabel.text = name.substring(to: name.index(after: name.startIndex))
            
            let teamImageColor = team.isActive ? ColorScheme().color(withName: ColorSchemeColorTextBackground,  variant: .light) : ColorScheme().color(withName: ColorSchemeColorTextDimmed, variant: .dark)
            self.backgroundColor = teamImageColor
        }
    }
}

@objc internal class TeamView: BaseTeamView {

    public let team: TeamType
    public override var collapsed: Bool {
        didSet {
            
        }
    }
    
    private let imageView: TeamImageView
    
    private var observerUnreadToken: NSObjectProtocol!
    private var observerSelectionToken: NSObjectProtocol!
    
    init(team: TeamType) {
        self.team = team
        self.imageView = TeamImageView(team: team)
        
        super.init()
        
        imageView.contentMode = .scaleAspectFill
        
        self.update()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        self.updateLabel()
        self.imageView.selected = self.team.isActive
        self.imageView.updateImage()
        self.updateDot()
    }
    
    fileprivate func updateLabel() {
        self.nameLabel.text = self.team.name
        self.cas_styleClass = team.isActive ? "selected" : .none
    }
    
    static let ciContext: CIContext = {
        return CIContext()
    }()
    
    fileprivate func updateDot() {
        self.dotView.isHidden = team.isActive || !self.team.hasUnreadMessages()
    }
    
    @objc override public func didTap(_ sender: UITapGestureRecognizer!) {
        self.onTap?(self.team)
    }
}
