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
import WireDataModel
import UIKit

extension MessagePresenter {

    /// return a view controller for viewing image messge
    ///
    /// - Parameters:
    ///   - message: a message with image data
    ///   - actionResponder: a action responder
    ///   - isPreviewing: is peeking with 3D touch?
    /// - Returns: if isPreviewing, return a ConversationImagesViewController otherwise return a the view wrapped in navigation controller
    func imagesViewController(for message: ZMConversationMessage,
                              actionResponder: MessageActionResponder,
                              isPreviewing: Bool) -> UIViewController {

        guard let conversation = message.conversationLike else {
            fatal("Message has no conversation.")
        }

        guard let imageSize = message.imageMessageData?.originalSize else {
            fatal("Image in message has no size.")
        }

        let imagesCategoryMatch = CategoryMatch(including: .image, excluding: .none)

        let collection = AssetCollectionWrapper(conversation: conversation,
                                                matchingCategories: [imagesCategoryMatch])

        let imagesController = ConversationImagesViewController(collection: collection, initialMessage: message, inverse: true)
        imagesController.isPreviewing = isPreviewing

        // preferredContentSize should not excess view's size
        if isPreviewing {
            let ratio = UIScreen.main.bounds.size.minZoom(imageSize: imageSize)
            let preferredContentSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)

            imagesController.preferredContentSize = preferredContentSize
        }

        if UIDevice.current.userInterfaceIdiom == .phone {
            imagesController.modalPresentationStyle = .fullScreen
            imagesController.snapshotBackgroundView = UIScreen.main.snapshotView(afterScreenUpdates: true)
        } else {
            imagesController.modalPresentationStyle = .overFullScreen
        }
        imagesController.modalTransitionStyle = .crossDissolve

        let closeButton = CollectionsView.closeButton()
        closeButton.addTarget(self, action: #selector(MessagePresenter.closeImagesButtonPressed(_:)), for: .touchUpInside)

        imagesController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
        imagesController.messageActionDelegate = actionResponder
        imagesController.swipeToDismiss = true
        imagesController.dismissAction = { [weak self] completion in
            self?.modalTargetController?.dismiss(animated: true, completion: completion)
        }

        return isPreviewing ? imagesController : imagesController.wrapInNavigationController(navigationBarClass: UINavigationBar.self)
    }

    @objc
    private func closeImagesButtonPressed(_ sender: AnyObject!) {
        modalTargetController?.dismiss(animated: true)
    }
}
