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

// MARK: Cell Registration

extension UITableViewCell {
    @objc static var zm_reuseIdentifier: String {
    	return NSStringFromClass(self) + "_ReuseIdentifier"
    }
    
    @objc static func register(in tableView: UITableView) {
        tableView.register(self, forCellReuseIdentifier: zm_reuseIdentifier)
    }
}

extension UICollectionViewCell {
    @objc static var zm_reuseIdentifier: String {
        return NSStringFromClass(self) + "_ReuseIdentifier"
    }
    
    static func register(in collectionView: UICollectionView) {
        collectionView.register(self, forCellWithReuseIdentifier: zm_reuseIdentifier)
    }
}

// MARK: - Cell Dequeuing

extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(ofType cellType: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: T.zm_reuseIdentifier, for: indexPath) as! T
    }
}

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>(ofType cellType: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: T.zm_reuseIdentifier, for: indexPath) as! T
    }
}
