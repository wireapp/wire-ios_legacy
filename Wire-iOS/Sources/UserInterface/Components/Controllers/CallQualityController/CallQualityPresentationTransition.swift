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

import UIKit

class CallQualityPresentationTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.55
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let callQualityVC = transitionContext.viewController(forKey: .to) as? CallQualityViewController else {
            return
        }
        
        // Prepare view hierarchy
        
        let containerView = transitionContext.containerView
        let toView = callQualityVC.view!
        let contentView = callQualityVC.contentView
        let dimmingView = callQualityVC.dimmingView
        
        containerView.addSubview(toView)
        callQualityVC.updateLayout(for: containerView.traitCollection)

        switch containerView.traitCollection.horizontalSizeClass {
        case .regular:
            contentView.transform = CGAffineTransform(scaleX: 0, y: 0)
            
        default:
            contentView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height)
        }
        
        // Animate Presentation
        
        let duration = transitionDuration(using: transitionContext)

        let animations = {
            dimmingView.alpha = 1
            contentView.transform = .identity
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .systemPresentationCurve, animations: animations) { finished in
            transitionContext.completeTransition((transitionContext.transitionWasCancelled == false) && finished)
        }
        
    }
    
}
