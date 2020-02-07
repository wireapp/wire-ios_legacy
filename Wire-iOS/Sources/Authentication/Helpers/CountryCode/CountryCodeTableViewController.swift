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

final class CountryCodeTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    weak var delegate: CountryCodeTableViewControllerDelegate?
    private var sections: [[Any]]?
    private var sectionTitles: [AnyHashable]?
    lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: resultsTableViewController)
    }()
    private let resultsTableViewController: CountryCodeResultsTableViewController = CountryCodeResultsTableViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CountryCell.register(in: tableView)
        
        createDataSource()
        
        
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
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.backgroundColor = UIColor.white
        
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        
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
        var searchResults: NSArray = (sections as NSArray?)?.value(forKeyPath: "@unionOfArrays.self") as! NSArray
        
        // Strip out all the leading and trailing spaces
        let strippedString = searchText?.trimmingCharacters(in: CharacterSet.whitespaces)
        
        // Break up the search terms (separated by spaces)
        var searchItems: [AnyHashable]? = nil
        if strippedString?.isEmpty == false {
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
        let orPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: numberPredicates as! [NSPredicate])
        let finalPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [andPredicates!, orPredicates])
        
        searchResults = searchResults.filtered(using: finalPredicate) as NSArray
        
        // Hand over the filtered results to our search results table
        let tableController = self.searchController.searchResultsController as? CountryCodeResultsTableViewController
        tableController?.filteredCountries = searchResults as? [AnyHashable]
        tableController?.tableView.reloadData()
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCountry: Country?
        if resultsTableViewController.tableView == tableView {
            selectedCountry = resultsTableViewController.filteredCountries?[indexPath.row] as? Country
            searchController.isActive = false
        } else {
            selectedCountry = sections?[indexPath.section][indexPath.row] as? Country
        }
        
        delegate?.countryCodeTableViewController(self, didSelect: selectedCountry!)
    }
    
    // MARK: - TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections?[section].count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: CountryCell.self, for: indexPath)

        configureCell(cell, for: sections?[indexPath.section][indexPath.row] as! Country)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return UILocalizedIndexedCollation.current().sectionTitles[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return UILocalizedIndexedCollation.current().sectionIndexTitles
    }
    
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
