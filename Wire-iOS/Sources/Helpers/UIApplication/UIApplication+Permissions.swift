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

import WireCommonComponents
import UIKit
import Photos

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
                    self.wr_warnAboutCameraPermission(withCompletion: { _ in
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

    private class func wr_warnAboutCameraPermission(withCompletion completion: AlertActionHandler?) {
        let currentResponder = UIResponder.currentFirst
        (currentResponder as? UIView)?.endEditing(true)

        let alert = UIAlertController.cameraPermissionAlert(with: completion)

        AppDelegate.shared.window?.rootViewController?.present(alert, animated: true)
    }

    private class func wr_warnAboutMicrophonePermission() {
        let alert = UIAlertController.microphonePermissionAlert
        AppDelegate.shared.window?.rootViewController?.present(alert, animated: true)
    }

    private class func wr_warnAboutPhotoLibraryRestricted() {
        let alert = UIAlertController.alertWithOKButton(
            title: "library.alert.permission_warning.title".localized,
            message: "library.alert.permission_warning.restrictions.explaination".localized
        )

        AppDelegate.shared.window?.rootViewController?.present(alert, animated: true)
    }

    private class func wr_warnAboutPhotoLibaryDenied() {
        let alert = UIAlertController.photoLibraryPermissionAlert
        AppDelegate.shared.window?.rootViewController?.present(alert, animated: true)
    }
}
