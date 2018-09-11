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


private let log = ZMSLog(tag: "link opening")


enum MapsOpeningOption: Int, LinkOpeningOption {


    case apple, google

    static var allOptions: [MapsOpeningOption] {
        return [.apple, .google]
    }

    var displayString: String {
        switch self {
        case .apple: return "open_link.maps.option.apple".localized
        case .google: return "open_link.maps.option.google".localized
        }
    }

    var isAvailable: Bool {
        switch self {
        case .apple: return true
        case .google: return UIApplication.shared.googleMapsInstalled
        }
    }

    static func storedPreference() -> MapsOpeningOption {
        return MapsOpeningOption(rawValue: Settings.shared().mapsLinkOpeningOptionRawValue) ?? .apple
    }

}


extension URL {

    public func openAsLocation() -> Bool {
        log.debug("Trying to open \"\(self)\" as location")
        let saved = MapsOpeningOption.storedPreference()
        log.debug("Saved option to open a location: \(saved.displayString)")

        switch saved {
        case .apple: return false
        case .google:
            guard UIApplication.shared.canOpenURL(self) else { return false }
            UIApplication.shared.open(self)
            return true
        }
    }
    
}


// MARK: - Private


fileprivate extension UIApplication {

    var googleMapsInstalled: Bool {
        return canHandleScheme("comgooglemaps://")
    }

}
