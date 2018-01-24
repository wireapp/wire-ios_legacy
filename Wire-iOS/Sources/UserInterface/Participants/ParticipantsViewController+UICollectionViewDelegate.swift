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

        var viewContollerToPush: UIViewController?

        if user.isServiceUser {
            let confirmButton = Button(style: .full)
            confirmButton.setTitle("participants.services.remove_integration.button".localized, for: .normal)
            confirmButton.setBackgroundImageColor(.red, for: .normal)
            let serviceDetail = ServiceDetailViewController(serviceUser: user,
                                                            backgroundColor: self.view.backgroundColor,
                                                            textColor: .black, ///FIXME: ask for design
                confirmButton: confirmButton)

            ///TODO: inject a remove block
            //            public var completion: ((ZMConversation?)->())? = nil // TODO: not wired up yet
            //            serviceDetail.completion = {(_ conversation: ZMConversation) -> () in
            ///TODO: remove from conversation
            //            }

            serviceDetail.navigationControllerDelegate = navigationControllerDelegate
            viewContollerToPush = serviceDetail
        } else {
            let profileViewController = ProfileViewController(user: user, conversation: conversation)
            profileViewController?.delegate = self
            profileViewController?.navigationControllerDelegate = navigationControllerDelegate
            viewContollerToPush = profileViewController
        }

        if let layoutAttributes: UICollectionViewLayoutAttributes = collectionView.layoutAttributesForItem(at: indexPath) {
            navigationControllerDelegate.tapLocation = collectionView.convert(layoutAttributes.center, to: view)
        }

        if let viewContollerToPush = viewContollerToPush {
            navigationController?.pushViewController(viewContollerToPush, animated: true)
        }
    }
}

