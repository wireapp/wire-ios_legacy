//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension ContactsDataSource {
    
    @objc
    public func search(withQuery query: String) {
        guard let searchDirectory = self.searchDirectory else { return }
        
        let request = SearchRequest(query: query, searchOptions: [.contacts, .addressBook])
        let task = searchDirectory.perform(request)
        
        task.onResult { [weak self] (searchResult, _) in
            guard let `self` = self else { return }
            self.ungroupedSearchResults = searchResult.addressBook
            self.delegate?.dataSource?(self, didReceiveSearchResult: searchResult.addressBook)
        }
        
        task.start()
    }
    
    
}
