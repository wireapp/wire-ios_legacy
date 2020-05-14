//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class SpinnerSubtitleView: UIStackView {

    var subtitle: String? {
        didSet {
            updateSubtitle(subtitle)
        }
    }

    @objc
    let spinner = ProgressSpinner()

    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        setupViews()
        updateSubtitle(nil)
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        axis = .vertical
        alignment = .center
        spacing = 20
        distribution = .fillProportionally
        label.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        label.font = FontSpec(.small, .regular).fontWithoutDynamicType
        [spinner, label].forEach(addArrangedSubview)
    }

    private func updateSubtitle(_ text: String?) {
        label.text = text
        label.isHidden = nil == text || 0 == text!.count
    }

}
