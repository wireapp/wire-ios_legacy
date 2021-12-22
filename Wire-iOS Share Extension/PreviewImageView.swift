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

import Foundation
import UIKit

/**
 * The aspect ratio of the video view.
 */

enum PreviewDisplayMode {
    case video
    case link
    case placeholder
    indirect case mixed(Int, PreviewDisplayMode?)

    /// The size of the preview, in points.
    static var size: CGSize {
        return CGSize(width: 70, height: 70)
    }

    /// The maximum size of a preview, adjusted for the device scale.
    static var pixelSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: 70 * scale, height: 70 * scale)
    }
}

extension Optional where Wrapped == PreviewDisplayMode {

    /// Combines the current display mode with the current one if they're compatible.
    func combine(with otherMode: PreviewDisplayMode?) -> PreviewDisplayMode? {
        guard let currentMode = self else {
            return otherMode
        }

        guard case let .mixed(count, _) = currentMode else {
            return currentMode
        }

        return .mixed(count, otherMode)
    }

}

/**
 * An image view used to preview the content of a post.
 */

final class PreviewImageView: UIImageView {

    private let detailsContainer = UIView()
    private let videoBadgeImageView = UIImageView()
    private let countLabel = UILabel()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        displayMode = nil

        detailsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        videoBadgeImageView.setIcon(.movie, size: .small, color: .white)

        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = .white
        countLabel.textAlignment = .natural

        detailsContainer.addSubview(videoBadgeImageView)
        detailsContainer.addSubview(countLabel)
        addSubview(detailsContainer)
    }

    private func configureConstraints() {
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        videoBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            // Video Indicator
            videoBadgeImageView.heightAnchor.constraint(equalToConstant: 16),
            videoBadgeImageView.widthAnchor.constraint(equalToConstant: 16),
            videoBadgeImageView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 4),
            videoBadgeImageView.centerYAnchor.constraint(equalTo: detailsContainer.centerYAnchor),
            // Count Label
            countLabel.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -4),
            countLabel.centerYAnchor.constraint(equalTo: detailsContainer.centerYAnchor),
            // Details Container
            detailsContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            detailsContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            detailsContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            detailsContainer.heightAnchor.constraint(equalToConstant: 24)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Display Mode

    /// How the content should be displayed.
    var displayMode: PreviewDisplayMode? {
        didSet {
            invalidateIntrinsicContentSize()
            updateContentMode(for: displayMode)
            updateBorders(for: displayMode)
            updateDetailsBadge(for: displayMode)
        }
    }

    private func updateContentMode(for displayMode: PreviewDisplayMode?) {
        switch displayMode {
        case .none:
            contentMode = .scaleAspectFit
        case .video?, .link?:
            contentMode = .scaleAspectFill
        case .placeholder?:
            contentMode = .center
        case .mixed(_, let mainMode)?:
            updateContentMode(for: mainMode)
        }
    }

    private func updateBorders(for displayMode: PreviewDisplayMode?) {
        switch displayMode {
        case .placeholder?, .link?:
            layer.borderColor = UIColor.gray.cgColor
            layer.borderWidth = UIScreen.hairline
        case .mixed(_, let mainMode)?:
            updateBorders(for: mainMode)
        default:
            layer.borderColor = nil
            layer.borderWidth = 0
        }
    }

    private func updateDetailsBadge(for displayMode: PreviewDisplayMode?) {
        switch displayMode {
        case .video?:
            detailsContainer.isHidden = false
            videoBadgeImageView.isHidden = false
            countLabel.isHidden = true
        case .mixed(let count, _)?:
            detailsContainer.isHidden = false
            videoBadgeImageView.isHidden = true
            countLabel.isHidden = false
            countLabel.text = String(count)
        default:
            detailsContainer.isHidden = true
            videoBadgeImageView.isHidden = true
            countLabel.isHidden = true
        }
    }

    override var intrinsicContentSize: CGSize {
        return PreviewDisplayMode.size
    }
}
