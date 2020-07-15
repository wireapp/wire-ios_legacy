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
import UIKit

enum PhoneWidth: CGFloat {
    case iPhone4 = 320
    case iPhone4_7 = 375
}

extension UITableViewCell {

    func prepareForSnapshots(width: PhoneWidth = .iPhone4_7) -> UITableView {
        
        bounds.size = systemLayoutSizeFitting(
            CGSize(width: width.rawValue, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return wrapInTableView()
    }

}
