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
import UIKit
import WireDataModel

protocol SearchServicesSectionDelegate: SearchSectionControllerDelegate {
    func addServicesSectionDidRequestOpenServicesAdmin()
}

final class SearchServicesSectionController: SearchSectionController {
    
    weak var delegate: SearchServicesSectionDelegate? = nil

    var services: [ServiceUser] = []

    let canSelfUserManageTeam: Bool

    init(canSelfUserManageTeam: Bool) {
        self.canSelfUserManageTeam = canSelfUserManageTeam
        super.init()
    }
    
    override var isHidden: Bool {
        return services.isEmpty
    }
    
    override func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(OpenServicesAdminCell.self, forCellWithReuseIdentifier: OpenServicesAdminCell.zm_reuseIdentifier)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if canSelfUserManageTeam {
            return services.count + 1
        }
        else {
            return services.count
        }
    }
    
    override var sectionTitle: String {
        return "peoplepicker.header.services".localized
    }
    
    func service(for indexPath: IndexPath) -> ServiceUser {
        if canSelfUserManageTeam {
            return services[indexPath.row - 1]
        }
        else {
            return services[indexPath.row]
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if canSelfUserManageTeam && indexPath.row == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: OpenServicesAdminCell.zm_reuseIdentifier, for: indexPath)
        }
        else {
            let service = self.service(for: indexPath)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.zm_reuseIdentifier, for: indexPath) as! UserCell
            
            cell.configure(with: service, selfUser: ZMUser.selfUser())
            cell.accessoryIconView.isHidden = false
            cell.showSeparator = (services.count - 1) != indexPath.row
            
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if canSelfUserManageTeam && indexPath.row == 0 {
            delegate?.addServicesSectionDidRequestOpenServicesAdmin()
        }
        else {
            let service = self.service(for: indexPath)
            delegate?.searchSectionController(self, didSelectUser: service, at: indexPath)
        }
    }
    
}
