//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


private let cellReuseIdentifier = "ConversationCell"


final class ConversationSelectionViewController : UITableViewController {
    
    fileprivate var allConversations : [Conversation]
    fileprivate var visibleConversations : [Conversation]

    var selectionHandler : ((_ conversation: Conversation) -> Void)?
    
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    init(conversations: [Conversation]) {
        allConversations = conversations
        visibleConversations = conversations
        
        super.init(style: .plain)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(TargetConversationCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.isTranslucent = false

        preferredContentSize = UIScreen.main.bounds.size
        definesPresentationContext = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        let searchBar = searchController.searchBar
        tableView.tableHeaderView = searchBar
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleConversations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let conversation = visibleConversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! TargetConversationCell
        cell.configure(for: conversation)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let selectionHandler = selectionHandler {
            selectionHandler(visibleConversations[indexPath.row])
        }
    }
}

extension ConversationSelectionViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            visibleConversations = allConversations.filter { conversation in
                if let _ = conversation.name.range(of: searchText, options: [.diacriticInsensitive, .caseInsensitive]) {
                    return true
                } else {
                    return false
                }
            }
        } else {
            visibleConversations = allConversations
        }
        tableView.reloadData()
    }
}
