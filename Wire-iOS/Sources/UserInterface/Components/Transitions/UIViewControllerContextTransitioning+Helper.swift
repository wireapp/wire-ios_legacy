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
import UIKit

extension UIViewControllerContextTransitioning {
    var fromView: UIView? {
        return view(forKey: .from)
    }
    
    var toView: UIView? {
        let returnView = view(forKey: .to)
        
        if let view = viewController(forKey: .to) {
            returnView?.frame = finalFrame(for: view)
        }
        
        return returnView
    }
    
    var fromViewController: UIViewController? {
        return viewController(forKey: .from)
    }
    
    var toViewController: UIViewController? {
        return viewController(forKey: .to)
    }
}
