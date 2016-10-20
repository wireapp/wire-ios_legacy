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

import Foundation
import ZMCSystem
import Cartography

class DeveloperOptionsController : UIViewController {
    
    var allTags : [String]!
    var tableView : UITableView!
}

struct DevOptionsLabelWithSwitch {
    let label : UILabel
    let uiSwitch : UISwitch
    let tag : String
}

extension DeveloperOptionsController {
    
    override func loadView() {
        self.title = "options"
        self.view = UIView()
        self.edgesForExtendedLayout = UIRectEdge()
        self.view.backgroundColor = .clear
        self.allTags = Array(ZMLogGetAllTags()!.map { $0 as! String})
        
        self.tableView = UITableView()
        self.tableView.dataSource = self
        self.tableView.backgroundColor = .clear
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        
        constrain(self.view, self.tableView) { view, tableView in
            tableView.edges == view.edges
        }
    }

}

extension DeveloperOptionsController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let logText = self.allTags[indexPath.row]
        cell.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "Log \(logText)"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)

        constrain(cell.contentView, label) { contentView, label in
            label.centerY == contentView.centerY
            label.left == contentView.left + 20
        }
        
        let `switch` = UISwitch()
        `switch`.translatesAutoresizingMaskIntoConstraints = false
        `switch`.isOn = ZMLogGetLevelForTag(logText) == .debug
        `switch`.tag = indexPath.row
        `switch`.addTarget(self, action: #selector(DeveloperOptionsController.switchLogDidChange(sender:)), for: .valueChanged)
        cell.contentView.addSubview(`switch`)

        constrain(cell.contentView, `switch`, label) { contentView, `switch`, label in
            `switch`.trailing == contentView.trailing - 20
            label.trailing == `switch`.leading
            `switch`.centerY == label.centerY
        }
        
        return cell
    }
    
    func switchLogDidChange(sender: AnyObject) {
        let `switch` = sender as! UISwitch
        let logTag = self.allTags[`switch`.tag]
        let newLevel = `switch`.isOn ? ZMLogLevel_t.debug : ZMLogLevel_t.warn
        ZMLogSetLevelForTag(newLevel, logTag)
    }
}
