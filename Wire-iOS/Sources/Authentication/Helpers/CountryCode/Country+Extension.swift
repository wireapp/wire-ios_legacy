
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

extension Country {

    ///  Return a Country form country code of carrier. If carrier not exists, get the country from current locale
    ///
    /// - Returns: a Country object
    @objc
    class func countryFromDevice() -> Country? {
        let networkInfo = CTTelephonyNetworkInfo()

        let carrier: CTCarrier?
        if #available(iOS 12, *) {
            /// Get the carrier from first cellular provider which has isoCountryCode
            carrier = networkInfo.serviceSubscriberCellularProviders?.values.filter{$0.isoCountryCode != nil}.first
        } else {
            carrier = networkInfo.subscriberCellularProvider
        }
        
        if let isoCountryCode = carrier?.isoCountryCode {
            return Country.countryWithISO(iso: isoCountryCode)
        } else {
            return Country.countryWithISO(iso: NSLocale.current.regionCode?.lowercased())
        }
    }

    private class func countryWithISO(iso: String?) -> Country? {
        guard let iso = iso else { return nil }
        
        for country in allCountries() {
            if let country = country as? Country,
                country.iso == iso {
                return country
            }
        }

        return nil
    }

}

