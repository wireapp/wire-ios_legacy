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

final class MockTapGestureRecognizer: UITapGestureRecognizer {
    let mockState: UIGestureRecognizerState
    var mockLocation: CGPoint?

    init(location: CGPoint?, state: UIGestureRecognizerState) {
        mockLocation = location
        mockState = state

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        return mockLocation ?? super.location(in: view)
    }

    override var state: UIGestureRecognizerState {
        get {
            return mockState
        }
        set {}
    }
}
