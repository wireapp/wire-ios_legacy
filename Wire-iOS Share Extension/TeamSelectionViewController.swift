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
import WireExtensionComponents
import WireShareEngine

private let cellReuseIdentifier = "TeamCell"

class TeamSelectionViewController : UITableViewController {
    
    fileprivate var allTeams : [Team]
    
    var selectionHandler : ((_ team: Team?) -> Void)?
    
    init(teams: [Team]) {
        allTeams = teams
        
        super.init(style: .plain)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        preferredContentSize = UIScreen.main.bounds.size
        definesPresentationContext = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTeams.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "share_extension.team_selection.personal.team.name".localized
        } else {
            let team = allTeams[indexPath.row - 1]
            cell.textLabel?.text = team.name
        }
        cell.backgroundColor = .clear
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectionHandler = selectionHandler {
            let team: Team? = (indexPath.row == 0) ? nil : allTeams[indexPath.row - 1]
            selectionHandler(team)
        }
    }
}
