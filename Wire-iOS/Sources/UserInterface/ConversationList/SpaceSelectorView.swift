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
        
        let inset: CGFloat = 32
        
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

final internal class SpaceSelectorView: LineView {
    public let spaces: [Space]
    public let spacesViews: [SpaceView]
    
    init(spaces: [Space]) {
        self.spaces = spaces
        self.spacesViews = self.spaces.map { SpaceView(space: $0) }
        super.init(views: spacesViews)
        
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
        spaceView.space.selected = !spaceView.space.selected
    }
}

@objc internal class DotView: UIView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = min(self.bounds.size.width / 2, self.bounds.size.height / 2)
    }
}

@objc internal class SpaceView: UIView {
    public let space: Space
    
    public let nameLabel = UILabel()
    public let dotView = DotView()
    
    private var observerUnreadToken: NSObjectProtocol!
    private var observerSelectionToken: NSObjectProtocol!
    
    init(space: Space) {
        self.space = space
        super.init(frame: .zero)
        
        observerSelectionToken = space.addSelectionObserver(self)
        observerUnreadToken = space.addUnreadObserver(self)
        [nameLabel, dotView].forEach(self.addSubview)
        
        let dotSize: CGFloat = 6
        
        dotView.backgroundColor = .accent()
        
        constrain(self, nameLabel, dotView) { selfView, nameLabel, dotView in
            nameLabel.edges == selfView.edges
            
            dotView.width == dotView.height
            dotView.height == dotSize
            
            dotView.centerX == nameLabel.trailing
            dotView.centerY == nameLabel.centerY - 6
            
            selfView.height == 40
        }
        
        self.updateLabel()
        self.updateDot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateLabel() {
        self.nameLabel.text = self.space.name.uppercased()
        self.cas_styleClass = space.selected ? "selected" : .none
    }
    
    fileprivate func updateDot() {
        self.dotView.isHidden = !self.space.hasUnreadMessages()
    }
}

extension SpaceView: SpaceUnreadObserver, SpaceSelectionObserver {
    func spaceDidChangeUnread(space: Space) {
        self.updateLabel()
        self.updateDot()
    }
    
    func spaceDidChangeSelection(space: Space) {
        self.updateLabel()
        self.updateDot()
    }
}
