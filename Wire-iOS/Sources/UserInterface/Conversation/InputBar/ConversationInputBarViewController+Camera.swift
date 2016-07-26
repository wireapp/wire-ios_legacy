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
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return VerticalTransition(offset: -180)
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return VerticalTransition(offset: 180)
    }
}


class StatusBarVideoEditorController: UIVideoEditorController {
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
}

extension ConversationInputBarViewController: CameraKeyboardViewControllerDelegate {
    
    public func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectVideo videoURLAsset: AVURLAsset) {
        // Video can be longer than allowed to be uploaded. Then we need to add user the possibility to trim it.
        if CMTimeGetSeconds(videoURLAsset.duration) > ConversationUploadMaxVideoDuration {
            let videoEditor = StatusBarVideoEditorController()
            videoEditor.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
            videoEditor.delegate = self
            videoEditor.videoMaximumDuration = ConversationUploadMaxVideoDuration
            videoEditor.videoPath = videoURLAsset.URL.path!
            videoEditor.videoQuality = UIImagePickerControllerQualityType.TypeMedium
            
            self.presentViewController(videoEditor, animated: true) {
                UIApplication.sharedApplication().wr_updateStatusBarForCurrentControllerAnimated(false)
            }
        }
        else {
            controller.showLoadingView = true

            self.convertVideoAtPath(videoURLAsset.URL.path!) { (success, resultPath, duration) in
                controller.showLoadingView = false

                guard let path = resultPath where success else {
                    return
                }
                
                let confirmVideoViewController = ConfirmAssetViewController()
                confirmVideoViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
                confirmVideoViewController.videoURL = NSURL(fileURLWithPath: path)
                confirmVideoViewController.previewTitle = self.conversation.displayName.uppercaseString
                confirmVideoViewController.editButtonVisible = false
                confirmVideoViewController.onConfirm = { [unowned self] in
                    self.dismissViewControllerAnimated(true, completion: .None)
                    
                    Analytics.shared()?.tagSentVideoMessage(duration)
                    self.uploadFileAtURL(NSURL(fileURLWithPath: path))
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
    }
    
    public func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectImageData imageData: NSData, source: CameraKeyboardSource) {
        
        let image = UIImage(data: imageData)
        
        let confirmImageViewController = ConfirmAssetViewController()
        confirmImageViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
        confirmImageViewController.image = image
        confirmImageViewController.previewTitle = self.conversation.displayName.uppercaseString
        confirmImageViewController.editButtonVisible = true
        confirmImageViewController.onConfirm = { [unowned self] in
            self.dismissViewControllerAnimated(true, completion: .None)
            
            self.sendController.sendMessageWithImageData(imageData, completion: .None)
            if source == .Camera {
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
                let sketchViewController = SketchViewController()
                sketchViewController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
                sketchViewController.sketchTitle = "image.edit_image".localized
                sketchViewController.delegate = self
                
                self.presentViewController(sketchViewController, animated: true, completion: .None)
                sketchViewController.canvasBackgroundImage = image
            }
        }
        
        self.presentViewController(confirmImageViewController, animated: true) {
            UIApplication.sharedApplication().wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    @objc private func image(image: UIImage?, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if let error = error {
            DDLogError("didFinishSavingWithError: \(error)")
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.shouldRefocusKeyboardAfterImagePickerDismiss = true
            self.presentImagePickerWithSourceType(.Camera, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String], allowsEditing: true)
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenCameraRoll(controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.shouldRefocusKeyboardAfterImagePickerDismiss = true
            self.presentImagePickerWithSourceType(.PhotoLibrary, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String], allowsEditing: true)
        }
    }
    
    @objc public func executeWithCameraRollPermission(closure: ()->()) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .Authorized:
                dispatch_async(dispatch_get_main_queue(), closure)
                
            default:
                // place for .NotDetermined - in this callback status is already determined so should never get here
                break
            }
        }
    }
    
    public func convertVideoAtPath(inputPath: String, completion: (success: Bool, resultPath: String?, duration: NSTimeInterval)->()) {
        var filename: String?
        
        let lastPathComponent = (inputPath as NSString).lastPathComponent
        filename = ((lastPathComponent as NSString).stringByDeletingPathExtension as NSString).stringByAppendingPathExtension("mp4")
        
        if filename == .None {
            filename = "video.mp4"
        }
        
        let videoURLAsset = AVURLAsset(URL: NSURL(fileURLWithPath: inputPath))
        
        videoURLAsset.wr_convertWithCompletion({ URL, videoAsset, error in
            guard let resultURL = URL where error == .None else {
                completion(success: false, resultPath: .None, duration: 0)
                return
            }
            completion(success: true, resultPath: resultURL.path!, duration: CMTimeGetSeconds(videoAsset.duration))
            
            }, filename: filename)
    }
}

extension ConversationInputBarViewController: UIVideoEditorControllerDelegate {
    public func videoEditorControllerDidCancel(editor: UIVideoEditorController) {
        editor.dismissViewControllerAnimated(true, completion: .None)
    }
    
    public func videoEditorController(editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        editor.dismissViewControllerAnimated(true, completion: .None)
        
        editor.showLoadingView = true

        self.convertVideoAtPath(editedVideoPath) { (success, resultPath, duration) in
            editor.showLoadingView = false

            guard let path = resultPath where success else {
                return
            }
            
            Analytics.shared()?.tagSentVideoMessage(duration)
            self.uploadFileAtURL(NSURL(fileURLWithPath: path))
        }
    }
    
    public func videoEditorController(editor: UIVideoEditorController, didFailWithError error: NSError) {
        editor.dismissViewControllerAnimated(true, completion: .None)
        DDLogError("Video editor failed with error: \(error)")
    }
}

extension ConversationInputBarViewController: SketchViewControllerDelegate {
    public func sketchViewController(controller: SketchViewController!, didSketchImage image: UIImage!) {
        controller.dismissViewControllerAnimated(true, completion: .None)

        self.sendController.sendMessageWithImageData(UIImagePNGRepresentation(image), completion: .None)
    }
    
    public func sketchViewControllerDidCancel(controller: SketchViewController!) {
        controller.dismissViewControllerAnimated(true, completion: .None)
    }
}
