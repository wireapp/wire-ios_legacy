//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class GuestsBarController: UIViewController {
    private let label = UILabel()
    private let container = UIView()
    private var containerHeightConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!
    
    private static let collapsedHeight: CGFloat = 2
    private static let expandedHeight: CGFloat = 20
    
    public var isCollapsed: Bool {
        get {
            return _isCollapsed
        }
        set {
            if newValue != _isCollapsed {
                setCollapsed(newValue, animated: false)
            }
        }
    }
    
    public func setCollapsed(_ collapsed: Bool, animated: Bool) {
        if collapsed == _isCollapsed {
            return
        }
        
        _isCollapsed = collapsed

        let change = {
            if (!collapsed) {
                self.heightConstraint.constant = collapsed ? GuestsBarController.collapsedHeight : GuestsBarController.expandedHeight
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
            
            self.containerHeightConstraint.constant = collapsed ? GuestsBarController.collapsedHeight : GuestsBarController.expandedHeight

            self.label.alpha = collapsed ? 0 : 1
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
        let completion: (Bool)->() = { _ in
            if (collapsed) {
                self.containerHeightConstraint.constant = collapsed ? GuestsBarController.collapsedHeight : GuestsBarController.expandedHeight
            }
        }
    
        if animated {
            UIView.wr_animate(easing: collapsed ? RBBEasingFunctionEaseOutQuad : RBBEasingFunctionEaseInQuad, duration: 1.0, animations: change, completion: completion)
        }
        else {
            change()
            completion(true)
        }
    }
    
    private var _isCollapsed: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        container.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorLightGraphite, variant: .dark)
        
        label.font = FontSpec(.small, .semibold).font!
        label.textColor = .white
        label.text = "conversation.guests_present".localized.uppercased()
        label.textAlignment = .center
        
        container.addSubview(label)
        
        view.addSubview(container)
        
        constrain(self.view, container, label) { view, container, label in
            label.edges == view.edges
            view.leading == container.leading
            view.trailing == container.trailing
            container.top == view.top

            heightConstraint = view.height == GuestsBarController.expandedHeight
            containerHeightConstraint = container.height == GuestsBarController.expandedHeight
        }
    }
}

extension GuestsBarController: Bar {
    var weight: Float {
        return 1
    }
}
