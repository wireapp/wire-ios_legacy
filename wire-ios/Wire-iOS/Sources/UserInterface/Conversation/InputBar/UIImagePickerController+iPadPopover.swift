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
import UIKit

struct ImagePickerPopoverPresentationContext {
    let presentViewController: UIViewController
    let sourceType: UIImagePickerController.SourceType
}

extension UIImagePickerController {
    class func popoverForIPadRegular(with context: ImagePickerPopoverPresentationContext) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = context.sourceType
        picker.preferredContentSize = CGSize.IPadPopover.preferredContentSize

        if context.presentViewController.isIPadRegular(device: UIDevice.current) {

            picker.modalPresentationStyle = .popover
        }

        return picker
    }
}
