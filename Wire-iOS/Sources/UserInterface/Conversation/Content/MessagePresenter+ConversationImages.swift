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
import Classy

extension MessagePresenter {
    func imagesViewController(for message: ZMConversationMessage, actionResponder: MessageActionResponder) -> UIViewController {
        
        guard let conversation = message.conversation else {
            fatal("Message \(message) has no conversation.")
        }
        
        let imagesCategoryMatch = CategoryMatch(including: .image, excluding: .none)
        
        let collection = AssetCollectionWrapper(conversation: conversation, matchingCategories: [imagesCategoryMatch])
        
        let imagesController = ConversationImagesViewController(collection: collection, initialMessage: message, inverse: true)
        
        if (UIDevice.current.userInterfaceIdiom == .phone) {
            imagesController.modalPresentationStyle = .fullScreen;
            imagesController.snapshotBackgroundView = UIScreen.main.snapshotView(afterScreenUpdates: true)
        } else {
            imagesController.modalPresentationStyle = .overFullScreen
        }
        imagesController.modalTransitionStyle = .crossDissolve

        CASStyler.default().styleItem(imagesController)

        let closeButton = CollectionsView.closeButton()
        closeButton.addTarget(self, action: #selector(MessagePresenter.closeImagesButtonPressed(_:)), for: .touchUpInside)
        
        imagesController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
        imagesController.messageActionDelegate = actionResponder
        imagesController.swipeToDismiss = true
        imagesController.dismissAction = { [weak self] completion in
            guard let `self` = self else {
                return
            }
            self.modalTargetController?.dismiss(animated: true, completion: completion)
        }
        return imagesController.wrapInNavigationController()
    }
    
    @objc func closeImagesButtonPressed(_ sender: AnyObject!) {
        self.modalTargetController?.dismiss(animated: true, completion: .none)
    }
}
