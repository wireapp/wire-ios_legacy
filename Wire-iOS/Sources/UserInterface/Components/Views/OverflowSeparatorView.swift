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
import Classy

@objc public class OverflowSeparatorView: UIView {    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.applyStyle()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.applyStyle()
    }
    
    private func applyStyle() {
        self.cas_styleClass = "separator"
        CASStyler.defaultStyler().styleItem(self)
        self.alpha = 0
    }
    
    override public func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, 0.5)
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView!) {
        self.alpha = scrollView.contentOffset.y > 0 ? 1 : 0
    }
}

