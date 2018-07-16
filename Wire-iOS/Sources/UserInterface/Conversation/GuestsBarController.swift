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
    private var bottomLabelConstraint: NSLayoutConstraint!
    
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
    
    @objc public func setCollapsed(_ collapsed: Bool, animated: Bool) {
        
        guard self.isViewLoaded else {
            return
        }
        
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
            self.bottomLabelConstraint.constant = collapsed ? -GuestsBarController.expandedHeight : -3
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
            UIView.wr_animate(easing: collapsed ? .easeOutQuad : .easeInQuad, duration: 0.4, animations: change, completion: completion)
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
        
        container.backgroundColor = UIColor(scheme: .lightGraphite, variant: .dark)
        container.clipsToBounds = true
        
        label.font = FontSpec(.small, .semibold).font!
        label.textColor = .white
        label.text = "conversation.guests_present".localized.uppercased()
        label.textAlignment = .center
        label.accessibilityIdentifier = "label.conversationview.hasguests"
        
        container.addSubview(label)
        
        view.addSubview(container)
        
        constrain(self.view, container, label) { view, container, label in
            label.leading == view.leading
            bottomLabelConstraint = label.bottom == view.bottom - 3
            label.trailing == view.trailing
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
