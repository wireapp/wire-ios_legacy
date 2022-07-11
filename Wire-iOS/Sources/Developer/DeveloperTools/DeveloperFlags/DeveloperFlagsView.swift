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

@available(iOS 14, *)
struct DeveloperFlagsView: View {

    // MARK: - Properties

    @StateObject
    var viewModel: DeveloperFlagsViewModel

    // MARK: - Views

    var body: some View {
        List(viewModel.flags, id: \.self) { flag in
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

@available(iOS 14, *)
struct DeveloperFlagsView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            DeveloperFlagsView(viewModel: DeveloperFlagsViewModel())
        }
    }

}
