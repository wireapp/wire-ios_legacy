//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit

final class SimpleImageMessageRestrictionView: BaseMessageRestrictionView {

    // MARK: - Life cycle

    init() {
        super.init(messageType: .image)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    override func setupViews() {
        super.setupViews()

        addSubview(iconView)
    }

    override func createConstraints() {
        super.createConstraints()

        NSLayoutConstraint.activate([
            // icon view
            iconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
}
