//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Photos
import CocoaLumberjackSwift



@objc class FastTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let sharedDelegate = FastTransitioningDelegate()
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return VerticalTransition(offset: -180)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return VerticalTransition(offset: 180)
    }
}


class StatusBarVideoEditorController: UIVideoEditorController {
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
}

extension ConversationInputBarViewController: CameraKeyboardViewControllerDelegate {
    
    @objc public func createCameraKeyboardViewController() {
        let cameraKeyboardViewController = CameraKeyboardViewController(splitLayoutObservable: ZClientViewController.shared().splitViewController)
        cameraKeyboardViewController.delegate = self
        
        self.cameraKeyboardViewController = cameraKeyboardViewController
    }
    
    public func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo videoURL: URL, duration: TimeInterval) {
        // Video can be longer than allowed to be uploaded. Then we need to add user the possibility to trim it.
        if duration > ConversationUploadMaxVideoDuration {
            let videoEditor = StatusBarVideoEditorController()
            videoEditor.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
            videoEditor.delegate = self
            videoEditor.videoMaximumDuration = ConversationUploadMaxVideoDuration
            videoEditor.videoPath = videoURL.path
            videoEditor.videoQuality = UIImagePickerControllerQualityType.typeMedium
            
            self.present(videoEditor, animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(false)
            }
        }
        else {

            let confirmVideoViewController = ConfirmAssetViewController()
            confirmVideoViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
            confirmVideoViewController.videoURL = videoURL as URL!
            confirmVideoViewController.previewTitle = self.conversation.displayName.uppercased()
            confirmVideoViewController.isEditButtonVisible = false
            confirmVideoViewController.onConfirm = { [unowned self] in
                self.dismiss(animated: true, completion: .none)
                Analytics.shared()?.tagSentVideoMessage(inConversation: self.conversation, context: .cameraKeyboard, duration: duration)
                self.uploadFile(at: videoURL as URL!)
            }
            
            confirmVideoViewController.onCancel = { [unowned self] in
                self.dismiss(animated: true) {
                    self.mode = .camera
                    self.inputBar.textView.becomeFirstResponder()
                }
            }
            
            
            self.present(confirmVideoViewController, animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            }
        }
    }
    
    public func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData imageData: Data, metadata: ImageMetadata) {
        self.showConfirmationForImage(imageData as Data, metadata: metadata)
    }
    
    @objc fileprivate func image(_ image: UIImage?, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if let error = error {
            DDLogError("didFinishSavingWithError: \(error)")
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.shouldRefocusKeyboardAfterImagePickerDismiss = true
            self.videoSendContext = ConversationMediaVideoContext.fullCameraKeyboard.rawValue
            self.presentImagePicker(with: .camera, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String], allowsEditing: false)
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.shouldRefocusKeyboardAfterImagePickerDismiss = true
            self.presentImagePicker(with: .photoLibrary, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String], allowsEditing: false)
        }
    }
    
    @objc public func showConfirmationForImage(_ imageData: NSData, metadata: ImageMetadata) {
        let image = UIImage(data: imageData as Data)
        
        let confirmImageViewController = ConfirmAssetViewController()
        confirmImageViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
        confirmImageViewController.image = image
        confirmImageViewController.previewTitle = self.conversation.displayName.uppercased()
        confirmImageViewController.isEditButtonVisible = true
        confirmImageViewController.onConfirm = { [unowned self] in
            self.dismiss(animated: true, completion: .none)
            
            Analytics.shared()?.tagMediaSentPicture(inConversation: self.conversation, metadata: metadata)
                
            self.sendController.sendMessage(withImageData: imageData as Data!, completion: .none)
            if metadata.source == .camera {
                let selector = #selector(ConversationInputBarViewController.image(_:didFinishSavingWithError:contextInfo:))
                UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData as Data)!, self, selector, nil)
            }
        }
        
        confirmImageViewController.onCancel = { [unowned self] in
            self.dismiss(animated: true) {
                self.mode = .camera
                self.inputBar.textView.becomeFirstResponder()
            }
        }
        
        confirmImageViewController.onEdit = { [unowned self] in
            self.dismiss(animated: true) {
                delay(0.01){
                    self.hideCameraKeyboardViewController {
                        let sketchViewController = SketchViewController()
                        sketchViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
                        sketchViewController.sketchTitle = "image.edit_image".localized
                        sketchViewController.delegate = self
                        sketchViewController.confirmsWithoutSketch = true
                        sketchViewController.source = .cameraGallery
                        
                        self.present(sketchViewController, animated: true, completion: .none)
                        sketchViewController.canvasBackgroundImage = image
                    }
                }
            }
        }
        
        self.present(confirmImageViewController, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    @objc public func executeWithCameraRollPermission(_ closure: @escaping (_ success: Bool)->()) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
            switch status {
            case .authorized:
                closure(true)
            default:
                closure(false)
                break
            }
            }
        }
    }
    
    public func convertVideoAtPath(_ inputPath: String, completion: @escaping (_ success: Bool, _ resultPath: String?, _ duration: TimeInterval)->()) {
        var filename: String?
        
        let lastPathComponent = (inputPath as NSString).lastPathComponent
        filename = ((lastPathComponent as NSString).deletingPathExtension as NSString).appendingPathExtension("mp4")
        
        if filename == .none {
            filename = "video.mp4"
        }
        
        let videoURLAsset = AVURLAsset(url: NSURL(fileURLWithPath: inputPath) as URL)
        
        videoURLAsset.wr_convert(completion: { URL, videoAsset, error in
            guard let resultURL = URL, error == .none else {
                completion(false, .none, 0)
                return
            }
            completion(true, resultURL.path, CMTimeGetSeconds((videoAsset?.duration)!))
            
            }, filename: filename)
    }
}

extension ConversationInputBarViewController: UIVideoEditorControllerDelegate {
    public func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        editor.dismiss(animated: true, completion: .none)
    }
    
    public func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        editor.dismiss(animated: true, completion: .none)
        
        editor.showLoadingView = true

        self.convertVideoAtPath(editedVideoPath) { (success, resultPath, duration) in
            editor.showLoadingView = false

            guard let path = resultPath , success else {
                return
            }
            
            Analytics.shared()?.tagSentVideoMessage(inConversation: self.conversation, context: .cameraKeyboard, duration: duration)
            self.uploadFile(at: NSURL(fileURLWithPath: path) as URL!)
        }
    }
    
    @nonobjc public func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: NSError) {
        editor.dismiss(animated: true, completion: .none)
        DDLogError("Video editor failed with error: \(error)")
    }
}
