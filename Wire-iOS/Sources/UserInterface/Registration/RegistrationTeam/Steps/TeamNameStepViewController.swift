//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography

class TeamNameStepViewController: UIViewController {
    //MARK:- UI styles

    static let headlineFont = FontSpec(.large, .light, .title1).font!
    static let regularFont = FontSpec(.normal, .regular).font!

    let headline: UILabel = {
        let label = UILabel()
        label.text = "team.name.headline".localized
        label.font = TeamNameStepViewController.headlineFont
//        label.textColor = .textColor

        return label
    }()

    let subheadline: UILabel = {
        let label = UILabel()
        label.text = "team.name.subheadline".localized
//        label.font = TeamNameStepViewController.subheadlineFont
//        label.textColor = .subtitleColor

        return label
    }()

}
