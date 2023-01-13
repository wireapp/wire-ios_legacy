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
import UIKit

final class CustomBackendView: UIView {
    lazy var backendLabel: UILabel = {
        let label = DynamicFontLabel(text: nil,
                                     fontSpec: .headerSemiboldFont,
                                     color: SemanticColors.Label.textSectionHeader)
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        let imageSize: CGFloat = 16
        let imageView = UIImageView(image: UIImage(named: "Info"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
        self.addSubview(imageView)

        backendLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(backendLabel)

        // Horizontal
        backendLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: -imageSize/2).isActive = true
        backendLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor).isActive = true
        backendLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -2).isActive = true
        imageView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor).isActive = true

        // Vertical
        imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        backendLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    func setBackendUrl(_ url: URL) {
        if let domain = NSURLComponents(url: url, resolvingAgainstBaseURL: false)?.host {
            backendLabel.text = domain
        }
    }
}
