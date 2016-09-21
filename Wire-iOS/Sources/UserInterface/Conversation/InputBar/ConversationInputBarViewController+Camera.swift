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
        let cameraKeyboardViewController = CameraKeyboardViewController(splitLayoutObservable: ZClientViewController.sharedZClientViewController().splitViewController)
        cameraKeyboardViewController.delegate = self
        
        self.cameraKeyboardViewController = cameraKeyboardViewController
    }
    
    public func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo videoURL: NSURL, duration: TimeInterval) {
        // Video can be longer than allowed to be uploaded. Then we need to add user the possibility to trim it.
        if duration > ConversationUploadMaxVideoDuration {
            let videoEditor = StatusBarVideoEditorController()
            videoEditor.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
            videoEditor.delegate = self
            videoEditor.videoMaximumDuration = ConversationUploadMaxVideoDuration
            videoEditor.videoPath = videoURL.path!
            videoEditor.videoQuality = UIImagePickerControllerQualityType.typeMedium
            
            self.presentViewController(videoEditor, animated: true) {
                UIApplication.sharedApplication().wr_updateStatusBarForCurrentControllerAnimated(false)
            }
        }
        else {

            let confirmVideoViewController = ConfirmAssetViewController()
            confirmVideoViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
            confirmVideoViewController.videoURL = videoURL
            confirmVideoViewController.previewTitle = self.conversation.displayName.uppercaseString
            confirmVideoViewController.editButtonVisible = false
            confirmVideoViewController.onConfirm = { [unowned self] in
                self.dismissViewControllerAnimated(true, completion: .None)
                Analytics.shared()?.tagSentVideoMessage(inConversation: self.conversation, context: .CameraKeyboard, duration: duration)
                self.uploadFileAtURL(videoURL)
            }
            
            confirmVideoViewController.onCancel = { [unowned self] in
                self.dismissViewControllerAnimated(true) {
                    self.mode = .Camera
                    self.inputBar.textView.becomeFirstResponder()
                }
            }
            
            
            self.presentViewController(confirmVideoViewController, animated: true) {
                UIApplication.sharedApplication().wr_updateStatusBarForCurrentControllerAnimated(true)
            }
        }
    }
    
    public func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData imageData: NSData, metadata: ImageMetadata) {
        self.showConfirmationForImage(imageData, metadata: metadata)
    }
    
    @objc fileprivate func image(_ image: UIImage?, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if let error = error {
            DDLogError("didFinishSavingWithError: \(error)")
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.shouldRefocusKeyboardAfterImagePickerDismiss = true
            self.videoSendContext = ConversationMediaVideoContext.FullCameraKeyboard.rawValue
            self.presentImagePickerWithSourceType(.Camera, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String], allowsEditing: false)
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.shouldRefocusKeyboardAfterImagePickerDismiss = true
            self.presentImagePickerWithSourceType(.PhotoLibrary, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String], allowsEditing: false)
        }
    }
    
    @objc public func showConfirmationForImage(_ imageData: NSData, metadata: ImageMetadata) {
        let image = UIImage(data: imageData as Data)
        
        let confirmImageViewController = ConfirmAssetViewController()
        confirmImageViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
        confirmImageViewController.image = image
        confirmImageViewController.previewTitle = self.conversation.displayName.uppercaseString
        confirmImageViewController.editButtonVisible = true
        confirmImageViewController.onConfirm = { [unowned self] in
            self.dismissViewControllerAnimated(true, completion: .None)
            
            Analytics.shared()?.tagMediaSentPicture(inConversation: self.conversation, metadata: metadata)
                
            self.sendController.sendMessageWithImageData(imageData, completion: .None)
            if metadata.source == .Camera {
                let selector = #selector(ConversationInputBarViewController.image(_:didFinishSavingWithError:contextInfo:))
                UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, self, selector, nil)
            }
        }
        
        confirmImageViewController.onCancel = { [unowned self] in
            self.dismissViewControllerAnimated(true) {
                self.mode = .Camera
                self.inputBar.textView.becomeFirstResponder()
            }
        }
        
        confirmImageViewController.onEdit = { [unowned self] in
            self.dismissViewControllerAnimated(true) {
                delay(0.01){
                    self.hideCameraKeyboardViewController {
                        let sketchViewController = SketchViewController()
                        sketchViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
                        sketchViewController.sketchTitle = "image.edit_image".localized
                        sketchViewController.delegate = self
                        sketchViewController.confirmsWithoutSketch = true
                        sketchViewController.source = .CameraGallery
                        
                        self.presentViewController(sketchViewController, animated: true, completion: .None)
                        sketchViewController.canvasBackgroundImage = image
                    }
                }
            }
        }
        
        self.presentViewController(confirmImageViewController, animated: true) {
            UIApplication.sharedApplication().wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    @objc public func executeWithCameraRollPermission(_ closure: @escaping (_ success: Bool)->()) {
        PHPhotoLibrary.requestAuthorization { status in
            dispatch_get_main_queue().asynchronously(DispatchQueue.main) {
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
        
        videoURLAsset.wr_convertWithCompletion({ URL, videoAsset, error in
            guard let resultURL = URL , error == .None else {
                completion(success: false, resultPath: .None, duration: 0)
                return
            }
            completion(success: true, resultPath: resultURL.path!, duration: CMTimeGetSeconds(videoAsset.duration))
            
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
            
            Analytics.shared()?.tagSentVideoMessage(inConversation: self.conversation, context: .CameraKeyboard, duration: duration)
            self.uploadFileAtURL(NSURL(fileURLWithPath: path))
        }
    }
    
    public func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: NSError) {
        editor.dismiss(animated: true, completion: .none)
        DDLogError("Video editor failed with error: \(error)")
    }
}
