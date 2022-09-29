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
    private let imagePickerManager = ImagePickerManager()

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
            imagePickerManager.showActionSheet(vc: viewController) { [weak self] image in
                self?.imagePickerManager.presentingPickerController?.dismiss(animated: true)
                guard let jpegData = image.jpegData else {
                    return
                }
                ZMUserSession.shared()?.enqueue({
                    ZMUserSession.shared()?.userProfileImage?.updateImage(imageData: jpegData)
                })
            }
        case .navigation:
            viewController?.navigationController?.pushViewController(controllerToShow, animated: true)
        }
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
