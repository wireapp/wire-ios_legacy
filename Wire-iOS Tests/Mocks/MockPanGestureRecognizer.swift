//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class MockPanGestureRecognizer: UIPanGestureRecognizer {
    let mockState: UIGestureRecognizer.State
    var mockLocation: CGPoint?
    var mockTranslation: CGPoint?
    var mockView: UIView?

    init(location: CGPoint?, translation: CGPoint?, view: UIView?, state: UIGestureRecognizer.State) {
        mockLocation = location
        mockTranslation = translation
        mockState = state
        mockView = view

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        return mockLocation ?? super.location(in: view)
    }

    override func translation(in view: UIView?) -> CGPoint {
        return mockTranslation ?? super.translation(in: view)
    }

    override var view: UIView? {
        return mockView ?? super.view
    }

    override var state: UIGestureRecognizer.State {
        get { mockState }
        set {}
    }
}
