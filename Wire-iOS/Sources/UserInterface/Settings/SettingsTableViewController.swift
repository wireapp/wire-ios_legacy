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
import Cartography

class SettingsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let group: SettingsInternalGroupCellDescriptorType
    private var selfUserObserver: AnyObject!
    @objc var dismissAction: ((SettingsTableViewController) -> ())? = .None
    
    var tableView: UITableView?
    
    required init(group: SettingsInternalGroupCellDescriptorType) {
        self.group = group

        super.init(nibName: nil, bundle: nil)
        self.title = group.title
        self.edgesForExtendedLayout = UIRectEdge.None

        self.group.items.flatMap { return $0.cellDescriptors }.forEach {
            if let groupDescriptor = $0 as? SettingsGroupCellDescriptorType {
                groupDescriptor.viewController = self
            }
        }
        
        self.selfUserObserver = ZMUser.addUserObserver(self, forUsers: [ZMUser.selfUser()], inUserSession: ZMUserSession.sharedSession())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError()
    }
    
    override func viewDidLoad() {
        self.createTableView()
        self.createConstraints()
        self.view.backgroundColor = .clearColor()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(SettingsTableViewController.dismissRootNavigation(_:)))
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tableView?.reloadData()
    }
    
    func createTableView() {
        let tableView = UITableView(frame: self.view.bounds, style: self.group.style == .Plain ? .Plain : .Grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor(white: 1, alpha: 0.1)
        tableView.backgroundColor = .clearColor()
        tableView.clipsToBounds = true
        
        let allCellTypes: [SettingsTableCell.Type] = [SettingsTableCell.self, SettingsGroupCell.self, SettingsButtonCell.self, SettingsToggleCell.self, SettingsValueCell.self, SettingsTextCell.self]
        
        for aClass in allCellTypes {
            tableView.registerClass(aClass, forCellReuseIdentifier: aClass.reuseIdentifier)
        }
        self.tableView = tableView
        
        self.view.addSubview(tableView)
    }

    func createConstraints() {
        if let tableView = self.tableView {
            constrain(self.view, tableView) { selfView, aTableView in
                aTableView.left == selfView.left
                aTableView.right == selfView.right
                aTableView.top == selfView.top
                aTableView.bottom == selfView.bottom
            }
        }
    }
    
    func dismissRootNavigation(sender: AnyObject) {
       self.dismissAction?(self)
    }
    
    // MARK: - UITableViewDelegate & UITableViewDelegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.group.visibleItems.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDescriptor = self.group.visibleItems[section]
        return sectionDescriptor.visibleCellDescriptors.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionDescriptor = self.group.visibleItems[indexPath.section]
        let cellDescriptor = sectionDescriptor.visibleCellDescriptors[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier(cellDescriptor.dynamicType.cellType.reuseIdentifier, forIndexPath: indexPath) as? SettingsTableCell {
            cell.descriptor = cellDescriptor
            cell.backgroundColor = tableView.style == .Grouped ? UIColor(white: 0, alpha: 0.1) : UIColor.clearColor()
            cellDescriptor.featureCell(cell)
            return cell
        }
        fatalError("Cannot dequeue cell for index path \(indexPath) and cellDescriptor \(cellDescriptor)")
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sectionDescriptor = self.group.visibleItems[indexPath.section]
        let property = sectionDescriptor.visibleCellDescriptors[indexPath.row]
        
        property.select(.None)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDescriptor = self.group.visibleItems[section]
        return sectionDescriptor.header
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionDescriptor = self.group.visibleItems[section]
        return sectionDescriptor.footer
    }
}

extension SettingsTableViewController: ZMUserObserver {
    func userDidChange(note: UserChangeInfo!) {
        if note.accentColorValueChanged {
            self.tableView?.reloadData()
        }
    }
}
