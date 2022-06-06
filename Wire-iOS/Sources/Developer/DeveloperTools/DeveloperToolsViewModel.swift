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

    struct Item: Identifiable {

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
            header: "App info",
            items: [
                Item(title: "App version", value: appVersion),
                Item(title: "Build number", value: buildNumber)
            ]
        ))

        sections.append(Section(
            header: "Backend info",
            items: [
                Item(title: "Name", value: backendName),
                Item(title: "Domain", value: backendDomain),
                Item(title: "API version", value: apiVersion),
                Item(title: "Is federation enabled?", value: isFederationEnabled)
            ]
        ))

        if let selfUser = selfUser {
            sections.append(Section(
                header: "Self user",
                items: [
                    Item(title: "Handle", value: selfUser.handle ?? "None"),
                    Item(title: "Email", value: selfUser.emailAddress ?? "None"),
                    Item(title: "User ID", value: selfUser.remoteIdentifier.uuidString),
                    Item(title: "Analytics ID", value: selfUser.analyticsIdentifier?.uppercased() ?? "None"),
                    Item(title: "Client ID", value: selfClient?.remoteIdentifier?.uppercased() ?? "None")
                ]
            ))
        }

        if let pushToken = PushTokenStorage.pushToken {
            sections.append(Section(
                header: "Push token",
                items: [
                    Item(title: "Token type", value: String(describing: pushToken.tokenType)),
                    Item(title: "Token data", value: pushToken.deviceTokenString)
                ]
            ))
        }
    }

    // MARK: - Events

    func handleEvent(_ event: Event) {
        switch event {
        case .dismissButtonTapped:
            onDismiss?()

        case let .itemTapped(item):
            UIPasteboard.general.string = item.value
        }
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

        @unknown default:
            return "Uknown type"
        }
    }

}
