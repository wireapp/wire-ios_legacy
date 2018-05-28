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

extension ConversationInputBarViewController {
    var popoverSourceRectFromPhotoButton: CGRect {
        let sourceView: UIView = self.parent?.view ?? self.view
        let buttonCenter = self.photoButton.convert(self.photoButton.center, to: sourceView)
        let sourceRect = CGRect(origin: buttonCenter, size: .zero)

        return sourceRect
    }

    @objc(presentImagePickerWithSourceType:mediaTypes:allowsEditing:)
    func presentImagePicker(with sourceType: UIImagePickerControllerSourceType,
                                  mediaTypes: [String],
                                  allowsEditing: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            #if TARGET_OS_SIMULATOR
            let testFilePath = "/var/tmp/video.mp4"
            if FileManager.default.fileExists(atPath: testFilePath) {
                uploadFile(at: URL(fileURLWithPath: testFilePath))
            }
            #endif
            return
            // Don't crash on Simulator
        }

        let presentController = {() -> Void in

            let sourceView: UIView = self.parent?.view ?? self.view

            let context = ImagePickerPopoverPresentationContext(sourceRect:self.popoverSourceRectFromPhotoButton,
                                                    sourceView: sourceView,
                                                    presentViewController: self,
                                                    sourceType: .photoLibrary)

            let pickerController = UIImagePickerController.popoverForIPadRegular(with: context)
            pickerController.delegate = self
            pickerController.allowsEditing = allowsEditing
            pickerController.mediaTypes = mediaTypes
            pickerController.videoMaximumDuration = TimeInterval(ConversationUploadMaxVideoDuration)
            pickerController.preferredContentSize = sourceView.frame.size


            if sourceType == .camera {
                switch Settings.shared().preferredCamera {
                case .back:
                    pickerController.cameraDevice = .rear
                case .front:
                    pickerController.cameraDevice = .front
                }
            }

            self.parent?.present(pickerController, animated: true)
        }

        if sourceType == .camera {
            execute(videoPermissions: presentController)
        } else {
            presentController()
        }
    }
}
