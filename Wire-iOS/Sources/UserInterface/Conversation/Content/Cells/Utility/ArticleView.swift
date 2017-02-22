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
import Cartography
import ZMCLinkPreview
import TTTAttributedLabel
import WireExtensionComponents
import Classy

@objc protocol ArticleViewDelegate: class {
    func articleViewWantsToOpenURL(_ articleView: ArticleView, url: URL)
    func articleViewDidLongPressView(_ articleView: ArticleView)
}

class ArticleView: UIView {

    /// MARK - Styling
    var containerColor: UIColor?
    var titleTextColor: UIColor?
    var titleFont: UIFont?
    var authorTextColor: UIColor?
    var authorFont: UIFont?
    var authorHighlightTextColor = UIColor.gray
    var authorHighlightFont = UIFont.boldSystemFont(ofSize: 14)
    var imageHeight: CGFloat = 144 {
        didSet {
            self.imageHeightConstraint.constant = self.imageHeight
        }
    }
    
    /// MARK - Views
    let messageLabel = TTTAttributedLabel(frame: CGRect.zero)
    let authorLabel = UILabel()
    let imageView = UIImageView()
    var loadingView: ThreeDotsLoadingView?
    var linkPreview: LinkPreview?
    private let obfuscationView = ObfuscationView(icon: .link)
    private let ephemeralColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorAccent)
    private var imageHeightConstraint: NSLayoutConstraint!
    weak var delegate: ArticleViewDelegate?
    
    init(withImagePlaceholder imagePlaceholder: Bool) {
        super.init(frame: CGRect.zero)
        [messageLabel, authorLabel, imageView, obfuscationView].forEach(addSubview)
        
        if (imagePlaceholder) {
            let loadingView = ThreeDotsLoadingView()
            imageView.addSubview(loadingView)
            imageView.isAccessibilityElement = true
            imageView.accessibilityIdentifier = "linkPreviewImage"
            self.loadingView = loadingView
        }
        
        CASStyler.default().styleItem(self)
        
        setupViews()
        setupConstraints(imagePlaceholder)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        accessibilityElements = [authorLabel, messageLabel, imageView]
        self.backgroundColor = self.containerColor
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        accessibilityIdentifier = "linkPreview"
        
        imageView.clipsToBounds = true

        authorLabel.lineBreakMode = .byTruncatingMiddle
        authorLabel.accessibilityIdentifier = "linkPreviewSource"

        messageLabel.numberOfLines = 0
        messageLabel.accessibilityIdentifier = "linkPreviewContent"
        messageLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        messageLabel.delegate = self

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(viewLongPressed)))

        updateLabels()
    }

    func updateLabels(obfuscated: Bool = false) {
        messageLabel.linkAttributes = obfuscated ? nil :  [NSForegroundColorAttributeName : UIColor.accent()]
        messageLabel.activeLinkAttributes = obfuscated ? nil : [NSForegroundColorAttributeName : UIColor.accent().withAlphaComponent(0.5)]

        authorLabel.font = obfuscated ? UIFont(name: "RedactedScript-Regular", size: 16) : authorFont
        messageLabel.font = obfuscated ? UIFont(name: "RedactedScript-Regular", size: 20) : titleFont

        authorLabel.textColor = obfuscated ? ephemeralColor : authorTextColor
        messageLabel.textColor = obfuscated ? ephemeralColor : titleTextColor
    }
    
    func setupConstraints(_ imagePlaceholder: Bool) {
        let imageHeight : CGFloat = imagePlaceholder ? self.imageHeight : 0
        
        constrain(self, messageLabel, authorLabel, imageView, obfuscationView) { (container: LayoutProxy, messageLabel: LayoutProxy, authorLabel: LayoutProxy, imageView: LayoutProxy, obfuscationView: LayoutProxy) -> () in
            imageView.left == container.left
            imageView.top == container.top
            imageView.right == container.right
            self.imageHeightConstraint = (imageView.height == imageHeight ~ 999)
            
            messageLabel.left == container.left + 12
            messageLabel.top == imageView.bottom + 12
            messageLabel.right == container.right - 12
            
            authorLabel.left == container.left + 12
            authorLabel.right == container.right - 12
            authorLabel.top == messageLabel.bottom + 8
            authorLabel.bottom == container.bottom - 12

            obfuscationView.edges == imageView.edges
        }
        
        if let loadingView = self.loadingView {
            constrain(imageView, loadingView) { imageView, loadingView in
                loadingView.center == imageView.center
            }
        }
    }
    
    var authorHighlightAttributes : [String: AnyObject] {
        return [NSFontAttributeName : authorHighlightFont, NSForegroundColorAttributeName: authorHighlightTextColor]
    }
    
    func formatURL(_ URL: Foundation.URL) -> NSAttributedString {
        let urlWithoutScheme = URL.absoluteString.removingURLScheme(URL.scheme!)
        let displayString = urlWithoutScheme.removingPrefixWWW().removingTrailingForwardSlash()

        if let host = URL.host?.removingPrefixWWW() {
            return displayString.attributedString.addAttributes(authorHighlightAttributes, toSubstring: host)
        } else {
            return displayString.attributedString
        }
    }
    
    static var imageCache : ImageCache  = {
        let cache = ImageCache(name: "ArticleView.imageCache")
        cache.maxConcurrentOperationCount = 4;
        cache.totalCostLimit = UInt(1024 * 1024 * 10); // 10 MB
        cache.qualityOfService = .utility;
        return cache
    }()
    
    func configure(withTextMessageData textMessageData: ZMTextMessageData, obfuscated: Bool) {
        guard let linkPreview = textMessageData.linkPreview else {
            return
        }
        self.linkPreview = linkPreview
        updateLabels(obfuscated: obfuscated)

        if let article = linkPreview as? Article {
            configure(withArticle: article, obfuscated: obfuscated)
        }
        
        if let twitterStatus = linkPreview as? TwitterStatus {
            configure(withTwitterStatus: twitterStatus)
        }

        obfuscationView.isHidden = !obfuscated

        if let imageData = textMessageData.imageData,
            let imageDataIdentifier = textMessageData.imageDataIdentifier {

            if obfuscated {
                ArticleView.imageCache.removeImage(forCacheKey: imageDataIdentifier)
                imageView.image = UIImage.init(for: .link, iconSize: .tiny, color: ColorScheme.default().color(withName: ColorSchemeColorBackground))
                imageView.contentMode = .center
                
            } else {
                imageView.image = UIImage(data: imageData)
                imageView.contentMode = .scaleAspectFill
                loadingView?.isHidden = true
                ArticleView.imageCache.image(for: imageData, cacheKey: imageDataIdentifier, creationBlock: { data -> Any in
                    return UIImage.deviceOptimizedImage(from: data)
                    }, completion: { [weak self] (image, _) in
                        if let image = image as? UIImage {
                            self?.imageView.image = image
                        }
                    })
            }
        }
    }
    
    func configure(withArticle article: Article, obfuscated: Bool) {
        if let url = article.openableURL, !obfuscated {
            authorLabel.attributedText = formatURL(url as URL)
        } else {
            authorLabel.text = article.originalURLString
        }
        
        messageLabel.text = article.title
    }
    
    func configure(withTwitterStatus twitterStatus: TwitterStatus) {
        let author = twitterStatus.author ?? "-"
        authorLabel.attributedText = "twitter_status.on_twitter".localized(args: author).attributedString.addAttributes(authorHighlightAttributes, toSubstring: author)
        messageLabel.text = twitterStatus.message
    }

    func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let url = linkPreview?.openableURL else { return }
        delegate?.articleViewWantsToOpenURL(self, url: url as URL)
    }
    
    func viewLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        delegate?.articleViewDidLongPressView(self)
    }
    
}

extension ArticleView : TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.openURL(url)
    }
}

extension ArticleView : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !messageLabel.containslink(at: touch.location(in: messageLabel))
    }

}

extension LinkPreview {

    /// Returns a `NSURL` that can be openened using `-openURL:` on `UIApplication` or `nil` if no openable `NSURL` could be created.
    var openableURL: NSURL? {
        let application = UIApplication.shared

        if let originalURL = NSURL(string: originalURLString), application.canOpenURL(originalURL as URL) {
            return originalURL
        } else if let permanentURL = permanentURL, application.canOpenURL(permanentURL) {
            return permanentURL as NSURL?
        }

        return nil
    }
}

