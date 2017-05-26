//
//  SearchResultsController.swift
//  Wire-iOS
//
//  Created by Jacob on 22.05.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import WireSyncEngine


@objc
public protocol SearchResultsControllerDelegate {
    
    func searchResultsController(_ searchResultsController: SearchResultsController, didTapOnUser user: ZMSearchableUser, indexPath: IndexPath)
    func searchResultsController(_ searchResultsController: SearchResultsController, didDoubleTapOnUser user: ZMSearchableUser, indexPath: IndexPath)
    func searchResultsController(_ searchResultsController: SearchResultsController, didTapOnConversation conversation: ZMConversation)
    
}

@objc
public enum SearchResultsControllerMode : Int {
    case search
    case selection
    case list
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
        
        sectionAggregator = CollectionViewSectionAggregator()
        sectionAggregator.collectionView = collectionView
        contactsSection = UsersInContactsSection()
        contactsSection.userSelection = userSelection
        contactsSection.title = "peoplepicker.header.contacts".localized
        teamMemberSection = UsersInContactsSection()
        teamMemberSection.userSelection = userSelection
        teamMemberSection.title = "peoplepicker.header.team_members".localized
        directorySection = UsersInDirectorySection()
        conversationsSection = GroupConversationsSection()
        conversationsSection.title = team != nil ? "peoplepicker.header.team_conversations".localized : "peoplepicker.header.conversations".localized
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
    public func search(withQuery query: String, local: Bool = false) {
        pendingSearchTask?.cancel()
        
        let searchOptions : SearchOptions = local ? [.contacts, .teamMembers] : [.conversations, .contacts, .teamMembers, .directory]
        let request = SearchRequest(query: query, searchOptions:searchOptions, team: team)
        let task = searchDirectory.perform(request)
        
        task.onResult { [weak self] (result, _) in
            self?.updateSections(withSearchResult: result)
        }
        
        task.start()
        
        pendingSearchTask = task
    }
    
    @objc
    func searchContactList() {
        pendingSearchTask?.cancel()
        
        let request = SearchRequest(query: "", searchOptions: [.contacts, .teamMembers], team: team)
        let task = searchDirectory.perform(request)
        
        task.onResult { [weak self] (result, _) in
            self?.updateSections(withSearchResult: result)
        }
        
        task.start()
        
        pendingSearchTask = task
    }
    
    func updateVisibleSections() {
        var sections : [CollectionViewSectionController]
        
        switch (mode, team != nil) {
        case (.search, false):
            sections = [contactsSection, conversationsSection, directorySection]
            break
        case (.search, true):
            sections = [teamMemberSection, conversationsSection, contactsSection, directorySection]
            break
        case (.selection, false):
            sections = [contactsSection]
            break
        case (.selection, true):
            sections = [teamMemberSection, contactsSection]
            break
        case (.list, false):
            sections = [topPeopleSection, contactsSection]
            break
        case (.list, true):
            sections = [teamMemberSection]
            break
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
    
}

extension SearchResultsController : CollectionViewSectionDelegate {
    
    public func collectionViewSectionController(_ controller: CollectionViewSectionController!, indexPathForItemIndex itemIndex: UInt) -> IndexPath! {
        let section = sectionAggregator.visibleSectionControllers.index(where: { $0 === controller }) ?? 0
        return IndexPath(row: Int(itemIndex), section: section)
    }
    
    public func collectionViewSectionController(_ controller: CollectionViewSectionController!, didSelectItem item: Any!, at indexPath: IndexPath!) {
        if let user = item as? ZMUser {
            delegate?.searchResultsController(self, didTapOnUser: user, indexPath: indexPath)
        }
        else if let searchUser = item as? ZMSearchUser {
            delegate?.searchResultsController(self, didTapOnUser: searchUser, indexPath: indexPath)
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
