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

import MobileCoreServices
import WireSyncEngine

extension ConversationInputBarViewController: UIDocumentPickerDelegate {

    @available(iOS 11.0, *)
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        uploadFiles(at: urls)
    }

    @available(iOS, introduced: 8.0, deprecated: 11.0, message: "Implement documentPicker:didPickDocumentsAtURLs: instead")
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        uploadItem(at: url)
    }

}

extension ConversationInputBarViewController {

    func configPopover(docController: UIDocumentPickerViewController,
                       sourceView: UIView,
                       delegate: UIPopoverPresentationControllerDelegate,
                       pointToView: UIView) {

        guard let popover = docController.popoverPresentationController else { return }

        popover.delegate = delegate
        popover.config(from: self, pointToView: pointToView, sourceView: sourceView)

        popover.permittedArrowDirections = .down
    }

    func createDocUploadActionSheet(sender: IconButton? = nil) -> UIAlertController {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        /// alert actions  for debugging
        #if targetEnvironment(simulator)
        let plistHandler: ((UIAlertAction) -> Void) = { _ in
            ZMUserSession.shared()?.enqueue({
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                guard let basePath = paths.first,
                    let sourceLocation = Bundle.main.url(forResource: "CountryCodes", withExtension: "plist") else { return }

                let destLocation = URL(fileURLWithPath: basePath).appendingPathComponent(sourceLocation.lastPathComponent)

                try? FileManager.default.copyItem(at: sourceLocation, to: destLocation)
                self.uploadFile(at: destLocation)
            })
        }

        controller.addAction(UIAlertAction(title: "CountryCodes.plist",
                                           style: .default,
                                           handler: plistHandler))

        let size = UInt(ZMUserSession.shared()?.maxUploadFileSize ?? 0) + 1
        let humanReadableSize = size / 1024 / 1024
        controller.addAction(uploadTestAlertAction(size: size, title: "Big file (size = \(humanReadableSize) MB)", fileName: "BigFile.bin"))

        controller.addAction(uploadTestAlertAction(size: 20971520, title: "20 MB file", fileName: "20MBFile.bin"))
        controller.addAction(uploadTestAlertAction(size: 41943040, title: "40 MB file", fileName: "40MBFile.bin"))

        if ZMUser.selfUser()?.hasTeam == true {
            controller.addAction(uploadTestAlertAction(size: 83886080, title: "80 MB file", fileName: "80MBFile.bin"))
            controller.addAction(uploadTestAlertAction(size: 125829120, title: "120 MB file", fileName: "120MBFile.bin"))
        }
        #endif

        let uploadVideoHandler: ((UIAlertAction) -> Void) = { _ in
            self.presentImagePicker(with: .photoLibrary,
                                    mediaTypes: [kUTTypeMovie as String], allowsEditing: true,
                                    pointToView: self.videoButton.imageView)
        }

        controller.addAction(UIAlertAction(icon: .movie,
                                           title: "content.file.upload_video".localized,
                                           tintColor: view.tintColor,
                                           handler: uploadVideoHandler))

        let takeVideoHandler: ((UIAlertAction) -> Void) = { _ in
            self.recordVideo()
        }

        controller.addAction(UIAlertAction(icon: .cameraShutter,
                                           title: "content.file.take_video".localized,
                                           tintColor: view.tintColor,
                                           handler: takeVideoHandler))

        let browseHandler: ((UIAlertAction) -> Void) = { _ in
            let documentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
            documentPickerViewController.modalPresentationStyle = self.isIPadRegular() ? .popover : .fullScreen
            if self.isIPadRegular(),
                let sourceView = self.parent?.view,
                let pointToView = sender?.imageView {
                self.configPopover(docController: documentPickerViewController, sourceView: sourceView, delegate: self, pointToView: pointToView)
            }

            documentPickerViewController.delegate = self

            if #available(iOS 11.0, *) {
                documentPickerViewController.allowsMultipleSelection = true
            }

            self.parent?.present(documentPickerViewController, animated: true)
        }

        controller.addAction(UIAlertAction(icon: .ellipsis,
                                           title: "content.file.browse".localized, tintColor: view.tintColor,
                                           handler: browseHandler))

        controller.addAction(.cancel())

        controller.configPopover(pointToView: sender ?? view)
        return controller
    }

    @objc
    func docUploadPressed(_ sender: IconButton) {
        mode = ConversationInputBarViewControllerMode.textInput
        inputBar.textView.resignFirstResponder()

        let controller = createDocUploadActionSheet(sender: sender)

        present(controller, animated: true)
    }

    @objc
    func videoButtonPressed(_ sender: IconButton) {
        recordVideo()
    }

    private func recordVideo() {
        guard !CameraAccess.displayAlertIfOngoingCall(at: .recordVideo, from: self) else { return }

        presentImagePicker(with: .camera, mediaTypes: [kUTTypeMovie as String], allowsEditing: false, pointToView: videoButton.imageView)
    }

    #if targetEnvironment(simulator)
    private func uploadTestAlertAction(size: UInt, title: String, fileName: String) -> UIAlertAction {
        return UIAlertAction(title: title, style: .default, handler: {_ in
            ZMUserSession.shared()?.enqueue({
                let randomData = Data.secureRandomData(length: UInt(size))

                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = dir.appendingPathComponent(fileName)
                    try? randomData.write(to: fileURL)

                    self.uploadFile(at: fileURL)
                }
            })
        })
    }
    #endif
}
