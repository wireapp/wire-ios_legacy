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


import Photos

protocol PhotoLibraryProtocol {
    func performChanges(_ changeBlock: @escaping () -> Swift.Void, completionHandler: ((Bool, Error?) -> Swift.Void)?)
}

extension PHPhotoLibrary: PhotoLibraryProtocol {}

protocol AssetChangeRequestProtocol: class {
    @discardableResult static func creationRequestForAsset(from image: UIImage) -> Self
}

extension PHAssetChangeRequest: AssetChangeRequestProtocol {}

@objcMembers final public class SavableImage: NSObject {

    /// protocols for inject mocking photo services
    var photoLibrary: PhotoLibraryProtocol = PHPhotoLibrary.shared()
    var assetChangeRequestType: AssetChangeRequestProtocol.Type = PHAssetChangeRequest.self
    var applicationType: ApplicationProtocol.Type = UIApplication.self

    public typealias ImageSaveCompletion = (Bool) -> Void

    fileprivate let imageData: Data
    fileprivate let imageOrientation: UIImageOrientation
    fileprivate var writeInProgess = false

    init(data: Data, orientation: UIImageOrientation) {
        imageData = data
        imageOrientation = orientation
        super.init()
    }
    
    public func saveToLibrary(withCompletion completion: ImageSaveCompletion? = .none) {
        guard !writeInProgess else { return }
        writeInProgess = true

        applicationType.wr_requestOrWarnAboutPhotoLibraryAccess { granted in
            guard granted else {
                completion?(false)
                return
            }

            self.photoLibrary.performChanges({
                guard let image = UIImage(data: self.imageData) else { return }
                self.assetChangeRequestType.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    self.writeInProgess = false
                    if let error = error {
                        self.warnAboutError(error)
                    }
                    completion?(success)
                }
            }
        }

    }

    private func warnAboutError(_ error: Error) {
        let alert = UIAlertController(title: "library.alert.permission_warning.title".localized,
                                      message: (error as NSError).localizedDescription,
                                      cancelButtonTitle: "general.ok".localized)

        AppDelegate.shared().notificationsWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }

}

extension UIImageOrientation {
    var exifOrientiation: UInt {
        switch self {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        }
    }
}
