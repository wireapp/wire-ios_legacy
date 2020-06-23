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

import UIKit
import WireLinkPreview
import WireCommonComponents
import WireDataModel

final class ArticleView: UIView {

    // MARK: - Styling
    private let containerColor: UIColor = .from(scheme: .placeholderBackground)
    private let titleTextColor: UIColor = .from(scheme: .textForeground)
    private let titleFont: UIFont = .normalSemiboldFont
    private let authorTextColor: UIColor = .from(scheme: .textDimmed)
    private let authorFont: UIFont = .smallLightFont
    private let authorHighlightTextColor = UIColor.from(scheme: .textDimmed)
    private let authorHighlightFont = UIFont.smallSemiboldFont

    var imageHeight: CGFloat = 144 {
        didSet {
            self.imageHeightConstraint.constant = self.imageHeight
        }
    }

    // MARK: - Views
    let messageLabel = UILabel()
    let authorLabel = UILabel()
    let imageView = ImageResourceView()
    var linkPreview: LinkMetadata?
    private let obfuscationView = ObfuscationView(icon: .link)
    private let ephemeralColor = UIColor.accent()
    private var imageHeightConstraint: NSLayoutConstraint!
    weak var delegate: ContextMenuLinkViewDelegate?

    init(withImagePlaceholder imagePlaceholder: Bool) {
        super.init(frame: .zero)
        [messageLabel, authorLabel, imageView, obfuscationView].forEach(addSubview)

        if imagePlaceholder {
            imageView.isAccessibilityElement = true
            imageView.accessibilityIdentifier = "linkPreviewImage"
        }

        setupViews()
        setupConstraints(imagePlaceholder)

        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            addInteraction(interaction)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        accessibilityElements = [authorLabel, messageLabel, imageView]
        self.backgroundColor = self.containerColor
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        accessibilityIdentifier = "linkPreview"

        imageView.clipsToBounds = true

        authorLabel.lineBreakMode = .byTruncatingMiddle
        authorLabel.accessibilityIdentifier = "linkPreviewSource"
        authorLabel.setContentHuggingPriority(.required, for: .vertical)

        messageLabel.numberOfLines = 0
        messageLabel.accessibilityIdentifier = "linkPreviewContent"
        messageLabel.setContentHuggingPriority(.required, for: .vertical)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGestureRecognizer)

        updateLabels()
    }

    private func updateLabels(obfuscated: Bool = false) {
        authorLabel.font = obfuscated ? UIFont(name: "RedactedScript-Regular", size: 16) : authorFont
        messageLabel.font = obfuscated ? UIFont(name: "RedactedScript-Regular", size: 20) : titleFont

        authorLabel.textColor = obfuscated ? ephemeralColor : authorTextColor
        messageLabel.textColor = obfuscated ? ephemeralColor : titleTextColor
    }

    private func setupConstraints(_ imagePlaceholder: Bool) {
        let imageHeight: CGFloat = imagePlaceholder ? self.imageHeight : 0

        [messageLabel, authorLabel, imageView, obfuscationView].prepareForLayout()

        imageView.fitInSuperview(exclude: [.bottom])
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageHeight)
        imageHeightConstraint.priority = UILayoutPriority(rawValue: 999)

        messageLabel.fitInSuperview(with: EdgeInsets(margin: 12), exclude: [.bottom, .top])
        authorLabel.fitInSuperview(with: EdgeInsets(margin: 12), exclude: [.top])
        obfuscationView.pin(to: imageView)

        NSLayoutConstraint.activate([
            imageHeightConstraint,
            messageLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            authorLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8)
            ])
    }

    private var authorHighlightAttributes: [NSAttributedString.Key: AnyObject] {
        return [.font: authorHighlightFont, .foregroundColor: authorHighlightTextColor]
    }

    private func formatURL(_ URL: Foundation.URL) -> NSAttributedString {
        let urlWithoutScheme = URL.urlWithoutScheme
        let displayString = urlWithoutScheme.removingPrefixWWW.removingTrailingForwardSlash

        if let host = URL.host?.removingPrefixWWW {
            return displayString.attributedString.addAttributes(authorHighlightAttributes, toSubstring: host)
        } else {
            return displayString.attributedString
        }
    }

    func configure(withTextMessageData textMessageData: ZMTextMessageData,
                   obfuscated: Bool) {
        guard let linkPreview = textMessageData.linkPreview else {
            return
        }

        self.linkPreview = linkPreview
        updateLabels(obfuscated: obfuscated)

        if let article = linkPreview as? ArticleMetadata {
            configure(withArticle: article, obfuscated: obfuscated)
        }

        if let twitterStatus = linkPreview as? TwitterStatusMetadata {
            configure(withTwitterStatus: twitterStatus)
        }

        obfuscationView.isHidden = !obfuscated
        imageView.isHidden = obfuscated

        if !obfuscated {
            imageView.image = nil
            imageView.contentMode = .scaleAspectFill
            imageView.setImageResource(textMessageData.linkPreviewImage) { [weak self] in
                self?.updateContentMode()
            }
        }
    }

    func updateContentMode() {
        guard let image = self.imageView.image else { return }
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale

        if width < 480.0 || height < 160.0 {
            self.imageView.contentMode = .center
        } else {
            self.imageView.contentMode = .scaleAspectFill
        }
    }

    private func configure(withArticle article: ArticleMetadata, obfuscated: Bool) {
        if let url = article.openableURL, !obfuscated {
            authorLabel.attributedText = formatURL(url as URL)
        } else {
            authorLabel.text = article.originalURLString
        }

        messageLabel.text = article.title
    }

    private func configure(withTwitterStatus twitterStatus: TwitterStatusMetadata) {
        let author = twitterStatus.author ?? "-"
        authorLabel.attributedText = "twitter_status.on_twitter".localized(args: author).attributedString.addAttributes(authorHighlightAttributes, toSubstring: author)

        messageLabel.text = twitterStatus.message
    }

    @objc
    private func viewTapped(_ sender: UITapGestureRecognizer) {
        if UIMenuController.shared.isMenuVisible {
            return UIMenuController.shared.setMenuVisible(false, animated: true)
        }

        openURL()
    }

    private func openURL() {
        delegate?.linkViewWantsToOpenURL(self)
    }
}

// MARK: - UIContextMenuInteractionDelegate

@available(iOS 13.0, *)
extension ArticleView: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return delegate?.linkPreviewContextMenu(view: self)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            self.openURL()
        }
    }
}

extension LinkMetadata {

    /// Returns a `URL` that can be openened using `openURL()` on `UIApplication` or `nil` if no openable `URL` could be created.
    var openableURL: URL? {
        let application = UIApplication.shared

        if let originalURL = URL(string: originalURLString),
            application.canOpenURL(originalURL) {
            return originalURL
        } else if let permanentURL = permanentURL,
            application.canOpenURL(permanentURL) {
            return permanentURL
        }

        return nil
    }
}
