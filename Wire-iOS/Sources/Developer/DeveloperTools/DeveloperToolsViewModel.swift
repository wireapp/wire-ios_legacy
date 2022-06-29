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
import WireSyncEngine
import WireTransport
import UIKit

@available(iOS 14, *)
final class DeveloperToolsViewModel: ObservableObject {

    // MARK: - Models

    struct Section: Identifiable {

        let id = UUID()
        var header: String
        var items: [Item]

    }

    enum Item: Identifiable {

        case button(ButtonItem)
        case text(TextItem)

        var id: UUID {
            switch self {
            case .button(let buttonItem):
                return buttonItem.id

            case .text(let textItem):
                return textItem.id
            }
        }

    }

    struct ButtonItem: Identifiable {

        let id = UUID()
        let title: String
        let action: () -> Void

    }

    struct TextItem: Identifiable {

        let id = UUID()
        let title: String
        let value: String

    }

    enum Event {

        case dismissButtonTapped
        case itemTapped(Item)

    }

    // MARK: - Properties

    var onDismiss: (() -> Void)?

    // MARK: - State

    var sections: [Section]

    // MARK: - Life cycle

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        sections = []

        sections.append(Section(
            header: "Logs",
            items: [
                .button(ButtonItem(title: "Send debug logs", action: sendDebugLogs))
            ]
        ))

        sections.append(Section(
            header: "App info",
            items: [
                .text(TextItem(title: "App version", value: appVersion)),
                .text(TextItem(title: "Build number", value: buildNumber))
            ]
        ))

        sections.append(Section(
            header: "Backend info",
            items: [
                .text(TextItem(title: "Name", value: backendName)),
                .text(TextItem(title: "Domain", value: backendDomain)),
                .text(TextItem(title: "API version", value: apiVersion)),
                .text(TextItem(title: "Is federation enabled?", value: isFederationEnabled))
            ]
        ))

        if let selfUser = selfUser {
            sections.append(Section(
                header: "Self user",
                items: [
                    .text(TextItem(title: "Handle", value: selfUser.handle ?? "None")),
                    .text(TextItem(title: "Email", value: selfUser.emailAddress ?? "None")),
                    .text(TextItem(title: "User ID", value: selfUser.remoteIdentifier.uuidString)),
                    .text(TextItem(title: "Analytics ID", value: selfUser.analyticsIdentifier?.uppercased() ?? "None")),
                    .text(TextItem(title: "Client ID", value: selfClient?.remoteIdentifier?.uppercased() ?? "None"))
                ]
            ))
        }

        if let pushToken = PushTokenStorage.pushToken {
            sections.append(Section(
                header: "Push token",
                items: [
                    .text(TextItem(title: "Token type", value: String(describing: pushToken.tokenType))),
                    .text(TextItem(title: "Token data", value: pushToken.deviceTokenString))
                ]
            ))
        }
    }

    // MARK: - Events

    func handleEvent(_ event: Event) {
        switch event {
        case .dismissButtonTapped:
            onDismiss?()

        case let .itemTapped(.text(textItem)):
            UIPasteboard.general.string = textItem.value

        case let .itemTapped(.button(buttonItem)):
            buttonItem.action()
        }
    }

    // MARK: - Actions

    private func sendDebugLogs() {
        DebugLogSender.sendLogsByEmail(message: "Send logs yo!")
    }

    // MARK: - Helpers

    private var appVersion: String {
        return Bundle.main.shortVersionString ?? "Unknown"
    }

    private var buildNumber: String {
        return Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"
    }

    private var backendName: String {
        return BackendEnvironment.shared.title
    }

    private var backendDomain: String {
        return APIVersion.domain ?? "None"
    }

    private var apiVersion: String {
        guard let version = APIVersion.current else { return "None" }
        return String(describing: version.rawValue)
    }

    private var isFederationEnabled: String {
        return String(describing: APIVersion.isFederationEnabled)
    }

    private var selfUser: ZMUser? {
        guard let session = ZMUserSession.shared() else { return nil }
        return ZMUser.selfUser(inUserSession: session)
    }

    private var selfClient: UserClient? {
        guard let session = ZMUserSession.shared() else { return nil }
        return session.selfUserClient
    }

}

extension PushToken.TokenType: CustomStringConvertible {

    public var description: String {
        switch self {
        case .standard:
            return "Standard"

        case .voip:
            return "VoIP"

        }
    }

}
