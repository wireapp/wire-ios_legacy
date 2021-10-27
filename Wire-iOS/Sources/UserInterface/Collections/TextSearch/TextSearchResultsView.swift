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
import Cartography

final class TextSearchResultsView: UIView {
    var tableView = UITableView()
    var noResultsView = NoResultsView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()

        backgroundColor = .from(scheme: .contentBackground)
    }

    func setupViews() {
        tableView.register(TextSearchResultCell.self, forCellReuseIdentifier: TextSearchResultCell.reuseIdentifier)
        tableView.estimatedRowHeight = 44
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.backgroundColor = .clear
        addSubview(tableView)

        noResultsView.label.accessibilityLabel = "no text messages"
        noResultsView.label.text = "collections.search.no_items".localized(uppercased: true)
        noResultsView.icon = .search
        addSubview(noResultsView)
    }

    func createConstraints() {
        constrain(self, tableView, noResultsView) { resultsView, tableView, noResultsView in
            tableView.edges == resultsView.edges

            noResultsView.top >= resultsView.top + 12
            noResultsView.bottom <= resultsView.bottom - 12
            noResultsView.center == resultsView.center
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
