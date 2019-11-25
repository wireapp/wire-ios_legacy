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

extension SplitViewController: UIGestureRecognizerDelegate {

    @objc(gestureRecognizerShouldBegin:)
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if layoutSize == .regularLandscape {
            return false
        }

        if let delegate = delegate, !delegate.splitViewControllerShouldMoveLeftViewController(self) {
            return false
        }

        if isLeftViewControllerRevealed && !isIPadRegular() {
            return false
        }

        return true
    }
}

extension SplitViewController {
    @objc
    func onHorizontalPan(_ gestureRecognizer: UIPanGestureRecognizer?) {
        
        guard layoutSize != .regularLandscape,
              delegate?.splitViewControllerShouldMoveLeftViewController(self) == true,
              isConversationViewVisible,
              let gestureRecognizer = gestureRecognizer else {
            return
        }
        
        var offset = gestureRecognizer.translation(in: view)
        
        switch gestureRecognizer.state {
        case .began:
            leftViewController?.beginAppearanceTransition(!isLeftViewControllerRevealed, animated: true)
            rightViewController?.beginAppearanceTransition(isLeftViewControllerRevealed, animated: true)
            leftView?.isHidden = false
        case .changed:
            if let width = leftViewController?.view.bounds.size.width {
                if isLeftViewControllerRevealed {
                    if offset.x > 0 {
                        offset.x = 0
                    }
                    if abs(offset.x) > width {
                        offset.x = -width
                    }
                    openPercentage = 1.0 - abs(offset.x) / width
                } else {
                    if offset.x < 0 {
                        offset.x = 0
                    }
                    if abs(offset.x) > width {
                        offset.x = width
                    }
                    openPercentage = abs(offset.x) / width
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                }
                view.layoutIfNeeded()
            }
        case .cancelled,
             .ended:
            let isRevealed = openPercentage > 0.5
            let didCompleteTransition = isRevealed != isLeftViewControllerRevealed
            
            setLeftViewControllerRevealed(isRevealed, animated: true) { [weak self] in
                
                if didCompleteTransition {
                    self?.leftViewController?.endAppearanceTransition()
                    self?.rightViewController?.endAppearanceTransition()
                }
            }
        default:
            break
        }
    }

}
