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

import UIKit

class ConversationTimeoutOptionsViewController: UIViewController {

    fileprivate let conversation: ZMConversation
    fileprivate let items: [ZMConversationMessageDestructionTimeout]
    fileprivate let userSession: ZMUserSession

    private let tableView = UITableView(frame: .zero, style: .grouped)

    // MARK:

    public init(conversation: ZMConversation, items: [ZMConversationMessageDestructionTimeout], userSession: ZMUserSession) {
        self.conversation = conversation
        self.items = items
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorContentBackground)
    }

    private func configureConstraints() {

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

    }

}

// MARK: - Table View

extension ConversationTimeoutOptionsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = item.displayString
        cell.accessoryType = item == conversation.destructionTimeout ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let newTimeout = items[indexPath.row]

        userSession.enqueueChanges {
            self.conversation.updateMessageDestructionTimeout(timeout: newTimeout)
        }

        tableView.reloadData()

    }

}
