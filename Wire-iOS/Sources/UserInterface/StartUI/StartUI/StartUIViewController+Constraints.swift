//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireDataModel

extension StartUIViewController {
    func createConstraints() {
        [searchHeaderViewController.view, groupSelector, searchResultsViewController.view].forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        searchHeaderViewController.view.fitInSuperview(exclude: [.bottom])

        if showsGroupSelector {
            NSLayoutConstraint.activate([
                groupSelector.topAnchor.constraint(equalTo: searchHeaderViewController.view.bottomAnchor),
                searchResultsViewController.view.topAnchor.constraint(equalTo: groupSelector.bottomAnchor)
                ])

            groupSelector.fitInSuperview(exclude: [.bottom, .top])
        } else {
            NSLayoutConstraint.activate([
            searchResultsViewController.view.topAnchor.constraint(equalTo: searchHeaderViewController.view.bottomAnchor)
                ])
        }

        searchResultsViewController.view.fitInSuperview(exclude: [.top])
    }

    var showsGroupSelector: Bool {
        return SearchGroup.all.count > 1 && ZMUser.selfUser().canSeeServices
    }
}
