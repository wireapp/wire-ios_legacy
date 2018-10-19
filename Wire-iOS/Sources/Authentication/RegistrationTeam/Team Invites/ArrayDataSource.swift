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

final class ArrayDataSource<Cell: UITableViewCell, Data>: NSObject, UITableViewDataSource {
    
    var configure: ((Cell, Data) -> Void)?
    var data: [Data] {
        get { return _data }
        set {
            _data = newValue
            tableView.reloadData()
        }
    }
    
    private unowned let tableView: UITableView
    private var _data = [Data]()
    
    func append(_ element: Data) {
        _data.insert(element, at: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    
    init(for tableView: UITableView) {
        self.tableView = tableView
        super.init()
        tableView.dataSource = self
        Cell.register(in: tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.zm_reuseIdentifier, for: indexPath) as! Cell
        configure?(cell, _data[indexPath.row])
        return cell
    }

}
