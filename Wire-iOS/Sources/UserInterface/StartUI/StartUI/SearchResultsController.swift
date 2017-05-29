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
import WireSyncEngine

extension SearchResult {
    
    var isEmpty : Bool {
        return contacts.count == 0 && teamMembers.count == 0 && conversations.count == 0 && directory.count == 0
    }
    
}

@objc
public protocol SearchResultsControllerDelegate {
    
    func searchResultsController(_ searchResultsController: SearchResultsController, didTapOnUser user: ZMSearchableUser, indexPath: IndexPath, section: SearchResultsControllerSection)
    func searchResultsController(_ searchResultsController: SearchResultsController, didDoubleTapOnUser user: ZMSearchableUser, indexPath: IndexPath)
    func searchResultsController(_ searchResultsController: SearchResultsController, didTapOnConversation conversation: ZMConversation)
    func searchResultsController(_ searchResultsController: SearchResultsController, didReceiveEmptyResult empty: Bool, mode: SearchResultsControllerMode)
    
}

@objc
public enum SearchResultsControllerMode : Int {
    case search
    case selection
    case list
}

@objc
public enum SearchResultsControllerSection : Int {
    case unknown
    case topPeople
    case contacts
    case teamMembers
    case conversations
    case directory
}

@objc
public class SearchResultsController : NSObject {
    
    let searchDirectory : SearchDirectory
    let collectionView : UICollectionView
    let userSelection: UserSelection
    
    let sectionAggregator : CollectionViewSectionAggregator
    let contactsSection : UsersInContactsSection
    let teamMemberSection : UsersInContactsSection
    let directorySection : UsersInDirectorySection
    let conversationsSection : GroupConversationsSection
    let topPeopleSection : TopPeopleLineSection
    
    var team: Team?
    var pendingSearchTask : SearchTask? = nil
    
    public weak var delegate : SearchResultsControllerDelegate? = nil
    
    public var mode : SearchResultsControllerMode = .search {
        didSet{
            updateVisibleSections()
        }
    }
    
    deinit {
        searchDirectory.tearDown()
    }
    
    @objc
    public init(collectionView: UICollectionView, userSelection: UserSelection, team: Team?) {
        self.collectionView = collectionView
        self.searchDirectory = SearchDirectory(userSession: ZMUserSession.shared()!)
        self.userSelection = userSelection
        self.team = team
        self.mode = .list
        
        let teamName = team?.name ?? ""
        
        sectionAggregator = CollectionViewSectionAggregator()
        sectionAggregator.collectionView = collectionView
        contactsSection = UsersInContactsSection()
        contactsSection.userSelection = userSelection
        contactsSection.title = team != nil ? "peoplepicker.header.contacts_personal".localized : "peoplepicker.header.contacts".localized
        teamMemberSection = UsersInContactsSection()
        teamMemberSection.userSelection = userSelection
        teamMemberSection.title = "peoplepicker.header.team_members".localized(args: teamName)
        directorySection = UsersInDirectorySection()
        conversationsSection = GroupConversationsSection()
        conversationsSection.title = team != nil ? "peoplepicker.header.team_conversations".localized(args: teamName) : "peoplepicker.header.conversations".localized
        topPeopleSection = TopPeopleLineSection()
        topPeopleSection.userSelection = userSelection
        topPeopleSection.topConversationDirectory = ZMUserSession.shared()?.topConversationsDirectory
        
        super.init()
        
        contactsSection.delegate = self
        teamMemberSection.delegate = self
        directorySection.delegate = self
        topPeopleSection.delegate = self
        
        updateVisibleSections()
    }
    
