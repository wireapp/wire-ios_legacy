//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension CountryCodeTableViewController {
    @objc
    func createDataSource() {
        guard let countries = Country.allCountries else { return }

        let selector = #selector(getter: Country.displayName)
        let sectionTitlesCount = UILocalizedIndexedCollation.current().sectionTitles.count

        var mutableSections: [[Any]] = []
        for _ in 0..<sectionTitlesCount {
            mutableSections.append([Country]())
        }

        for country in countries {
            let sectionNumber = UILocalizedIndexedCollation.current().section(for: country, collationStringSelector: selector)
            mutableSections[sectionNumber].append(country)
        }

        for idx in 0..<sectionTitlesCount {
            let objectsForSection = mutableSections[idx]
            mutableSections[idx] = UILocalizedIndexedCollation.current().sortedArray(from: objectsForSection, collationStringSelector: selector)
        }

        #if WIRESTAN
        mutableSections[0].insert(Country.countryWirestan, at: 0)
        #endif

        sections = mutableSections
    }
}
