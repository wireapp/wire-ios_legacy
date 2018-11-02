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

/**
 * A view that displays the contents of a.
 */

class ConversationMessageSectionView: UIView, UITableViewDataSource, UITableViewDelegate {

    let section: ConversationMessageSectionController
    let tableView = UITableView()
    let isPreviewing: Bool

    init(section: ConversationMessageSectionController, isPreviewing: Bool) {
        self.section = section
        self.isPreviewing = isPreviewing
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        tableView.separatorStyle = .none

        tableView.dataSource = self
        tableView.delegate = self
        section.cellDescriptions.forEach { $0.register(in: tableView) }

        tableView.backgroundColor = .contentBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(tableView)
    }

    private func configureConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.fitInSuperview()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: tableView.frame.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.reloadData()
    }

    // MARK: - Data Soure

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.section.numberOfCells
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.section.makeCell(for: tableView, at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cell = tableView.cellForRow(at: indexPath) {
            if isPreviewing {
                return cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            } else {
                return cell.systemLayoutSizeFitting(CGSize(width: 0, height: tableView.frame.height)).height
            }
        } else {
            return 0
        }

    }

}
