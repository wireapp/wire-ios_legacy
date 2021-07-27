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
import UIKit

protocol CountryCodeTableViewControllerDelegate: class {
    func countryCodeTableViewController(_ viewController: UIViewController, didSelect country: Country)
}

final class CountryCodeTableViewController: UITableViewController, UISearchControllerDelegate {
    weak var delegate: CountryCodeTableViewControllerDelegate?
    private lazy var sections: [[Country]] = {

        guard let countries = Country.allCountries else { return [] }

        let selector = #selector(getter: Country.displayName)
        let sectionTitlesCount = UILocalizedIndexedCollation.current().sectionTitles.count

        var mutableSections: [[Country]] = []
        for _ in 0..<sectionTitlesCount {
            mutableSections.append([Country]())
        }

        for country in countries {
            let sectionNumber = UILocalizedIndexedCollation.current().section(for: country, collationStringSelector: selector)
            mutableSections[sectionNumber].append(country)
        }

        for idx in 0..<sectionTitlesCount {
            let objectsForSection = mutableSections[idx]
            if let countries =  UILocalizedIndexedCollation.current().sortedArray(from: objectsForSection, collationStringSelector: selector) as? [Country] {

                mutableSections[idx] = countries
            }
        }

        #if WIRESTAN
        mutableSections[0].insert(Country.countryWirestan, at: 0)
        #endif

        return mutableSections
    }()

    lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: resultsTableViewController)
    }()
    private let resultsTableViewController: CountryCodeResultsTableViewController = CountryCodeResultsTableViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        CountryCell.register(in: tableView)

        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        tableView.sectionIndexBackgroundColor = UIColor.clear

        resultsTableViewController.tableView.delegate = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.backgroundColor = UIColor.white

        navigationItem.rightBarButtonItem = navigationController?.closeItem()

        definesPresentationContext = true
        title = NSLocalizedString("registration.country_select.title", comment: "").localizedUppercase
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCountry: Country?
        if resultsTableViewController.tableView == tableView {
            selectedCountry = resultsTableViewController.filteredCountries?[indexPath.row]
            searchController.isActive = false
        } else {
            selectedCountry = sections[indexPath.section][indexPath.row]
        }

        if let selectedCountry = selectedCountry {
            delegate?.countryCodeTableViewController(self, didSelect: selectedCountry)
        }
    }

    // MARK: - TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: CountryCell.self, for: indexPath)

        cell.configure(for: sections[indexPath.section][indexPath.row])

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return UILocalizedIndexedCollation.current().sectionTitles[section]
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return UILocalizedIndexedCollation.current().sectionIndexTitles
    }
}

// MARK: - UISearchBarDelegate

extension CountryCodeTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UISearchResultsUpdating

/// TODO: test
extension CountryCodeTableViewController: UISearchResultsUpdating {

    func filter(searchText: String?) -> [Any]? {
        guard var searchResults: [Any] = (sections as NSArray).value(forKeyPath: "@unionOfArrays.self") as? [Any] else { return nil}

        // Strip out all the leading and trailing spaces
        let strippedString = searchText?.trimmingCharacters(in: CharacterSet.whitespaces)

        // Break up the search terms (separated by spaces)
        let searchItems: [String]
        if strippedString?.isEmpty == false {
            searchItems = strippedString?.components(separatedBy: " ") ?? []
        } else {
            searchItems = []
        }

        var searchItemPredicates: [NSPredicate] = []
        var numberPredicates: [NSPredicate] = []
        for searchString in searchItems {
            let displayNamePredicate = NSPredicate(format: "displayName CONTAINS[cd] %@", searchString)
            searchItemPredicates.append(displayNamePredicate)

            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .none

            if let targetNumber = numberFormatter.number(from: searchString) {
                numberPredicates.append(NSPredicate(format: "e164 == %@", targetNumber))
            }
        }

        let andPredicates: NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: searchItemPredicates)

        let orPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: numberPredicates)
        let finalPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [andPredicates, orPredicates])

        searchResults = searchResults.filter {
            finalPredicate.evaluate(with: $0)
        }

        return searchResults
    }

    func updateSearchResults(for searchController: UISearchController) {
        // Update the filtered array based on the search text
        let searchText = searchController.searchBar.text

        guard let searchResults = filter(searchText: searchText) else { return }

        // Hand over the filtered results to our search results table
        let tableController = self.searchController.searchResultsController as? CountryCodeResultsTableViewController
        tableController?.filteredCountries = searchResults as? [Country]
        tableController?.tableView.reloadData()
    }

}
