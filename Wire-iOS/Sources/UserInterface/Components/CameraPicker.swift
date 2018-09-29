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
import MobileCoreServices
import AssetsLibrary

private let zmLog = ZMSLog(tag: "UI")

enum CameraPickerResult {
    case image(UIImage)
    case video(URL)
}

final public class CameraPicker: NSObject {
    weak var target: UIViewController? = .none
    var didPickResult: ((CameraPickerResult)->())? = .none
    var didPickImage: ((UIImage)->())? = .none
    var didPickVideo: ((URL)->())? = .none
    
    init(target: UIViewController) {
        self.target = target
    }
    
    var selfReference: CameraPicker?
    
    public func pick() {
        
        guard let target = self.target else {
            return
        }
        
        var sourceType = UIImagePickerController.SourceType.camera
        
        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            sourceType = .photoLibrary
        }
        
        let pickerController = UIImagePickerController()
        pickerController.sourceType = sourceType
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        pickerController.videoMaximumDuration = ZMUserSession.shared()!.maxVideoLength()
        pickerController.transitioningDelegate = FastTransitioningDelegate.sharedDelegate
        
        if sourceType == .camera {
            switch Settings.shared().preferredCamera {
            case .back:
                pickerController.cameraDevice = .rear
            case .front:
                pickerController.cameraDevice = .front
            }
        }
        
        target.present(pickerController, animated: true, completion: .none)
        
        self.selfReference = self
    }
    
    fileprivate func finishPicking() {
        if target?.presentedViewController is UIImagePickerController {
            target?.dismiss(animated: true, completion: nil)
        }
        self.selfReference = .none
    }
}


extension CameraPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Workaround http://stackoverflow.com/questions/26651355/
        try? AVAudioSession.sharedInstance().setActive(false)
        self.finishPicking()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        guard let mediaType = info[.mediaType] as? String else {
            self.finishPicking()
            return
        }
        
        // Workaround http://stackoverflow.com/questions/26651355/
        try? AVAudioSession.sharedInstance().setActive(false)
        
        switch mediaType {
        case kUTTypeMovie.string:
            guard let videoURL = info[.mediaURL] as? URL else {
                zmLog.error("Video not provided form \(picker): info \(info)")
                self.finishPicking()
                return
            }
            
            let videoTempPath = NSTemporaryDirectory().appendingPathComponent(String.filenameForSelfUser()).appendingPathExtension(videoURL.pathExtension)!
            let videoTempURL = URL(fileURLWithPath: videoTempPath)
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: videoTempPath) {
                try! fileManager.removeItem(at: videoTempURL)
            }
            
            try! fileManager.moveItem(at: videoURL, to: videoTempURL)
            
            if (picker.sourceType == .camera && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoTempPath)) {
                let selector = #selector(self.video(_:didFinishSavingWithError:contextInfo:))
                UISaveVideoAtPathToSavedPhotosAlbum(videoTempPath, self, selector, nil)
            }
            
            picker.showLoadingView = true
            AVAsset.wr_convertVideo(at: videoTempURL) { resultURL, asset, error in
                defer {
                    picker.showLoadingView = false
                    self.finishPicking()
                }

                guard let url = resultURL, error == nil else {
                    return
                }
            
                self.target?.dismiss(animated: true) {
                    self.didPickResult?(.video(url))
                    self.didPickVideo?(url)
                    self.finishPicking()
                }
            }
        case kUTTypeImage.string:
            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
                self.finishPicking()
                return
            }
            
            target?.dismiss(animated: true) {
                self.didPickResult?(.image(image))
                self.didPickImage?(image)
                self.finishPicking()
            }
        default:
            break
        }
    }
    
    @objc func video(_ videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let error = error {
            zmLog.error("Cannot save video: \(error)")
        }
    }

}
