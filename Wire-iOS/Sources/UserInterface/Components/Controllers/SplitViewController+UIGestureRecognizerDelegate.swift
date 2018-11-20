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
//    @objc(gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:)
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//                                  shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        //    return gestureRecognizer == self.revealDrawerGestureRecognizer;
//
//        if otherGestureRecognizer.view is MarkdownTextView ||
//            otherGestureRecognizer.view is InputBar {
//            return true
//        }
//
//        return false
//    }

//    @objc(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if otherGestureRecognizer.view is MarkdownTextView ||
//            otherGestureRecognizer.view is InputBar {
//            return true
//        }
//
//        return false
//    }


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

        ///TODO: return false if keyboard is shown??
        return true
    }
}
