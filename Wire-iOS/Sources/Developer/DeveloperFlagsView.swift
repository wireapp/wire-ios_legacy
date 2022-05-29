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

import SwiftUI

private let storage = UserDefaults(suiteName: "com.wire.developer-flags")!

enum DeveloperFlag: String, CaseIterable {

    case showCreateMLSGroupToggle

    var description: String {
        switch self {
        case .showCreateMLSGroupToggle:
            return "Turn on to show the MLS toggle when creating a new group."
        }
    }

    var isOn: Bool {
        get {
            return storage.bool(forKey: rawValue)
        }

        set {
            storage.set(newValue, forKey: rawValue)
        }
    }

}

@available(iOS 13, *)
struct DeveloperFlagsView: View {

    // MARK: - Properties

    @State
    private var flags = DeveloperFlag.allCases

    var body: some View {
        List(flags, id: \.self) { flag in
            cell(for: flag)
                .padding([.top, .bottom])
        }
    }

    private func cell(for flag: DeveloperFlag) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(flag.rawValue, isOn: binding(for: flag))
            Text(flag.description)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func binding(for flag: DeveloperFlag) -> Binding<Bool> {
        var flag = flag
        return Binding(
            get: { flag.isOn },
            set: { flag.isOn = $0 }
        )
    }
}

// MARK: - Previews

@available(iOS 13, *)
struct DeveloperFlagsView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            DeveloperFlagsView()
        }
    }

}
