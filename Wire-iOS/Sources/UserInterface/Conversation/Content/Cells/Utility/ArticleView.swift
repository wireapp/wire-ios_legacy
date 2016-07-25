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

@objc protocol ArticleViewDelegate: class {
    func articleViewWantsToOpenURL(articleView: ArticleView, url: NSURL)
    func articleViewDidLongPressView(articleView: ArticleView)
}

class ArticleView: UIView {
    
    /// MARK - Styling
    var containerColor: UIColor?
    var titleTextColor: UIColor?
    var titleFont: UIFont?
    var authorTextColor: UIColor?
    var authorFont: UIFont?
    var authorHighlightTextColor: UIColor = UIColor.grayColor()
    var authorHighlightFont: UIFont = UIFont.boldSystemFontOfSize(14)
    
    /// MARK - Views
    let messageLabel = TTTAttributedLabel(frame: CGRectZero)
    let authorLabel = UILabel()
    let imageView = UIImageView()
    var loadingView: ThreeDotsLoadingView?
    var linkPreview: LinkPreview?
    weak var delegate: ArticleViewDelegate?
    
    init(withImagePlaceholder imagePlaceholder: Bool) {
        super.init(frame: CGRectZero)

        [messageLabel, authorLabel, imageView].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        if (imagePlaceholder) {
            let loadingView = ThreeDotsLoadingView()
            imageView.addSubview(loadingView)
            imageView.isAccessibilityElement = true
            imageView.accessibilityIdentifier = "linkPreviewImage"
            self.loadingView = loadingView
        }
        
        CASStyler.defaultStyler().styleItem(self)
        
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
        
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        
        authorLabel.font = authorFont
        authorLabel.textColor = authorTextColor
        authorLabel.lineBreakMode = .ByTruncatingMiddle
        authorLabel.accessibilityIdentifier = "linkPreviewSource"
        
        messageLabel.font = titleFont
        messageLabel.textColor = titleTextColor
        messageLabel.numberOfLines = 0
        messageLabel.accessibilityIdentifier = "linkPreviewContent"
        messageLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        messageLabel.linkAttributes = [NSForegroundColorAttributeName : UIColor.accentColor()]
        messageLabel.activeLinkAttributes = [NSForegroundColorAttributeName : UIColor.accentColor().colorWithAlphaComponent(0.5)]
        messageLabel.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(viewLongPressed)))
    }
    
    func setupConstraints(imagePlaceholder: Bool) {
        let imageHeight : CGFloat = imagePlaceholder ? 144 : 0
        
        constrain(self, messageLabel, authorLabel, imageView) { container, messageLabel, authorLabel, imageView in
            imageView.left == container.left
            imageView.top == container.top
            imageView.right == container.right
            imageView.height == imageHeight ~ 999
            
            messageLabel.left == container.left + 12
            messageLabel.top == imageView.bottom + 12
            messageLabel.right == container.right - 12
            
            authorLabel.left == container.left + 12
            authorLabel.right == container.right - 12
            authorLabel.top == messageLabel.bottom + 8
            authorLabel.bottom == container.bottom - 12
        }
        
        if let loadingView = self.loadingView {
            constrain(imageView, loadingView) {imageView, loadingView in
                loadingView.center == imageView.center
            }
        }
    }
    
    var authorHighlightAttributes : [String: AnyObject] {
        get {
            return [NSFontAttributeName : authorHighlightFont, NSForegroundColorAttributeName: authorHighlightTextColor]
        }
    }
    
    func formatURL(URL: NSURL) -> NSAttributedString {
        let urlWithoutScheme = URL.absoluteString.stringByRemovingURLScheme(URL.scheme)
        let displayString = urlWithoutScheme.stringByRemovingPrefixWWW().stringByRemovingTrailingForwardSlash()

        if let host = URL.host?.stringByRemovingPrefixWWW() {
            return displayString.attributedString.addAttributes(authorHighlightAttributes, toSubstring: host)
        } else {
            return displayString.attributedString
        }
    }
    
    static var imageCache : ImageCache  = {
        let cache = ImageCache(name: "ArticleView.imageCache")
        cache.maxConcurrentOperationCount = 4;
        cache.totalCostLimit = 1024 * 1024 * 10; // 10 MB
        cache.qualityOfService = .Utility;
        return cache
    }()
    
    func configure(withTextMessageData textMessageData: ZMTextMessageData) {
        guard let linkPreview = textMessageData.linkPreview else { return }
        self.linkPreview = linkPreview

        if let article = linkPreview as? Article {
            configure(withArticle: article)
        }
        
        if let twitterStatus = linkPreview as? TwitterStatus {
            configure(withTwitterStatus: twitterStatus)
        }
        
        if let imageData = textMessageData.imageData {
            imageView.image = UIImage(data: imageData)
            loadingView?.hidden = true
            
            ArticleView.imageCache.imageForData(imageData, cacheKey: textMessageData.imageDataIdentifier, creationBlock:
                { data -> AnyObject! in
                    return UIImage.deviceOptimizedImageFromData(data)
                }, completion:
                {[weak self] (image, _) in
                    if let image = image as? UIImage {
                        self?.imageView.image = image
                    }
            })
        }
    }
    
    func configure(withArticle article: Article) {
        if let url = article.openableURL {
            authorLabel.attributedText = formatURL(url)
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
    
    func viewTapped(sender: UITapGestureRecognizer) {
        guard let url = linkPreview?.openableURL else { return }
        delegate?.articleViewWantsToOpenURL(self, url: url)
    }
    
    func viewLongPressed(sender: UILongPressGestureRecognizer) {
        guard sender.state == .Began else { return }
        delegate?.articleViewDidLongPressView(self)
    }
    
}

extension ArticleView : TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}

extension ArticleView : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return !messageLabel.containslinkAtPoint(touch.locationInView(messageLabel))
    }

}

extension LinkPreview {

    /// Returns a `NSURL` that can be openened using `-openURL:` on `UIApplication` or `nil` if no openable `NSURL` could be created.
    var openableURL: NSURL? {
        let application = UIApplication.sharedApplication()

        if let permanentURL = permanentURL where application.canOpenURL(permanentURL) {
            return permanentURL
        } else if let originalURL = NSURL(string: originalURLString) where application.canOpenURL(originalURL) {
            return originalURL
        }

        return nil
    }

}

// MARK: - URL Formatting

private extension String {

    func stringByRemovingPrefixWWW() -> String {
        return stringByReplacingOccurrencesOfString("www.", withString: "", options: .AnchoredSearch, range: nil)
    }

    func stringByRemovingTrailingForwardSlash() -> String {
        return stringByReplacingOccurrencesOfString("/", withString: "", options: [.AnchoredSearch, .BackwardsSearch], range: nil)
    }

    func stringByRemovingURLScheme(scheme: String) -> String {
        return stringByReplacingOccurrencesOfString(scheme + "://", withString: "", options: .AnchoredSearch, range: nil)
    }

}
