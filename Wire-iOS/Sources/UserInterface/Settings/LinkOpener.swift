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

public extension NSURL {

    @objc func open() {
        (self as URL).open()
    }

}

public extension URL {

    func open() {
        let openened = openAsTweet() || openAsLocation() || openAsLink()
        if !openened {
            UIApplication.shared.openURL(self)
        }
    }

    private func openAsTweet() -> Bool {
        guard isTweet else { return false }
        let saved = TweetOpeningOption(rawValue: Settings.shared().twitterLinkOpeningOptionRawValue) ?? .none
        switch saved {
        case .none: return false
        case .tweetbot:
            guard let url = tweetbotURL else { return false }
            return UIApplication.shared.openURL(url)
        }
    }

    private func openAsLocation() -> Bool {
        return false
    }

    private func openAsLink() -> Bool {
        return false
    }

}

protocol LinkOpeningOption {

    var displayString: String { get }
    static var availableOptions: [Self] { get }
}


enum TweetOpeningOption: Int, LinkOpeningOption {

    case none, tweetbot

    var displayString: String { return displayStringKey.localized }

    private var displayStringKey: String {
        switch self {
        case .none: return "open_link.twitter.option.default"
        case .tweetbot: return "open_link.twitter.option.tweetbot"
        }
    }

    static var availableOptions: [TweetOpeningOption] {
        return [
            TweetOpeningOption.none,
            TweetOpeningOption.tweetbot
            ].filter { $0.isAvailable }
    }

    private var isAvailable: Bool {
        switch self {
        case .none: return true
        case .tweetbot: return UIApplication.shared.tweetbotInstalled
        }
    }
}

enum MapsOpeningOption: Int, LinkOpeningOption {

    case apple, google

    static var availableOptions: [MapsOpeningOption] {
        return [
            MapsOpeningOption.apple,
            MapsOpeningOption.google
            ].filter { $0.isAvailable }
    }

    internal static var displayString: String { return "open_link.maps.category.title".localized }
    var displayString: String { return displayStringKey.localized }

    private var displayStringKey: String {
        switch self {
        case .apple: return "open_link.maps.option.apple"
        case .google: return "open_link.maps.option.google"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .apple: return true
        case .google: return UIApplication.shared.googleMapsInstalled
        }
    }
}

enum BrowserOpeningOption: Int, LinkOpeningOption {

    case safari, chrome

    static var availableOptions: [BrowserOpeningOption] {
        return [
            BrowserOpeningOption.safari,
            BrowserOpeningOption.chrome
            ].filter { $0.isAvailable }
    }

    var displayString: String { return displayStringKey.localized }

    private var displayStringKey: String {
        switch self {
        case .safari: return "open_link.browser.option.safari"
        case .chrome: return "open_link.browser.option.chrome"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .safari: return true
        case .chrome: return UIApplication.shared.googleChromeInstalled
        }
    }
}

private extension UIApplication {

    var googleMapsInstalled: Bool {
        return false // TODO
    }

    var googleChromeInstalled: Bool {
        return false // TODO
    }
}

// MARK: - Tweets

private extension UIApplication {

    var tweetbotInstalled: Bool {
        guard let url = URL(string: "tweetbot://") else { return false }
        return canOpenURL(url)
    }
    
}

fileprivate extension URL {

    var isTweet: Bool {
        return absoluteString.contains("twitter.com") && absoluteString.contains("status")
    }

    var tweetbotURL: URL? {
        guard isTweet else { return nil }

        let components = [
            "https://twitter.com/",
            "http://twitter.com/",
            "http://mobile.twitter.com/",
            "https://mobile.twitter.com/"
        ]

        let tweetbot = components.reduce(absoluteString) { result, current in
            return result.replacingWithTweetbotURLScheme(current)
        }

        return URL(string: tweetbot)
    }
}

private extension String {

    func replacingWithTweetbotURLScheme(_ string: String) -> String {
        return replacingOccurrences(of: string, with: "tweetbot://")
    }

}
