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

import Foundation
import SwiftUI

extension SettingsCellDescriptorFactory {

    var developerGroup: SettingsCellDescriptorType {
        typealias ExternalScreen = SettingsExternalScreenCellDescriptor
        typealias Toggle = SettingsPropertyToggleCellDescriptor
        typealias Button = SettingsButtonCellDescriptor

        var developerCellDescriptors: [SettingsCellDescriptorType] = []

        if #available(iOS 13, *) {
            developerCellDescriptors.append(
                ExternalScreen(title: "Developer flags") {
                    UIHostingController(rootView: DeveloperFlagsView().environment(\.colorScheme, .dark))
                }
            )
        }

        developerCellDescriptors.append(
            ExternalScreen(title: "Logging") { DeveloperOptionsController() }
        )

        developerCellDescriptors.append(
            Toggle(settingsProperty: settingsPropertyFactory.property(.enableBatchCollections))
        )

        developerCellDescriptors.append(
            Button(title: "Send broken message",
                   isDestructive: true,
                   selectAction: DebugActions.sendBrokenMessage)
        )

        developerCellDescriptors.append(
            Button(title: "First unread conversation (badge count)",
                   isDestructive: false,
                   selectAction: DebugActions.findUnreadConversationContributingToBadgeCount)
        )

        developerCellDescriptors.append(
            Button(title: "First unread conversation (back arrow count)",
                   isDestructive: false,
                   selectAction: DebugActions.findUnreadConversationContributingToBackArrowDot)
        )

        developerCellDescriptors.append(
            Button(title: "Delete invalid conversations",
                   isDestructive: false,
                   selectAction: DebugActions.deleteInvalidConversations)
        )

        developerCellDescriptors.append(SettingsShareDatabaseCellDescriptor())
        developerCellDescriptors.append(SettingsShareCryptoboxCellDescriptor())

        developerCellDescriptors.append(
            Button(title: "Reload user interface",
                   isDestructive: false,
                   selectAction: DebugActions.reloadUserInterface)
        )

        developerCellDescriptors.append(
            Button(title: "Re-calculate badge count",
                   isDestructive: false,
                   selectAction: DebugActions.recalculateBadgeCount)
        )

        developerCellDescriptors.append(
            Button(title: "Append N messages to the top conv (not sending)", isDestructive: true) { _ in
                DebugActions.askNumber(title: "Enter count of messages") { count in
                    DebugActions.appendMessagesInBatches(count: count)
                }
            }
        )

        developerCellDescriptors.append(
            Button(title: "Spam the top conv", isDestructive: true) { _ in
                DebugActions.askNumber(title: "Enter count of messages") { count in
                    DebugActions.spamWithMessages(amount: count)
                }
            }
        )

        developerCellDescriptors.append(
            ExternalScreen(title: "Show database statistics",
                           isDestructive: false,
                           presentationStyle: .navigation,
                           presentationAction: {  DatabaseStatisticsController() })
        )

        if !Analytics.shared.isOptedOut && !TrackingManager.shared.disableAnalyticsSharing {
            developerCellDescriptors.append(
                Button(title: "Reset call quality survey",
                       isDestructive: false,
                       selectAction: DebugActions.resetCallQualitySurveyMuteFilter)
            )
        }

        developerCellDescriptors.append(
            Button(title: "Generate test crash",
                   isDestructive: false,
                   selectAction: DebugActions.generateTestCrash)
        )

        developerCellDescriptors.append(
            Button(title: "Trigger slow sync",
                   isDestructive: false,
                   selectAction: DebugActions.triggerSlowSync)
        )

        developerCellDescriptors.append(
            Button(title: "What's my analytics id?",
                   isDestructive: false,
                   selectAction: DebugActions.showAnalyticsIdentifier)
        )

        developerCellDescriptors.append(
            Button(title: "What's the api version?",
                   isDestructive: false,
                   selectAction: DebugActions.showAPIVersionInfo)
        )

        return SettingsGroupCellDescriptor(items: [SettingsSectionDescriptor(cellDescriptors: developerCellDescriptors)],
                                           title: L10n.Localizable.`Self`.Settings.DeveloperOptions.title,
                                           icon: .robot)
    }

}
