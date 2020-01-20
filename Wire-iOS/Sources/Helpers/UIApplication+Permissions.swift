// 
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


import UIKit
import Photos

extension Notification.Name {
    static let UserGrantedAudioPermissions = Notification.Name("UserGrantedAudioPermissionsNotification")
}

extension UIApplication {
    
    class func wr_requestOrWarnAboutMicrophoneAccess(_ grantedHandler: @escaping (_ granted: Bool) -> Void) {
        let audioPermissionsWereNotDetermined = AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined
        
        AVAudioSession.sharedInstance().requestRecordPermission({ granted in
            
            DispatchQueue.main.async(execute: {
                if !granted {
                    self.wr_warnAboutMicrophonePermission()
                }
                
                if audioPermissionsWereNotDetermined && granted {
                    NotificationCenter.default.post(name: Notification.Name.UserGrantedAudioPermissions, object: nil)
                }
                grantedHandler(granted)
            })
        })
    }
    
    class func wr_requestOrWarnAboutVideoAccess(_ grantedHandler: @escaping (_ granted: Bool) -> Void) {
        UIApplication.wr_requestVideoAccess({ granted in
            DispatchQueue.main.async(execute: {
                if !granted {
                    self.wr_warnAboutCameraPermission(withCompletion: {
                        grantedHandler(granted)
                    })
                } else {
                    grantedHandler(granted)
                }
            })
        })
    }
    
    static func wr_requestOrWarnAboutPhotoLibraryAccess(_ grantedHandler: ((Bool) -> Swift.Void)!) {
        PHPhotoLibrary.requestAuthorization({ status in
            DispatchQueue.main.async(execute: {
                switch status {
                case .restricted:
                    self.wr_warnAboutPhotoLibraryRestricted()
                    grantedHandler(false)
                case .denied,
                     .notDetermined:
                    self.wr_warnAboutPhotoLibaryDenied()
                    grantedHandler(false)
                case .authorized:
                    grantedHandler(true)
                @unknown default:
                    break
                }
            })
        })
    }
    
    class func wr_requestVideoAccess(_ grantedHandler: @escaping (_ granted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            DispatchQueue.main.async(execute: {
                grantedHandler(granted)
            })
        })
    }
    
    private class func wr_warnAboutCameraPermission(withCompletion completion: @escaping () -> ()) {
        let currentResponder = UIResponder.wr_currentFirst()
        (currentResponder as? UIView)?.endEditing(true)
        
        let noVideoAlert = UIAlertController.alertWithOKButton(title: "voice.alert.camera_warning.title".localized,
                                                               message: "voice.alert.camera_warning.explanation".localized,
                                                               okActionHandler: { action in
                                                                completion()
        })
        
        let actionSettings = UIAlertAction(title: "general.open_settings".localized,
                                           style: .default,
                                           handler: { action in
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url, options: [:])
                                            }
                                            completion()
        })
        
        noVideoAlert.addAction(actionSettings)
        
        AppDelegate.shared.window?.rootViewController?.present(noVideoAlert, animated: true)
    }
    
    private class func wr_warnAboutMicrophonePermission() {
        let noMicrophoneAlert = UIAlertController.alertWithOKButton(title: "voice.alert.microphone_warning.title".localized,
                                                                    message: "voice.alert.microphone_warning.explanation".localized,
                                                                    okActionHandler: nil)
        
        let actionSettings = UIAlertAction(title: "general.open_settings".localized,
                                           style: .default,
                                           handler: { action in
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            }
        })
        
        noMicrophoneAlert.addAction(actionSettings)
        
        AppDelegate.shared.window?.rootViewController?.present(noMicrophoneAlert, animated: true)
    }
    
    private class func wr_warnAboutPhotoLibraryRestricted() {
        let libraryRestrictedAlert = UIAlertController(title: "library.alert.permission_warning.title".localized,
                                                       message: "library.alert.permission_warning.restrictions.explaination".localized,
                                                       cancelButtonTitle: "general.ok".localized)
        
        AppDelegate.shared.window?.rootViewController?.present(libraryRestrictedAlert, animated: true)
    }
    
    private class func wr_warnAboutPhotoLibaryDenied() {
        let deniedAlert = UIAlertController(title: "library.alert.permission_warning.title".localized,
                                            message: "library.alert.permission_warning.not_allowed.explaination".localized,
                                            cancelButtonTitle: "general.cancel".localized)
        
        deniedAlert.addAction(UIAlertAction(title: "general.open_settings".localized,
                                            style: .default,
                                            handler: { action in
                                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                }
        }))
        
        AppDelegate.shared.window?.rootViewController?.present(deniedAlert, animated: true)
    }
}
