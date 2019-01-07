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


extension ZMUser {
    var hasValidEmail: Bool {
        guard let email = self.emailAddress,
                !email.isEmpty else {
            return false
        }
        return true
    }
}

extension SettingsCellDescriptorFactory {

    func accountGroup() -> SettingsCellDescriptorType {
        var sections: [SettingsSectionDescriptorType] = [
            infoSection(),
            appearanceSection(),
            privacySection(),
            personalInformationSection(),
            conversationsSection()]
        
        if let user = ZMUser.selfUser(), !user.usesCompanyLogin {
            sections.append(actionsSection())
        }
        
        sections.append(signOutSection())

        return SettingsGroupCellDescriptor(items: sections, title: "self.settings.account_section".localized, icon: .settingsAccount)
    }

    // MARK: - Sections

    func infoSection() -> SettingsSectionDescriptorType {
        var cellDescriptors = [nameElement(), handleElement()]
        
        if let user = ZMUser.selfUser(), !user.usesCompanyLogin {
            if !ZMUser.selfUser().hasTeam || !(ZMUser.selfUser().phoneNumber?.isEmpty ?? true) {
                cellDescriptors.append(phoneElement())
            }
            
            cellDescriptors.append(emailElement())
        }
        return SettingsSectionDescriptor(
            cellDescriptors: cellDescriptors,
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
    
    func privacySection() -> SettingsSectionDescriptorType {
        return SettingsSectionDescriptor(
            cellDescriptors: [readReceiptsEnabledElement()],
            header: "self.settings.privacy_section_group.title".localized,
            footer: "self.settings.privacy_section_group.subtitle".localized
        )
    }

    func personalInformationSection() -> SettingsSectionDescriptorType {
        return SettingsSectionDescriptor(
            cellDescriptors: [dateUsagePermissionsElement()],
            header: "self.settings.account_personal_information_group.title".localized
        )
    }

    func conversationsSection() -> SettingsSectionDescriptorType {
        return SettingsSectionDescriptor(
            cellDescriptors: [backUpElement()],
            header: "self.settings.conversations.title".localized
        )
    }

    func actionsSection() -> SettingsSectionDescriptorType {
        var cellDescriptors = [resetPasswordElement()]
        if let selfUser = self.settingsPropertyFactory.selfUser, !selfUser.isTeamMember {
            cellDescriptors.append(deleteAccountButtonElement())
        }
        
        return SettingsSectionDescriptor(
            cellDescriptors: cellDescriptors,
            header: "self.settings.account_details.actions.title".localized,
            footer: .none
        )
    }

    func signOutSection() -> SettingsSectionDescriptorType {
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
                return ChangeEmailViewController()
            },
            previewGenerator: { _ in
                if let email = ZMUser.selfUser().emailAddress, !email.isEmpty {
                    return SettingsCellPreview.text(email)
                } else {
                    return SettingsCellPreview.text("self.add_email_password".localized)
                }
            },
            accessoryViewMode: .alwaysHide
        )
    }

    func phoneElement() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.account_section.phone.title".localized,
            isDestructive: false,
            presentationStyle: .navigation,
            presentationAction: {
                return ChangePhoneViewController()
            },
            previewGenerator: { _ in
                if let phoneNumber = ZMUser.selfUser().phoneNumber, !phoneNumber.isEmpty {
                    return SettingsCellPreview.text(phoneNumber)
                } else {
                    return SettingsCellPreview.text("self.add_phone_number".localized)
                }
        },
            accessoryViewMode: .alwaysHide
        )

    }

    func handleElement() -> SettingsCellDescriptorType {
        let presentation: () -> ChangeHandleViewController = {
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
                accessoryViewMode: .alwaysHide
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
    
    func readReceiptsEnabledElement() -> SettingsCellDescriptorType {
        return SettingsPropertyToggleCellDescriptor(settingsProperty: self.settingsPropertyFactory.property(.readReceiptsEnabled),
                                                    inverse: false,
                                                    identifier: "ReadReceiptsSwitch")
    }

    func backUpElement() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(
            title: "self.settings.history_backup.title".localized,
            isDestructive: false,
            presentationStyle: .navigation,
            presentationAction: {
                if ZMUser.selfUser().hasValidEmail || ZMUser.selfUser()!.usesCompanyLogin {
                    return BackupViewController.init(backupSource: SessionManager.shared!)
                }
                else {
                    let alert = UIAlertController(
                        title: "self.settings.history_backup.set_email.title".localized,
                        message: "self.settings.history_backup.set_email.message".localized,
                        preferredStyle: .alert
                    )
                    let actionCancel = UIAlertAction(title: "general.ok".localized, style: .cancel, handler: nil)
                    alert.addAction(actionCancel)

                    guard let controller = UIApplication.shared.wr_topmostController(onlyFullScreen: false) else { return nil }

                    controller.present(alert, animated: true)
                    return nil
                }
        }
        )
    }

    func dateUsagePermissionsElement() -> SettingsCellDescriptorType {
        return dataUsagePermissionsGroup()
    }

    func resetPasswordElement() -> SettingsCellDescriptorType {
        let resetPasswordTitle = "self.settings.password_reset_menu.title".localized
        return SettingsExternalScreenCellDescriptor(title: resetPasswordTitle, isDestructive: false, presentationStyle: .modal, presentationAction: { 
            return BrowserViewController(url: URL.wr_passwordReset.appendingLocaleParameter)
        }, previewGenerator: .none)
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

        let logoutAction: ()->() = {
            guard let selectedAccount = SessionManager.shared?.accountManager.selectedAccount else {
                fatal("No session manager and selected account to log out from")
            }
            
            SessionManager.shared?.delete(account: selectedAccount)
        }

        return SettingsExternalScreenCellDescriptor(title: "self.sign_out".localized,
                                                    isDestructive: true,
                                                    presentationStyle: .modal,
                                                    presentationAction: { 
            let alert = UIAlertController(
                title: "self.settings.account_details.log_out.alert.title".localized,
                message: "self.settings.account_details.log_out.alert.message".localized,
                preferredStyle: .alert
            )
            let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil)
            alert.addAction(actionCancel)
            let actionLogout = UIAlertAction(title: "general.ok".localized, style: .destructive, handler: { _ in logoutAction() })
            alert.addAction(actionLogout)
            return alert
        })
        
    }

}
