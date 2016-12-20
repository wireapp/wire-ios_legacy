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

@objc final public class CollectionLoadingCell: UICollectionViewCell, Reusable {
    let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.loadingView)
        
        self.loadingView.startAnimating()
        
        constrain(self, self.loadingView) { selfView, loadingView in
            loadingView.center == selfView.center
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isHeightCalculated: Bool = false
    
    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if !isHeightCalculated {
            var newFrame = layoutAttributes.frame
            newFrame.size.height = 64
            layoutAttributes.frame = newFrame
            isHeightCalculated = true
        }
        return layoutAttributes
    }
}
