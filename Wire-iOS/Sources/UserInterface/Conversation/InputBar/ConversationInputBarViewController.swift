
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import MobileCoreServices

extension ConversationInputBarViewController {
    @objc
    func postImage(_ image: MediaAsset) {
        sendController.sendMessage(withImageData: image.data())
    }
    
    ///TODO: chnage to didSet after ConversationInputBarViewController is converted to Swift
    @objc
    func asssignInputController(_ inputController: UIViewController?) {
        self.inputController?.view.removeFromSuperview()
        
        self.inputController = inputController
        deallocateUnusedInputControllers()
        
        
        if let inputController = inputController {
            let inputViewSize = UIView.wr_lastKeyboardSize
            
            let inputViewFrame: CGRect = CGRect(origin: .zero, size: inputViewSize)
            let inputView = UIInputView(frame: inputViewFrame, inputViewStyle: .keyboard)
            inputView.allowsSelfSizing = true
            
            inputView.autoresizingMask = .flexibleWidth
            inputController.view.frame = inputView.frame
            inputController.view.autoresizingMask = .flexibleWidth
            if let view = inputController.view {
                inputView.addSubview(view)
            }
            
            inputBar.textView.inputView = inputView
        } else {
            inputBar.textView.inputView = nil
        }
        
        inputBar.textView.reloadInputViews()
    }

    func deallocateUnusedInputControllers() {
        if cameraKeyboardViewController != inputController {
            cameraKeyboardViewController = nil
        }
        if audioRecordKeyboardViewController != inputController {
            audioRecordKeyboardViewController = nil
        }
        if ephemeralKeyboardViewController != inputController {
            ephemeralKeyboardViewController = nil
        }
    }

}

//MARK: - GiphySearchViewControllerDelegate

extension ConversationInputBarViewController: GiphySearchViewControllerDelegate {
    func giphySearchViewController(_ giphySearchViewController: GiphySearchViewController, didSelectImageData imageData: Data, searchTerm: String) {
        clearInputBar()
        dismiss(animated: true) {
            let messageText: String
            
            if (searchTerm == "") {
                messageText = String(format: "giphy.conversation.random_message".localized, searchTerm)
            } else {
                messageText = String(format: "giphy.conversation.message".localized, searchTerm)
            }
            
            self.sendController.sendTextMessage(messageText, mentions: [], withImageData: imageData)
        }
    }
}

//MARK: - UIImagePickerControllerDelegate

extension ConversationInputBarViewController: UIImagePickerControllerDelegate {
    
    ///TODO: check this is still necessary on iOS 13?
    private func statusBarBlinksRedFix() {
        // Workaround http://stackoverflow.com/questions/26651355/
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        statusBarBlinksRedFix()
        
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String
        
        if mediaType == kUTTypeMovie as String {
            processVideo(info: info, picker: picker)
        } else if mediaType == kUTTypeImage as String {
            let image: UIImage? = (info[UIImagePickerController.InfoKey.editedImage] as? UIImage) ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            
            if let image = image, let jpegData = image.jpegData(compressionQuality: 0.9) {
                if picker.sourceType == UIImagePickerController.SourceType.camera {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    // In case of picking from the camera, the iOS controller is showing it's own confirmation screen.
                    parent?.dismiss(animated: true) {
                        self.sendController.sendMessage(withImageData: jpegData, completion: nil)
                    }
                } else {
                    parent?.dismiss(animated: true) {
                        self.showConfirmationForImage(jpegData, isFromCamera: false, uti: mediaType)
                    }
                }

            }
        } else {
            parent?.dismiss(animated: true)
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        statusBarBlinksRedFix()
        
        parent?.dismiss(animated: true) {
            
            if self.shouldRefocusKeyboardAfterImagePickerDismiss {
                self.shouldRefocusKeyboardAfterImagePickerDismiss = false
                self.mode = .camera
                self.inputBar.textView.becomeFirstResponder()
            }
        }
    }
}
