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


extension SettingsCellDescriptorFactory {

    func accountGroup() -> SettingsCellDescriptorType {
        var sections: [SettingsSectionDescriptorType] = [
            infoSection(),
            appearanceSection(),
            actionsSection()
        ]

        if let signOutSection = signOutSection() {
            sections.append(signOutSection)
        }

        return SettingsGroupCellDescriptor(items: sections, title: "self.settings.account_section".localized, icon: .settingsAccount)
    }

    // MARK: - Sections

    func infoSection() -> SettingsSectionDescriptorType {
        return SettingsSectionDescriptor(
            cellDescriptors: [nameElement(), handleElement(), phoneElement(), emailElement()],
            header: "self.settings.account_details_group.info.title".localized,
            footer: nil
        )
    }

    func appearanceSection() -> SettingsSectionDescriptorType {
        return SettingsSectionDescriptor(
            cellDescriptors: [pictureElement(), colorElement()],
            header: "self.settings.account_appearance_group.title".localized
        )
    }

    func actionsSection() -> SettingsSectionDescriptorType {
        var cellDescriptors = [ressetPasswordElement()]
        if !self.settingsPropertyFactory.selfUser.isTeamMember {
            cellDescriptors.append(deleteAccountButtonElement())
        }
        
        return SettingsSectionDescriptor(
            cellDescriptors: cellDescriptors,
            header: "self.settings.account_details.actions.title".localized,
            footer: .none
        )
    }

    func signOutSection() -> SettingsSectionDescriptorType? {
        guard DeveloperMenuState.signOutEnabled() else { return nil }
        return SettingsSectionDescriptor(cellDescriptors: [signOutElement()], header: .none, footer: .none)
    }

    // MARK: - Elements

    func nameElement() -> SettingsCellDescriptorType {
        return SettingsPropertyTextValueCellDescriptor(settingsProperty: settingsPropertyFactory.property(.profileName))
    }

    func emailElement() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.account_section.email.title".localized,
            isDestructive: false,
            presentationStyle: .navigation,
            presentationAction: { () -> (UIViewController?) in
             if let email = ZMUser.selfUser().emailAddress, !email.isEmpty {
                return ChangeEmailViewController()
             } else {
                let addEmailController = AddEmailPasswordViewController()
                addEmailController.showsNavigationBar = false
                let stepDelegate = DismissStepDelegate()
                stepDelegate.strongCapture = stepDelegate
                
                addEmailController.formStepDelegate = stepDelegate
                return addEmailController
            }
        },
            previewGenerator: { _ in
                if let email = ZMUser.selfUser().emailAddress, !email.isEmpty {
                    return SettingsCellPreview.text(email)
                } else {
                    return SettingsCellPreview.text("self.add_email_password".localized)
                }
        },
            hideAccesoryView: true
        )
    }

    func phoneElement() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.account_section.phone.title".localized,
            isDestructive: false,
            presentationStyle: .navigation,
            presentationAction: { () -> (UIViewController?) in
                if let phoneNumber = ZMUser.selfUser().phoneNumber, !phoneNumber.isEmpty {
                    return ChangePhoneViewController()
                } else {
                    let addController = AddPhoneNumberViewController()
                    addController.showsNavigationBar = false
                    let stepDelegate = DismissStepDelegate()
                    stepDelegate.strongCapture = stepDelegate
                    
                    addController.formStepDelegate = stepDelegate
                    return addController
                }
        },
            previewGenerator: { _ in
                if let phoneNumber = ZMUser.selfUser().phoneNumber, !phoneNumber.isEmpty {
                    return SettingsCellPreview.text(phoneNumber)
                } else {
                    return SettingsCellPreview.text("self.add_phone_number".localized)
                }
        },
            hideAccesoryView: true
        )

    }

    func handleElement() -> SettingsCellDescriptorType {
        let presentation: () -> ChangeHandleViewController = {
            Analytics.shared()?.tag(UserNameEvent.Settings.enteredUsernameScreen)
            return ChangeHandleViewController()
        }

        if nil != ZMUser.selfUser().handle {
            let preview: PreviewGeneratorType = { _ in
                guard let handle = ZMUser.selfUser().handle else { return .none }
                return .text("@" + handle)
            }
            return SettingsExternalScreenCellDescriptor(
                title: "self.settings.account_section.handle.title".localized,
                isDestructive: false,
                presentationStyle: .navigation,
                presentationAction: presentation,
                previewGenerator: preview,
                hideAccesoryView: true
            )
        }

        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.account_section.add_handle.title".localized,
            presentationAction: presentation
        )
    }

    func pictureElement() -> SettingsCellDescriptorType {
        let previewGenerator: PreviewGeneratorType = { _ in
            guard let image = ZMUser.selfUser().imageSmallProfileData.flatMap(UIImage.init) else { return .none }
            return .image(image)
        }

        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.account_picture_group.picture".localized,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: ProfileSelfPictureViewController.init,
            previewGenerator: previewGenerator
        )
    }

    func colorElement() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.account_picture_group.color".localized,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: AccentColorPickerController.init,
            previewGenerator: { _ in .color(ZMUser.selfUser().accentColor) }
        )
    }

    func ressetPasswordElement() -> SettingsCellDescriptorType {
        let resetPasswordTitle = "self.settings.password_reset_menu.title".localized
        return SettingsButtonCellDescriptor(title: resetPasswordTitle, isDestructive: false) { _ in
            UIApplication.shared.openURL(NSURL.wr_passwordReset().wr_URLByAppendingLocaleParameter() as URL)
            Analytics.shared()?.tagResetPassword(true, from: ResetFromProfile)
        }
    }

    func deleteAccountButtonElement() -> SettingsCellDescriptorType {
        let presentationAction: () -> UIViewController = {
            let alert = UIAlertController(
                title: "self.settings.account_details.delete_account.alert.title".localized,
                message: "self.settings.account_details.delete_account.alert.message".localized,
                preferredStyle: .alert
            )
            let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil)
            alert.addAction(actionCancel)
            let actionDelete = UIAlertAction(title: "general.ok".localized, style: .destructive) { _ in
                ZMUserSession.shared()?.enqueueChanges {
                    ZMUserSession.shared()?.initiateUserDeletion()
                }
            }
            alert.addAction(actionDelete)
            return alert
        }

        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.account_details.delete_account.title".localized,
            isDestructive: true,
            presentationStyle: .modal,
            presentationAction: presentationAction
        )
    }

    func signOutElement() -> SettingsCellDescriptorType {
        return SettingsButtonCellDescriptor(title: "Sign out", isDestructive: false) { _ in
            Settings.shared().reset()
            ExtensionSettings.shared.reset()
            ZMUserSession.resetStateAndExit()
        }
    }

}
