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
import WireTransport

@available(iOS 14, *)
final class PreferredAPIVersionViewModel: ObservableObject {

    // MARK: - Models

    struct Section: Identifiable {

        let id = UUID()
        let header: String
        let items: [Item]

    }

    struct Item: Identifiable {

        let id = UUID()
        let title: String
        let value: Value

    }

    enum Value: Equatable {

        case noPreference
        case apiVersion(APIVersion)

        init(apiVersion: APIVersion?) {
            if let apiVersion = apiVersion {
                self = .apiVersion(apiVersion)
            } else {
                self = .noPreference
            }
        }

    }

    enum Event {

        case itemTapped(Item)

    }

    // MARK: - State

    let sections: [Section]

    @Published
    var selectedItemID: Item.ID

    // MARK: - Life cycle

    init() {
        sections = [
            Section(header: "", items: [Item(title: "No preference", value: .noPreference)]),
            Section(header: "Production versions", items: APIVersion.productionVersions.map {
                Item(title: String($0.rawValue), value: Value(apiVersion: $0))
            }),
            Section(header: "Development versions", items: APIVersion.developmentVersions.map {
                Item(title: String($0.rawValue), value: Value(apiVersion: $0))
            })
        ]

        // Initial selection
        let selectedItem = sections.flatMap(\.items).first { item in
            item.value == Value(apiVersion: APIVersion.preferredVersion)
        }!

        selectedItemID = selectedItem.id
    }

    // MARK: - Events

    func handleEvent(_ event: Event) {
        switch event {
        case let .itemTapped(item):
            selectedItemID = item.id

            switch item.value {
            case .noPreference:
                APIVersion.preferredVersion = nil
            case .apiVersion(let version):
                APIVersion.preferredVersion = version
            }
        }
    }

}
