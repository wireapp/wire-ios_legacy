
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

// Because the system manages the input accessory view lifecycle and positioning, we have to monitor what
// is being done to us and report back

protocol InvisibleInputAccessoryViewDelegate: class {
    func invisibleInputAccessoryView(_ view: InvisibleInputAccessoryView, superviewFrameChanged frame: CGRect?)
}

final class InvisibleInputAccessoryView: UIView {
    weak var delegate: InvisibleInputAccessoryViewDelegate?
    
    var overriddenIntrinsicContentSize: CGSize = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override public var intrinsicContentSize: CGSize {
        return overriddenIntrinsicContentSize
    }
        
    private var frameObserver: NSObject?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil,
           let superview = superview {
            
            let keypath = "center"
            
            frameObserver = KeyValueObserver.observe(superview, keyPath: keypath, target: self, selector: #selector(superviewFrameChanged(_:)))
        } else {
            frameObserver = nil
        }
    }
    
    @objc
    private func superviewFrameChanged(_ changes: [AnyHashable : Any]?) {
        delegate?.invisibleInputAccessoryView(self, superviewFrameChanged: superview?.frame)
    }
}