    @objc
    public func cancelPreviousSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
    }
    
    @objc
    public func search(withQuery query: String, local: Bool = false) {
        pendingSearchTask?.cancel()
        
        let searchOptions : SearchOptions = local ? [.contacts, .teamMembers] : [.conversations, .contacts, .teamMembers, .directory]
        let request = SearchRequest(query: query, searchOptions:searchOptions, team: team)
        let task = searchDirectory.perform(request)
        
        task.onResult { [weak self] (result, isCompleted) in
            guard let `self` = self else { return }
            
            self.updateSections(withSearchResult: result)
            
            if isCompleted {
                self.delegate?.searchResultsController(self, didReceiveEmptyResult: result.isEmpty, mode: .search)
            }
        }
        
        task.start()
        
        pendingSearchTask = task
    }
    
    @objc
    func searchContactList() {
        pendingSearchTask?.cancel()
        
        let request = SearchRequest(query: "", searchOptions: [.contacts, .teamMembers], team: team)
        let task = searchDirectory.perform(request)
        
        task.onResult { [weak self] (result, isCompleted) in
            guard let `self` = self else { return }
            
            self.updateSections(withSearchResult: result)
            
            if isCompleted {
                self.delegate?.searchResultsController(self, didReceiveEmptyResult: result.isEmpty, mode: .list)
            }
        }
        
        task.start()
        
        pendingSearchTask = task
    }
    
    func updateVisibleSections() {
        var sections : [CollectionViewSectionController]
        
        switch (mode, team != nil) {
        case (.search, false):
            sections = [contactsSection, conversationsSection, directorySection]
        case (.search, true):
            sections = [teamMemberSection, conversationsSection, contactsSection, directorySection]
        case (.selection, false):
            sections = [contactsSection]
        case (.selection, true):
            sections = [teamMemberSection, contactsSection]
        case (.list, false):
            sections = [topPeopleSection, contactsSection]
        case (.list, true):
            sections = [teamMemberSection]
        }
        
        sectionAggregator.sectionControllers = sections
    }

    func updateSections(withSearchResult searchResult: SearchResult) {
        contactsSection.contacts = searchResult.contacts
        teamMemberSection.contacts = searchResult.teamMembers.flatMap({ $0.user })
        directorySection.suggestions = searchResult.directory
        conversationsSection.groupConversations = searchResult.conversations
        
        collectionView.reloadData()
    }
    
    func sectionFor(controller: CollectionViewSectionController) -> SearchResultsControllerSection {
        if controller === topPeopleSection {
            return .topPeople
        } else if controller === contactsSection {
            return .contacts
        } else if controller === teamMemberSection {
            return .teamMembers
        } else if  controller === conversationsSection {
            return .conversations
        } else if controller === directorySection {
            return .directory
        } else {
            return .unknown
        }
    }
    
}

extension SearchResultsController : CollectionViewSectionDelegate {
    
    public func collectionViewSectionController(_ controller: CollectionViewSectionController!, indexPathForItemIndex itemIndex: UInt) -> IndexPath! {
        let section = sectionAggregator.visibleSectionControllers.index(where: { $0 === controller }) ?? 0
        return IndexPath(row: Int(itemIndex), section: section)
    }
    
    public func collectionViewSectionController(_ controller: CollectionViewSectionController!, didSelectItem item: Any!, at indexPath: IndexPath!) {
        if let user = item as? ZMUser {
            delegate?.searchResultsController(self, didTapOnUser: user, indexPath: indexPath, section: sectionFor(controller: controller))
        }
        else if let searchUser = item as? ZMSearchUser {
            delegate?.searchResultsController(self, didTapOnUser: searchUser, indexPath: indexPath, section: sectionFor(controller: controller))
        }
        else if let conversation = item as? ZMConversation {
            delegate?.searchResultsController(self, didTapOnConversation: conversation)
        }
    }
    
    public func collectionViewSectionController(_ controller: CollectionViewSectionController!, didDoubleTapItem item: Any!, at indexPath: IndexPath!) {
        if let user = item as? ZMUser {
            delegate?.searchResultsController(self, didDoubleTapOnUser: user, indexPath: indexPath)
        }
        else if let searchUser = item as? ZMSearchUser {
            delegate?.searchResultsController(self, didDoubleTapOnUser: searchUser, indexPath: indexPath)
        }
    }
    
    public func collectionViewSectionController(_ controller: CollectionViewSectionController!, didDeselectItem item: Any!, at indexPath: IndexPath!) {
        
    }
}
