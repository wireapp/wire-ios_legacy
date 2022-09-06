//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSystem
import WireDataModel
import WireCommonComponents

private let zmLog = ZMSLog(tag: "UI")

final class CollectionImageCell: CollectionCell {

    static let maxCellSize: CGFloat = 100

    override var message: ZMConversationMessage? {
        didSet {
            updateViews()
        }
    }

    private var containerView = UIView()
    private let imageView = ImageResourceView()
    private let restrictionView = SimpleImageMessageRestrictionView()

    /// This token is changes everytime the cell is re-used. Useful when performing
    /// asynchronous tasks where the cell might have been re-used in the mean time.
    private var reuseToken = UUID()

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }

    var isHeightCalculated: Bool = false

    func loadView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        secureContentsView.addSubview(containerView)

        NSLayoutConstraint.activate([
            // containerView
            containerView.leadingAnchor.constraint(equalTo: secureContentsView.leadingAnchor),
            containerView.topAnchor.constraint(equalTo: secureContentsView.topAnchor),
            containerView.trailingAnchor.constraint(equalTo: secureContentsView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: secureContentsView.bottomAnchor)
        ])
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        message = .none
        isHeightCalculated = false
        reuseToken = UUID()
    }

    override var obfuscationIcon: StyleKitIcon {
        return .photo
    }

    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)

        guard let changeInfo = changeInfo, changeInfo.imageChanged else { return }

        updateViews()
    }

    private func updateViews() {
        guard let message = self.message else { return }

        if message.canBeShared {
            imageView.contentMode = .scaleAspectFill
            imageView.accessibilityIdentifier = "image"
            imageView.imageSizeLimit = .maxDimensionForShortSide(CollectionImageCell.maxCellSize * UIScreen.main.scale)
            imageView.imageResource = message.imageMessageData?.image

            setup(imageView)

        } else {
            setup(restrictionView)
            restrictionView.configure()
        }
    }

    private func setup(_ view: UIView) {
        view.clipsToBounds = true

        containerView.removeSubviews()
        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}
