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


extension UIAlertController {

    static func controllerForDraftDeletion(_ handler: @escaping () -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: "compose.drafts.compose.delete.confirm.title".localized,
            message: "compose.drafts.compose.delete.confirm.message".localized,
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(
            title: "compose.drafts.compose.delete.confirm.action.title".localized,
            style: .destructive,
            handler: { _ in handler() }
        )

        controller.addAction(.cancel())
        controller.addAction(deleteAction)
        return controller
    }
    
    static func controllerForDraftDismiss(deleteHandler: @escaping() -> Void, saveHandler: @escaping() -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let saveAction = UIAlertAction(
            title: "compose.drafts.compose.dismiss.confirm.action.title".localized,
            style: .default,
            handler: { _ in saveHandler() }
        )

        let deleteAction = UIAlertAction(
            title: "compose.drafts.compose.dismiss.delete.action.title".localized,
            style: .destructive,
            handler: { _ in deleteHandler() }
        )
        
        controller.addAction(.cancel())
        controller.addAction(saveAction)
        controller.addAction(deleteAction)
        return controller
    }

}

extension UIAlertAction {

    static func cancel() -> UIAlertAction {
        return UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil)
    }

}
