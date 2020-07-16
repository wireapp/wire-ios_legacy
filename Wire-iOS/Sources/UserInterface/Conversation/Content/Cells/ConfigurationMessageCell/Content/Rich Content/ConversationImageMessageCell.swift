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
import WireDataModel

final class ConversationImageMessageCell: UIView,
                                          ConversationMessageCell,
                                          ContextMenuDelegate {

    struct Configuration {
        let image: ZMImageMessageData
        let message: ZMConversationMessage
        var isObfuscated: Bool {
            return message.isObfuscated
        }
    }

    private var containerView = UIView()
    private lazy var imageResourceView: ImageResourceView = {
        let view = ImageResourceView()

        // allow iOS 13 context menu
        if #available(iOS 13.0, *) {
            view.delegate = self
            view.isUserInteractionEnabled = true
        }

        return view
    }()

    private let obfuscationView = ObfuscationView(icon: .photo)

    private var aspectConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    var containerColor: UIColor? = .from(scheme: .placeholderBackground)
    var containerHeightConstraint: NSLayoutConstraint!

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?

    var isSelected: Bool = false

    var selectionView: UIView? {
        return containerView
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .from(scheme: .placeholderBackground)
        imageResourceView.contentMode = .scaleAspectFill
        imageResourceView.layer.borderColor = UIColor.from(scheme: .cellSeparator).cgColor

        addSubview(containerView)

        [imageResourceView, obfuscationView].forEach(containerView.addSubview)
        obfuscationView.isHidden = true
    }

    private func createConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        obfuscationView.translatesAutoresizingMaskIntoConstraints = false
        imageResourceView.translatesAutoresizingMaskIntoConstraints = false

        obfuscationView.fitInSuperview()
        imageResourceView.fitInSuperview()

        let leading = containerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        let top = containerView.topAnchor.constraint(equalTo: topAnchor)
        let bottom = containerView.bottomAnchor.constraint(equalTo: bottomAnchor)

        widthConstraint = containerView.widthAnchor.constraint(equalToConstant: 0)
        heightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        widthConstraint?.priority = .defaultHigh
        heightConstraint?.priority = .defaultHigh

        NSLayoutConstraint.activate([
            leading,
            trailing,
            top,
            bottom,
            widthConstraint!,
            heightConstraint!
        ])
    }

    func configure(with object: Configuration, animated: Bool) {
        obfuscationView.isHidden = !object.isObfuscated
        imageResourceView.isHidden = object.isObfuscated

        let scaleFactor: CGFloat = object.image.isAnimatedGIF ? 1 : 0.5
        let imageSize = object.image.originalSize.applying(CGAffineTransform.init(scaleX: scaleFactor, y: scaleFactor))
        let imageAspectRatio = imageSize.width > 0 ? imageSize.height / imageSize.width : 1.0

        aspectConstraint.apply({ containerView.removeConstraint($0) })
        aspectConstraint = containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: imageAspectRatio)
        aspectConstraint?.isActive = true
        widthConstraint?.constant = imageSize.width
        heightConstraint?.constant = imageSize.height

        containerView.backgroundColor = UIColor.from(scheme: .placeholderBackground)
        imageResourceView.layer.borderWidth = 0

        let imageResource = object.isObfuscated ? nil : object.image.image

        imageResourceView.setImageResource(imageResource) { [weak self] in
            self?.updateImageContainerAppearance()
            _ = object.message.startSelfDestructionIfNeeded()
        }
    }

    func updateImageContainerAppearance() {
        if imageResourceView.image?.isTransparent == true {
            containerView.backgroundColor = UIColor.clear
            imageResourceView.layer.borderWidth = 0
        } else {
            containerView.backgroundColor = UIColor.from(scheme: .placeholderBackground)
            imageResourceView.layer.borderWidth = UIScreen.hairline
        }
    }

}

final class ConversationImageMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationImageMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 8

    let isFullWidth: Bool = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    var accessibilityIdentifier: String? {
        return configuration.isObfuscated ? "ObfuscatedImageCell" : "ImageCell"
    }

    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, image: ZMImageMessageData) {
        self.message = message
        self.configuration = View.Configuration(image: image, message: message)
    }

}
