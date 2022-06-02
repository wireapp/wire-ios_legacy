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
import WireSyncEngine
import AVFoundation

private let zmLog = ZMSLog(tag: "ConversationInputBarViewController - Image Picker")

extension ConversationInputBarViewController {

    func presentImagePicker(with sourceType: UIImagePickerController.SourceType,
                            mediaTypes: [String],
                            allowsEditing: Bool,
                            pointToView: UIView?) {

        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? PopoverPresenterViewController else { return }

        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            if UIDevice.isSimulator {
                let testFilePath = "/var/tmp/video.mp4"
                if FileManager.default.fileExists(atPath: testFilePath) {
                    uploadFile(at: URL(fileURLWithPath: testFilePath))
                }
            }
            return
            // Don't crash on Simulator
        }

        let presentController = {() -> Void in

            let context = ImagePickerPopoverPresentationContext(presentViewController: rootViewController,
                                                                sourceType: sourceType)

            let pickerController = UIImagePickerController.popoverForIPadRegular(with: context)
            pickerController.delegate = self
            pickerController.allowsEditing = allowsEditing
            pickerController.mediaTypes = mediaTypes
            pickerController.videoMaximumDuration = ZMUserSession.shared()!.maxVideoLength
            pickerController.videoExportPreset = AVURLAsset.defaultVideoQuality

            if let popover = pickerController.popoverPresentationController,
                let imageView = pointToView {
                popover.config(from: rootViewController,
                               pointToView: imageView,
                               sourceView: rootViewController.view)

                popover.backgroundColor = .white
                popover.permittedArrowDirections = .down
            }

            if sourceType == .camera {
                let settingsCamera: SettingsCamera? = Settings.shared[.preferredCamera]
                switch settingsCamera {
                case .back?:
                    pickerController.cameraDevice = .rear
                case .front?, .none:
                    pickerController.cameraDevice = .front
                }
            }

            rootViewController.present(pickerController, animated: true)
        }

        if sourceType == .camera {
            execute(videoPermissions: presentController)
        } else {
            presentController()
        }
    }

    func processVideo(info: [UIImagePickerController.InfoKey: Any],
                      picker: UIImagePickerController) {
        guard let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            parent?.dismiss(animated: true)
            zmLog.error("Video not provided form \(picker): info \(info)")
            return
        }

        let videoTempURL = URL(fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true).appendingPathComponent(String.filenameForSelfUser()).appendingPathExtension(videoURL.pathExtension)

        do {
            try FileManager.default.removeTmpIfNeededAndCopy(fileURL: videoURL, tmpURL: videoTempURL)
        } catch let error {
            zmLog.error("Cannot copy video from \(videoURL) to \(videoTempURL): \(error)")
            return
        }

        if picker.sourceType == UIImagePickerController.SourceType.camera && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoTempURL.path),
           MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared()).hasAccessToCameraRoll {
            UISaveVideoAtPathToSavedPhotosAlbum(videoTempURL.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        }

        AVURLAsset.convertVideoToUploadFormat(at: videoTempURL, fileLengthLimit: Int64(ZMUserSession.shared()!.maxUploadFileSize)) { resultURL, _, error in
            if error == nil,
               let resultURL = resultURL {
                self.uploadFile(at: resultURL)
            }

            self.parent?.dismiss(animated: true)
        }
    }

}
