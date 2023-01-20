// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import CoreTelephony
import WireTransport

extension String {
    static func phoneNumber(withE164 e164: UInt, number: String) -> String {
        return "+\(e164)\(number)"
    }
}

final class Country: NSObject {
    let iso: String

    // this property has to be marked @objc for NSPredicate key
    @objc
    let e164: UInt

    class var defaultCountry: Country {

        #if WIRESTAN
        if BackendEnvironment.shared.environmentType.value == .staging {
            return Country.countryWirestan
        }

        #endif

        return Country.countryFromDevice ?? Country(iso: "us", e164: 1)
    }

    init(iso: String, e164: UInt) {
        self.iso = iso
        self.e164 = e164

        super.init()
    }

    class func detect(fromCode e164: UInt) -> Country? {
        return self.detectCountry(withMatcher: { country in
            return country?.e164 ?? 0 == e164
        })
    }

    // Normalized phone number required: "1234567890" instead of "+1 (23) 456-78-90"
    class func detect(forPhoneNumber phoneNumber: String) -> Country? {
        return detectCountry(withMatcher: { country in
            return phoneNumber.hasPrefix(country?.e164PrefixString ?? "")
        })
    }

    class func detectCountry(withMatcher matcher: @escaping (Country?) -> Bool) -> Country? {
        let matches = allCountries?.filter(matcher) ?? []

        // One or no matches is trivial case
        if matches.count <= 1 {
            return matches.first
        }

        // If country from device is in match list, probably it is desired by user

        if let countryFromDevice = Country.countryFromDevice, matches.contains(countryFromDevice) {
            return countryFromDevice
        }

        // List to prioritize main countries with shared prefixes (e.g., USA with "+1")
        let priorityList = ["us", "it", "fi", "tz", "uk", "no", "ru"]

        return matches.first {
            priorityList.contains($0.iso)
        }

    }

    class var allCountries: [Country]? {

        var countries: [Country] = []

        #if WIRESTAN
        countries.append(Country.countryWirestan)
        #endif

        guard let countryCodeDict = [String: AnyObject].contentsOf(url: Bundle.main.url(forResource: "CountryCodes", withExtension: "plist")!),
              let countryCodes = countryCodeDict["countryCodes"] as? [[String: Any]] else {
            return countries
        }

            for countryData in countryCodes {

                if let iso = countryData["iso"] as? String,
                    let e164 = countryData["e164"] as? UInt {

                countries.append(Country(iso: iso, e164: e164))
                }
            }

        return countries
    }

    #if WIRESTAN
    /// A fake country with +0 country code. Used only on edge and staging environments
    class var countryWirestan: Country {
        return Country(iso: "WIS", e164: 0)
    }

    #endif

    // this property has to be marked @objc for NSPredicate key
    @objc
    var displayName: String {
        #if WIRESTAN
        if iso == "WIS" {
            return "Wirestan ☀️"
        }
        #endif
        var localized = Locale.current.localizedString(forRegionCode: iso)

        if localized?.isEmpty ?? true {
            // Try the fallback locale
            let USLocale = NSLocale(localeIdentifier: "en_US")
            localized = USLocale.displayName(forKey: .countryCode, value: iso)
        }

        if localized?.isEmpty ?? true {
            // Return something instead of just @c nil
            return iso.uppercased()
        }
        return localized ?? ""
    }

    // E.g. "+1", "+49", "+380"
    var e164PrefixString: String {
        return "+\(e164)"
    }

    ///  Return a Country form country code of carrier. If carrier not exists, get the country from current locale
    ///
    /// - Returns: a Country object
    class var countryFromDevice: Country? {
        let networkInfo = CTTelephonyNetworkInfo()

        let carrier: CTCarrier?
            /// Get the carrier from first cellular provider which has isoCountryCode
        carrier = networkInfo.serviceSubscriberCellularProviders?.values.first(where: { $0.isoCountryCode != nil })

        if let isoCountryCode = carrier?.isoCountryCode {
            return Country.country(with: isoCountryCode)
        } else {
            return Country.country(with: NSLocale.current.regionCode?.lowercased())
        }
    }

    private class func country(with iso: String?) -> Country? {
        guard let iso = iso else { return nil }

        return allCountries?.first(where: { $0.iso == iso })
    }

}

extension Dictionary {
    static func contentsOf(url: URL) -> [String: AnyObject]? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) else {
                return nil
        }

        return plist as? [String: AnyObject]
    }
}
