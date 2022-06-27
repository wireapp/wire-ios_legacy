//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ConversationViewController: UIPopoverPresentationControllerDelegate {

    func createAndPresentParticipantsPopoverController(with rect: CGRect,
                                                       from view: UIView,
                                                       contentViewController controller: UIViewController) {
        endEditing()

        controller.presentationController?.delegate = self
        present(controller, animated: true)
    }
}

extension ConversationViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        if controller.presentedViewController is AddParticipantsViewController {
            return .overFullScreen
        }

        return .formSheet
    }
}

extension ConversationViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> Void)?) {
        dismiss(animated: true, completion: completion)
    }
}
