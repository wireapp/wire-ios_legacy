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

import UIKit
import Cartography


class AnimatedPenView : UIView {
    
    private let WritingAnimationKey = "writing"
    private let dots = UIImageView()
    private let pen = UIImageView()
    
    public var isAnimating : Bool = false {
        didSet {
            pen.layer.speed = isAnimating ? 1 : 0
            pen.layer.beginTime = pen.layer.convertTime(CACurrentMediaTime(), from: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let iconColor = UIColor.from(scheme: .textForeground)
        let backgroundColor = UIColor.from(scheme: .background)
        
        dots.image = UIImage(for: .typingDots, fontSize: 8, color: iconColor)
        pen.image = UIImage(for: .pencil, fontSize: 8, color: iconColor)
        pen.backgroundColor = backgroundColor
        pen.contentMode = .center

        addSubview(dots)
        addSubview(pen)
        
        setupConstraints()
        startWritingAnimation()
        
        pen.layer.speed = 0
        pen.layer.timeOffset = 2
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        startWritingAnimation()
    }
    
    func setupConstraints() {
        constrain(self, dots, pen) { container, dots, pen in
            distribute(by: 2, horizontally: dots, pen)
            
            dots.left == container.left
            dots.top == container.top
            dots.bottom == container.bottom
            
            pen.right == container.right
            pen.top == container.top
            pen.bottom == container.bottom
        }
    }
    
    func startWritingAnimation() {
        
        let p1 = 7
        let p2 = 10
        let p3 = 13
        let moveX = CAKeyframeAnimation(keyPath: "position.x")
        moveX.values = [p1, p2, p2, p3, p3, p1]
        moveX.keyTimes = [0, 0.25, 0.35, 0.50, 0.75, 0.85]
        moveX.duration = 2
        moveX.repeatCount = Float.infinity
        
        pen.layer.add(moveX, forKey: WritingAnimationKey)
    }
    
    func stopWritingAnimation() {
        pen.layer.removeAnimation(forKey: WritingAnimationKey)
    }
    
    @objc func applicationDidBecomeActive(_ notification : Notification) {
        startWritingAnimation()
    }

}

@objcMembers class TypingIndicatorView: UIView {
    
    public let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .smallLightFont
        label.textColor = .from(scheme: .textPlaceholder)

        return label
    }()
    public let animatedPen = AnimatedPenView()
    public let container: UIView = {
        let view = UIView()
        view.backgroundColor = .from(scheme: .background)

        return view
    }()
    public let expandingLine: UIView = {
        let view = UIView()
        view.backgroundColor = .from(scheme: .background)

        return view
    }()

    private var expandingLineWidth : NSLayoutConstraint?
    
    public var typingUsers : [ZMUser] = [] {
        didSet {
            updateNameLabel()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(expandingLine)
        addSubview(container)
        container.addSubview(nameLabel)
        container.addSubview(animatedPen)
                
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        container.layer.cornerRadius = container.bounds.size.height / 2
    }
    
    func setupConstraints() {
        constrain(self, container, nameLabel, animatedPen, expandingLine) { view, container, nameLabel, animatedPen, expandingLine in
            container.edges == view.edges
            
            distribute(by: 4, horizontally: animatedPen, nameLabel)
            
            animatedPen.left == container.left + 8
            animatedPen.centerY == container.centerY
            
            nameLabel.top == container.top + 4
            nameLabel.bottom == container.bottom - 4
            nameLabel.right == container.right - 8
            
            expandingLine.center == view.center
            expandingLine.height == 1
            expandingLineWidth = expandingLine.width == 0
        }
    }
    
    func updateNameLabel() {
        nameLabel.text = typingUsers.map({ $0.displayName.uppercased(with: Locale.current) }).joined(separator: ", ")
    }
    
    public func setHidden(_ hidden : Bool, animated : Bool) {
        
        let collapseLine = { () -> Void in
            self.expandingLineWidth?.constant = 0
            self.layoutIfNeeded()
        }
        
        let expandLine = { () -> Void in
            self.expandingLineWidth?.constant = self.bounds.width
            self.layoutIfNeeded()
        }
        
        let showContainer = {
            self.container.alpha = 1
        }
        
        let hideContainer = {
            self.container.alpha = 0
        }
        
        if (animated) {
            if (hidden) {
                collapseLine()
                UIView.animate(withDuration: 0.15, animations: hideContainer)
            } else {
                animatedPen.isAnimating = false
                self.layoutSubviews()
                UIView.wr_animate(easing: .easeInOutQuad, duration: 0.35, animations: expandLine)
                UIView.wr_animate(easing: .easeInQuad, duration: 0.15, delay: 0.15, animations: showContainer, options: .beginFromCurrentState, completion: { _ in
                    self.animatedPen.isAnimating = true
                })
            }
            
        } else {
            if (hidden) {
                collapseLine()
                self.container.alpha = 0
            } else {
                expandLine()
                showContainer()
            }
        }
    }
    
}
