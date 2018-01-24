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

extension ParticipantsViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard headerView?.titleView.isFirstResponder == false else {
            headerView?.titleView.resignFirstResponder()
            return
        }
        guard let user: ZMUser = participants[indexPath.row] as? ZMUser else { return }

        ///TODO: new VC for server user, a ServiceDetailViewController with a remove button
        var viewContollerToPush: UIViewController?

        if user.isServiceUser {
            ///TODO: inject a remove btn
            let serviceDetail = ServiceDetailViewController(serviceUser: user)
//            public var completion: ((ZMConversation?)->())? = nil // TODO: not wired up yet
//            serviceDetail.completion = {(_ conversation: ZMConversation) -> () in
                ///TODO: remove from conversation
//            }
            viewContollerToPush = serviceDetail
        } else {
            let profileViewController = ProfileViewController(user: user, conversation: conversation)
            profileViewController?.delegate = self
            profileViewController?.navigationControllerDelegate = navigationControllerDelegate
            viewContollerToPush = profileViewController
        }

        let layoutAttributes: UICollectionViewLayoutAttributes? = collectionView.layoutAttributesForItem(at: indexPath)
        navigationControllerDelegate.tapLocation = collectionView.convert(layoutAttributes?.center ?? CGPoint.zero, to: view)

        if let viewContollerToPush = viewContollerToPush {
        navigationController?.pushViewController(viewContollerToPush, animated: true)
        }
    }
}

