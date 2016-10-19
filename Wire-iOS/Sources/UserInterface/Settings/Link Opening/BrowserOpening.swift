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


enum BrowserOpeningOption: Int, LinkOpeningOption {

    case safari, chrome, firefox

    static var allOptions: [BrowserOpeningOption] {
        return [.safari, .chrome, .firefox]
    }

    var displayString: String {
        switch self {
        case .safari: return "open_link.browser.option.safari".localized
        case .chrome: return "open_link.browser.option.chrome".localized
        case .firefox: return "open_link.browser.option.firefox".localized
        }
    }

    var isAvailable: Bool {
        switch self {
        case .safari: return true
        case .chrome: return UIApplication.shared.chromeInstalled
        case .firefox: return UIApplication.shared.firefoxInstalled
        }
    }

}

extension URL {

    func openAsLink() -> Bool {
        let saved = BrowserOpeningOption(rawValue: Settings.shared().browserLinkOpeningOptionRawValue) ?? .safari
        switch saved {
        case .safari: return false
        case .chrome:
            guard let url = chromeURL else { return false }
            return UIApplication.shared.openURL(url)
        case .firefox:
            guard let url = firefoxURL else { return false }
            return UIApplication.shared.openURL(url)
        }
    }

}


// MARK: - Private


fileprivate extension UIApplication {

    var chromeInstalled: Bool {
        return canHandleScheme("googlechrome://")
    }

    var firefoxInstalled: Bool {
        return canHandleScheme("firefox://")
    }

}


fileprivate extension URL {

    var chromeURL: URL? {
        if absoluteString.contains("http://") {
            return URL(string: "googlechrome://\(absoluteString.replacingOccurrences(of: "http://", with: ""))")
        }
        if absoluteString.contains("https://") {
            return URL(string: "googlechromes://\(absoluteString.replacingOccurrences(of: "https://", with: ""))")
        }
        return URL(string: "googlechrome://\(absoluteString)")
    }

    var firefoxURL: URL? {
        return URL(string: "firefox://open-url?url=\(absoluteString)")
    }
    
}
