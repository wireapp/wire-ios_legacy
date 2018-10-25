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

@objcMembers class CustomSpacingStackView: UIView {

    private var stackView: UIStackView
    
    /**
     This initializer must be used if you intend to call wr_addCustomSpacing.
     */
    init(customSpacedArrangedSubviews subviews : [UIView]) {
        var subviewsWithSpacers : [UIView] = []
        
        subviews.forEach { view in
            subviewsWithSpacers.append(view)
            subviewsWithSpacers.append(SpacingView(0))
        }
        
        stackView = UIStackView(arrangedSubviews: subviewsWithSpacers)
        
        super.init(frame: .zero)
        
        addSubview(stackView)
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        stackView = UIStackView()
        super.init(coder: aDecoder)
    }
    
    /**
     Add a custom spacing after a view.
     
     This is a approximation of the addCustomSpacing method only available since iOS 11. This method
     has several constraints:
     
     - The stackview must be initialized with customSpacedArrangedSubviews
     - spacing dosesn't update if views are hidden after this method is called
     - custom spacing can't be smaller than 2x the minimum spacing
     */
    func wr_addCustomSpacing(_ customSpacing: CGFloat, after view: UIView) {
        guard let spacerIndex = stackView.subviews.index(of: view)?.advanced(by: 1),
            let spacer = stackView.subviews[spacerIndex] as? SpacingView else { return }
        
        if view.isHidden || customSpacing < (stackView.spacing * 2) {
            spacer.isHidden = true
        } else {
            spacer.size = customSpacing - stackView.spacing
        }
    }
    
    private func createConstraints() {
        constrain(self, stackView) { view, stackView in
            stackView.edges == view.edges
        }
    }
    
    var alignment: UIStackView.Alignment {
        get { return stackView.alignment }
        set { stackView.alignment = newValue }
    }

    var distribution: UIStackView.Distribution {
        get { return stackView.distribution }
        set { stackView.distribution = newValue }
    }

    var axis: NSLayoutConstraint.Axis {
        get { return stackView.axis }
        set { stackView.axis = newValue }
    }
    
    var spacing: CGFloat {
        get { return stackView.spacing }
        set { stackView.spacing = newValue }
    }
    
}

fileprivate class SpacingView : UIView {
    
    var size : CGFloat
    
    public init(_ size : CGFloat) {
        self.size = size
        
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: size, height: size)))
        
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: size, height: size)
    }
    
}

