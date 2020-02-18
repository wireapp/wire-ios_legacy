// 
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

final class ZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private var interactionPoint = CGPoint.zero
    private var reversed = false
    
    init(interactionPoint: CGPoint, reversed: Bool) {
        super.init()
        
        self.interactionPoint = interactionPoint
        self.reversed = reversed
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.65
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to) else { return }
        let containerView = transitionContext.containerView
        
        if let view = transitionContext.viewController(forKey: .to) {
            toView.frame = transitionContext.finalFrame(for: view)
        }
        
        containerView.addSubview(toView)
        
        if !transitionContext.isAnimated {
            transitionContext.completeTransition(true)
            return
        }
        
        toView.layoutIfNeeded()
        
        fromView.alpha = 1
        fromView.layer.needsDisplayOnBoundsChange = false

        if reversed {
            
            UIView.wr_animate(easing: .easeInExpo, duration: 0.35, animations: {               fromView.alpha = 0
                fromView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }) { finished in
                fromView.transform = .identity
            }
            
            toView.alpha = 0
            toView.transform = CGAffineTransform(scaleX: 2, y: 2)
            
            
            UIView.wr_animate(easing: .easeOutExpo, duration: 0.35, animations: {
                toView.alpha = 1
                toView.transform = .identity
            }) { finished in
                transitionContext.completeTransition(true)
            }
        } else {
            
            var frame = fromView.frame
            fromView.layer.anchorPoint = interactionPoint
            fromView.frame = frame
            
            UIView.wr_animate(easing: .easeInExpo, duration: 0.35, animations: {
                fromView.alpha = 0
                fromView.transform = CGAffineTransform(scaleX: 2, y: 2)
            }) { finished in
                fromView.transform = CGAffineTransform.identity
            }
            
            frame = toView.frame
            toView.layer.anchorPoint = interactionPoint
            toView.frame = frame
            
            toView.alpha = 0
            toView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            
            
            UIView.wr_animate(easing: .easeOutExpo, duration: 0.35, delay: 0.3, animations: {
                toView.alpha = 1
                toView.transform = CGAffineTransform.identity
            }) { finished in
                transitionContext.completeTransition(true)
            }
        }
    }
}
