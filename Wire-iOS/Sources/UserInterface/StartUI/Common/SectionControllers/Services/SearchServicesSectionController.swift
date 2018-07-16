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

class SearchServicesSectionController: SearchSectionController {
    
    var delegate: SearchSectionControllerDelegate? = nil

    var services: [ServiceUser] = []
    
    override var isHidden: Bool {
        return services.isEmpty
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.services.count
    }
    
    override var sectionTitle: String {
        return "peoplepicker.header.services".localized
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let service = services[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.zm_reuseIdentifier, for: indexPath) as! UserCell
        
        cell.configure(with: service)
        cell.showSeparator = (services.count - 1) != indexPath.row
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let service = services[indexPath.row]
        delegate?.searchSectionController(self, didSelectUser: service, at: indexPath)
    }
    
}
