//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import MobileCoreServices
import WireSyncEngine

typealias AppearancePreviewType = (SettingsCellDescriptorType) -> AppearanceType

class SettingsAppearanceCellDescriptor: SettingsCellDescriptorType, SettingsExternalScreenCellDescriptorType {
    static let cellType: SettingsTableCellProtocol.Type = SettingsAppearanceCell.self

    private var text: String
    private let appearancePreview: AppearancePreviewType?
    private let presentationStyle: PresentationStyle
    private let imagePickerConfirmationController = ImagePickerConfirmationController()
    private let imagePickerController = UIImagePickerController()

    weak var viewController: UIViewController?
    let presentationAction: () -> (UIViewController?)

    var identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var previewGenerator: PreviewGeneratorType?

    var visible: Bool {
        return true
    }

    var title: String {
        return text
    }

    init(text: String,
         appearancePreview: AppearancePreviewType? = .none,
         presentationStyle: PresentationStyle,
         presentationAction: @escaping () -> (UIViewController?)) {
        self.text = text
        self.appearancePreview = appearancePreview
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction

        imagePickerConfirmationController.imagePickedBlock = { [weak self] imageData in
//            print(self?.viewController)
//            print(self?.viewController?.presentedViewController)
//            print(self?.viewController?.presentationController)
//            print(self?.viewController?.presentingViewController)
//            print(self?.viewController?.parent)
            self?.imagePickerController.dismiss(animated: true) {
                self?.setSelfImageTo(imageData)
            }
        }

    }

    // MARK: - Configuration

    func featureCell(_ cell: SettingsCellType) {
        if let tableCell = cell as? SettingsAppearanceCell {
            if let appearancePreview = self.appearancePreview {
                tableCell.type = appearancePreview(self)
            }
            tableCell.configure(with: .appearance(title: text), variant: .dark)
            if self.presentationStyle == .modal {
                tableCell.hideDisclosureIndicator()
            } else {
                tableCell.showDisclosureIndicator()
            }
        }
    }

    // MARK: - SettingsCellDescriptorType

    func select(_ value: SettingsPropertyValue?) {
        guard let controllerToShow = self.generateViewController() else {
            return
        }

        switch self.presentationStyle {
        case .modal:
            UIAlertController.presentProfilePicturePicker()
        case .navigation:
            viewController?.navigationController?.pushViewController(controllerToShow, animated: true)
        }
    }

    func presentProfilePicturePicker1() {
        typealias Alert = L10n.Localizable.Self.Settings.AccountPictureGroup.Alert

        let actionSheet = UIAlertController(title: Alert.title,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: Alert.choosePicture, style: .default, handler: { [weak self] (_) in
            self?.chooseFromLibraryAction()
        }))

        actionSheet.addAction(UIAlertAction(title: Alert.takePicture, style: .default, handler: { [weak self] (_) in
            self?.takePhotoAction1()
        }))
        actionSheet.addAction(.cancel())

        viewController?.present(actionSheet, animated: true)
    }

    @objc
    private func chooseFromLibraryAction() {
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        imagePickerController.delegate = imagePickerConfirmationController

        if let viewController = viewController, viewController.isIPadRegular() {
            imagePickerController.modalPresentationStyle = .popover
            let popover: UIPopoverPresentationController? = imagePickerController.popoverPresentationController

            popover?.backgroundColor = UIColor.white
        }

        viewController?.present(imagePickerController, animated: true)
    }

    @objc
    private func takePhotoAction1() {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) || !UIImagePickerController.isCameraDeviceAvailable(.front) {
            return
        }

        let picker = UIImagePickerController()

        picker.sourceType = .camera
        picker.delegate = imagePickerConfirmationController
        picker.allowsEditing = true
        picker.cameraDevice = .front
        picker.mediaTypes = [kUTTypeImage as String]
        picker.modalTransitionStyle = .coverVertical
        viewController?.present(picker, animated: true)
    }

    /// This should be called when the user has confirmed their intent to set their image to this data. No custom presentations should be in flight, all previous presentations should be completed by this point.
    private func setSelfImageTo(_ selfImageData: Data?) {
        // iOS11 uses HEIF image format, but BE expects JPEG
        guard let selfImageData = selfImageData,
              let jpegData: Data = selfImageData.isJPEG ? selfImageData : UIImage(data: selfImageData)?.jpegData(compressionQuality: 1.0) else { return }

        ZMUserSession.shared()?.enqueue({
            ZMUserSession.shared()?.userProfileImage?.updateImage(imageData: jpegData)
        })
    }

    func generateViewController() -> UIViewController? {
        return self.presentationAction()
    }
}

enum AppearanceType {
    case none
    case image(UIImage)
    case color(UIColor)
}
