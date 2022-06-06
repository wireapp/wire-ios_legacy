//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

/**
 * The view that displays the restore from backup button.
 */

class BackupRestoreStepDescriptionSecondaryView: AuthenticationSecondaryViewDescription {

    let views: [ViewDescriptor]
    weak var actioner: AuthenticationActioner?

    init() {
        let restoreButton = ButtonDescription(
            title: L10n.Localizable.Registration.NoHistory.restoreBackup.uppercased(),
            accessibilityIdentifier: "restore_backup")
        views = [restoreButton]

        restoreButton.buttonTapped = { [weak self] in
            self?.actioner?.executeAction(.startBackupFlow)
        }
    }
}

/**
 * The step that displays information about the history.
 */

class BackupRestoreStepDescription: AuthenticationStepDescription {
    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: String?
    let secondaryView: AuthenticationSecondaryViewDescription?

    init(context: NoHistoryContext) {
        backButton = BackButtonDescription()
        mainView = SolidButtonDescription(
            title: L10n.Localizable.Registration.NoHistory.gotIt,
            accessibilityIdentifier: "ignore_backup")

        switch context {
        case .newDevice:
            headline = L10n.Localizable.Registration.NoHistory.hero
            subtext = L10n.Localizable.Registration.NoHistory.subtitle
        case .loggedOut:
            headline = L10n.Localizable.Registration.NoHistory.LoggedOut.hero
            subtext = L10n.Localizable.Registration.NoHistory.LoggedOut.subtitle
        }

        guard SecurityFlags.backup.isEnabled else {
            secondaryView = nil
            return
        }
        secondaryView = BackupRestoreStepDescriptionSecondaryView()
    }

}
