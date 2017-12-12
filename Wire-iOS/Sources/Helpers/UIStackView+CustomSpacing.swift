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

extension UIStackView {
    
    /**
     This initializer must be used if you intend to call wr_addCustomSpacing.
     */
    convenience init(customSpacedArrangedSubviews subviews : [UIView]) {
        
        var subviewsWithSpacers : [UIView] = []
        
        subviews.forEach { view in
            subviewsWithSpacers.append(view)
            subviewsWithSpacers.append(SpacingView(0))
        }
        
        self.init(arrangedSubviews: subviewsWithSpacers)
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
        if let spacerIndex = subviews.index(of: view)?.advanced(by: 1) {
            if let spacer = subviews[spacerIndex] as? SpacingView {
                if view.isHidden || customSpacing < (spacing * 2) {
                    spacer.isHidden = true
                } else {
                    spacer.size = customSpacing - spacing
                }
            }
        }
    }
    
}

fileprivate class SpacingView : UIView {
    
    var size : CGFloat
    
    public init(_ size : CGFloat) {
        self.size = size
        
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: size, height: size)))
        
        setContentCompressionResistancePriority(999, for: .vertical)
        setContentCompressionResistancePriority(999, for: .horizontal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: size, height: size)
    }
    
}
