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

extension CountryCodeBaseTableViewController {

    override open func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(CountryCell.self, forCellReuseIdentifier: CountryCodeCellIdentifier)
    }

    @objc(configureCell:forCountry:)
    func configureCell(_ cell: UITableViewCell, for country: Country) {
        cell.textLabel?.text = country.displayName
        cell.detailTextLabel?.text = "+\(country.e164)"

        cell.accessibilityHint = "registration.phone.country_code.hint".localized
    }
}

final class CountryCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

@objc protocol CountryCodeTableViewControllerDelegate: NSObjectProtocol {
    @objc optional func countryCodeTableViewController(_ viewController: UIViewController?, didSelect country: Country?)
}

final class CountryCodeTableViewController: CountryCodeBaseTableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    weak var delegate: CountryCodeTableViewControllerDelegate?
    private var sections: [AnyHashable]?
    private var sectionTitles: [AnyHashable]?
    private var searchController: UISearchController?
    private var resultsTableViewController: CountryCodeResultsTableViewController?

    func viewDidLoad() {
        super.viewDidLoad()
        
        createDataSource()
        
        resultsTableViewController = CountryCodeResultsTableViewController()
        searchController = UISearchController(searchResultsController: resultsTableViewController)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.sizeToFit()
        if #available(iOS 11.0, *) {
            navigationItem?.searchController = searchController
            navigationItem?.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController?.searchBar
        }
        tableView.sectionIndexBackgroundColor = UIColor.clear
        
        resultsTableViewController.tableView.delegate = self
        searchController?.delegate = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        searchController?.searchBar.backgroundColor = UIColor.white
        
        navigationItem?.rightBarButtonItem = navigationController?.closeItem()
        
        definesPresentationContext = true
        title = NSLocalizedString("registration.country_select.title", comment: "").localizedUppercase
    }
    
    func dismiss(_ sender: Any?) {
        dismiss(animated: true)
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        // Update the filtered array based on the search text
        let searchText = searchController.searchBar.text
        var searchResults = sections.value(forKeyPath: "@unionOfArrays.self") as? [AnyHashable]
        
        // Strip out all the leading and trailing spaces
        let strippedString = searchText?.trimmingCharacters(in: CharacterSet.whitespaces)
        
        // Break up the search terms (separated by spaces)
        var searchItems: [AnyHashable]? = nil
        if (strippedString?.count ?? 0) > 0 {
            searchItems = strippedString?.components(separatedBy: " ")
        }
        
        var searchItemPredicates: [AnyHashable] = []
        var numberPredicates: [AnyHashable] = []
        for searchString in searchItems ?? [] {
            guard let searchString = searchString as? String else {
                continue
            }
            let displayNamePredicate = NSPredicate(format: "displayName CONTAINS[cd] %@", searchString)
            searchItemPredicates.append(displayNamePredicate)
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .none
            let targetNumber = numberFormatter.number(from: searchString)
            
            if targetNumber != nil {
                var e164Predicate: NSPredicate? = nil
                if let targetNumber = targetNumber {
                    e164Predicate = NSPredicate(format: "e164 == %@", targetNumber)
                }
                if let e164Predicate = e164Predicate {
                    numberPredicates.append(e164Predicate)
                }
            }
        }
        
        var andPredicates: NSCompoundPredicate? = nil
        if let searchItemPredicates = searchItemPredicates as? [NSPredicate] {
            andPredicates = NSCompoundPredicate(andPredicateWithSubpredicates: searchItemPredicates)
        }
        let orPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: numberPredicates)
        let finalPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [andPredicates, orPredicates])
        
        searchResults = searchResults.filtered(using: finalPredicate)
        
        // Hand over the filtered results to our search results table
        let tableController = self.searchController?.searchResultsController as? CountryCodeResultsTableViewController
        tableController?.filteredCountries = searchResults
        tableController?.tableView.reloadData()
    }
}

