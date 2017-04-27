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

internal class LineView: UIView {
    public let views: [UIView]
    init(views: [UIView]) {
        self.views = views
        super.init(frame: .zero)
        layoutViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutViews() {
        
        self.views.forEach(self.addSubview)
        
        guard let first = self.views.first else {
            return
        }
        
        let inset: CGFloat = 24
        
        constrain(self, first) { selfView, first in
            first.leading == selfView.leading
            first.top == selfView.top ~ LayoutPriority(750)
            first.bottom == selfView.bottom ~ LayoutPriority(750)
        }
        
        var previous: UIView = first
        
        self.views.dropFirst().forEach {
            constrain(previous, $0, self) { previous, current, selfView in
                current.leading == previous.trailing + inset
                current.top == selfView.top ~ LayoutPriority(750)
                current.bottom == selfView.bottom ~ LayoutPriority(750)
            }
            previous = $0
        }

        guard let last = self.views.last else {
            return
        }
        
        constrain(self, last) { selfView, last in
            last.trailing == selfView.trailing
        }
    }
}

final internal class SpaceSelectorView: UIView {
    public let spaces: [Space]
    public let spacesViews: [SpaceView]
    private let lineView: LineView
    private var topOffsetConstraint: NSLayoutConstraint!
    public var imagesCollapsed: Bool = false {
        didSet {
            self.topOffsetConstraint.constant = imagesCollapsed ? -20 : 0
            
            self.spacesViews.flatMap { [$0.imageView, $0.dotView] }.forEach { $0.alpha = imagesCollapsed ? 0 : 1 }
            
            self.layoutIfNeeded()
        }
    }
    
    init(spaces: [Space]) {
        self.spaces = spaces
        self.spacesViews = self.spaces.map { SpaceView(space: $0) }
        self.lineView = LineView(views: self.spacesViews)
        super.init(frame: .zero)
        
        self.addSubview(lineView)
        self.clipsToBounds = true

        constrain(self, self.lineView) { selfView, lineView in
            self.topOffsetConstraint = lineView.centerY == selfView.centerY
            lineView.leading == selfView.leading
            lineView.trailing == selfView.trailing
            lineView.height == selfView.height
        }
        
        self.spacesViews.forEach {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didSelectSpace(_:)))
            $0.addGestureRecognizer(tapGesture)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc public func didSelectSpace(_ sender: UITapGestureRecognizer!) {
        guard let spaceView = sender.view as? SpaceView else {
            fatal("Incorrect view")
        }
        
        let tappedSpace = spaceView.space
        
        let allExceptTapped = self.spaces.filter { $0 != tappedSpace }
        
        let allSelected = self.spaces.map { $0.selected }.reduce(true) { $0 && $1 }
        
        if allSelected {
            allExceptTapped.forEach {
                $0.selected = false
            }
        }
        else {
            tappedSpace.selected = !tappedSpace.selected
        }
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

@objc internal class SpaceView: UIView {
    public final class SpaceImageView: UIImageView {
        private var lastLayoutBounds: CGRect = .zero
        private let maskLayer = CALayer()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.mask = maskLayer
            maskLayer.contentsScale = UIScreen.main.scale
            maskLayer.contentsGravity = "center"
            self.updateClippingLayer()
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

        override func layoutSubviews() {
            super.layoutSubviews()
            
            if !bounds.equalTo(lastLayoutBounds) {
                updateClippingLayer()
                lastLayoutBounds = self.bounds
            }
        }
    }
    
    public let space: Space
    
    public let nameLabel = UILabel()
    public let dotView = DotView()
    public let imageView = SpaceImageView(frame: .zero)
    
    private var observerUnreadToken: NSObjectProtocol!
    private var observerSelectionToken: NSObjectProtocol!
    
    init(space: Space) {
        self.space = space
        super.init(frame: .zero)
        
        observerSelectionToken = space.addSelectionObserver(self)
        observerUnreadToken = space.addUnreadObserver(self)
        [imageView, nameLabel, dotView].forEach(self.addSubview)
        
        imageView.contentMode = .scaleAspectFill
        
        nameLabel.textAlignment = .center
        nameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        nameLabel.lineBreakMode = .byTruncatingTail
        
        let dotSize: CGFloat = 8
        
        dotView.backgroundColor = .accent()
        
        constrain(self, imageView, nameLabel, dotView) { selfView, imageView, nameLabel, dotView in
            imageView.top == selfView.top + 12
            imageView.centerX == selfView.centerX
            selfView.width >= imageView.width
            selfView.right >= dotView.right
            imageView.width == imageView.height
            imageView.width == 28
            
            nameLabel.top == imageView.bottom + 4

            nameLabel.leading == selfView.leading
            nameLabel.trailing == selfView.trailing
            nameLabel.bottom == selfView.bottom - 4
            nameLabel.width <= 96
            
            dotView.width == dotView.height
            dotView.height == dotSize
            
            dotView.centerX == imageView.trailing - 3
            dotView.centerY == imageView.centerY - 6
            
            selfView.width <= 96
        }
        
        self.update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func update() {
        self.updateLabel()
        self.updateImage()
        self.updateDot()
    }
    
    fileprivate func updateLabel() {
        self.nameLabel.text = self.space.name
        self.cas_styleClass = space.selected ? "selected" : .none
    }
    
    static let ciContext: CIContext = {
        return CIContext()
    }()
    
    fileprivate func updateImage() {
        if let image = self.space.image {
            self.imageView.image = self.space.selected ? image : image.desaturatedImage(with: SpaceView.ciContext, saturation: 0.2)
            self.imageView.backgroundColor = nil
        }
        else {
            self.imageView.image = nil
            self.imageView.backgroundColor = self.space.selected ? ZMUser.selfUser().accentColor : ZMUser.selfUser().accentColor.mix(.gray, amount: 0.5)
        }
    }
    
    fileprivate func updateDot() {
        self.dotView.isHidden = space.selected || !self.space.hasUnreadMessages()
    }
}

extension SpaceView: SpaceUnreadObserver, SpaceSelectionObserver {
    func spaceDidChangeUnread(space: Space) {
        self.update()
    }
    
    func spaceDidChangeSelection(space: Space) {
        self.update()
    }
}
