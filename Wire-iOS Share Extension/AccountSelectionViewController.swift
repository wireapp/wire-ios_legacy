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

import UIKit
import WireCommonComponents
import WireShareEngine
import WireDataModel

private let cellReuseIdentifier = "AccountCell"

class AccountSelectionViewController: UITableViewController {

    fileprivate var accounts: [Account]
    fileprivate var current: Account?

    var selectionHandler : ((_ account: Account) -> Void)?

    init(accounts: [Account], current: Account?) {
        self.accounts = accounts

        super.init(style: .plain)

        self.current = current

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        definesPresentationContext = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let account = accounts[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)

        cell.textLabel?.text = account.userName
        cell.detailTextLabel?.text = account.teamName
        cell.backgroundColor = .clear
        cell.accessoryType = (account == current) ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let selectionHandler = selectionHandler {
            selectionHandler(accounts[indexPath.row])
        }
    }
}
