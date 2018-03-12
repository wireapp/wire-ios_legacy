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

import Foundation

class DirectorySectionController: SearchSectionController {
    
    var suggestions: [ZMSearchUser] = []
    var delegate: SearchSectionControllerDelegate? = nil
    var token: AnyObject? = nil
    weak var collectionView: UICollectionView? = nil
    
    override var isHidden: Bool {
        return self.suggestions.isEmpty
    }
    
    override var sectionTitle: String {
        return "peoplepicker.header.directory".localized
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)
        
        self.token = UserChangeInfo.add(searchUserObserver: self, for: nil, userSession: ZMUserSession.shared()!)
        
        self.collectionView = collectionView
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = suggestions[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.zm_reuseIdentifier, for: indexPath) as! UserCell
        
        cell.configure(with: user)
        cell.separator.isHidden = (suggestions.count - 1) == indexPath.row
        cell.guestIconView.isHidden = true
        cell.accessoryIconView.isHidden = true
        cell.connectButton.isHidden = false
        cell.connectButton.tag = indexPath.row
        cell.connectButton.addTarget(self, action: #selector(connect(_:)), for: .touchUpInside)
        
        return cell
    }
    
    func connect(_ sender: AnyObject) {
        guard let button = sender as? UIButton else { return }
        
        let indexPath = IndexPath(row: button.tag, section: 0)
        let user = suggestions[indexPath.row]
        
        ZMUserSession.shared()?.enqueueChanges {
            let messageText = "missive.connection_request.default_message".localized(args: user.displayName, ZMUser.selfUser().name)
            user.connect(withMessageText: messageText, completionHandler: {
                Analytics.shared().tagEventObject(AnalyticsConnectionRequestEvent(forAddContactMethod: .userSearch, connectRequestCount: 1))
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = suggestions[indexPath.row]
        delegate?.searchSectionController(self, didSelectUser: user, at: indexPath)
    }
    
}

extension DirectorySectionController: ZMUserObserver {
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged else { return }
        
        collectionView?.reloadData()
    }
    
}
