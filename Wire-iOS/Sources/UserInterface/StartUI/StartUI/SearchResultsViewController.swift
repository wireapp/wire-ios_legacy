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
import UIKit

enum SearchGroup: Int {
    case people
    case services
}

extension SearchGroup {

    var accessible: Bool {
        switch self {
        case .people:
            return true
        case .services:
            return ZMUser.selfUser().canCreateService
        }
    }

#if ADD_SERVICE_DISABLED
    // remove service from the tab
    static let all: [SearchGroup] = [.people]
#else
    static var all: [SearchGroup] {
        return [.people, .services].filter { $0.accessible }
    }
#endif

    var name: String {
        switch self {
        case .people:
            return "peoplepicker.header.people".localized
        case .services:
            return "peoplepicker.header.services".localized
        }
    }
}

protocol SearchResultsViewControllerDelegate: class {

    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnUser user: UserType, indexPath: IndexPath, section: SearchResultsViewControllerSection)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didDoubleTapOnUser user: UserType, indexPath: IndexPath)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnConversation conversation: ZMConversation)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnSeviceUser user: ServiceUser)
    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, wantsToPerformAction action: SearchResultsViewControllerAction)
}

enum SearchResultsViewControllerAction: Int {
    case createGroup
    case createGuestRoom
}

enum SearchResultsViewControllerMode: Int {
    case search
    case selection
    case list
}

enum SearchResultsViewControllerSection: Int {
    case unknown
    case topPeople
    case contacts
    case teamMembers
    case conversations
    case directory
    case services
    case federation
}

extension UIViewController {
    class ControllerHierarchyIterator: IteratorProtocol {
        private var current: UIViewController

        init(controller: UIViewController) {
            current = controller
        }

        func next() -> UIViewController? {
            var candidate: UIViewController? = .none
            if let controller = current.navigationController {
                candidate = controller
            } else if let controller = current.presentingViewController {
                candidate = controller
            } else if let controller = current.parent {
                candidate = controller
            }
            if let candidate = candidate {
                current = candidate
            }
            return candidate
        }
    }

    func isContainedInPopover() -> Bool {
        var hierarchy = ControllerHierarchyIterator(controller: self)

        return hierarchy.any {
            if let arrowDirection = $0.popoverPresentationController?.arrowDirection,
                arrowDirection != .unknown {
                return true
            } else {
                return false
            }
        }
    }
}

final class SearchResultsViewController: UIViewController {

    lazy var searchResultsView: SearchResultsView = {
        let view = SearchResultsView()
        view.parentViewController = self

        return view
    }()

    private lazy var searchDirectory: SearchDirectory! = {
        guard let session = ZMUserSession.shared() else {
            return nil
        }

        return SearchDirectory(userSession: session)
    }()

    let userSelection: UserSelection

    let sectionController: SectionCollectionViewController = SectionCollectionViewController()
    let contactsSection: ContactsSectionController = ContactsSectionController()
    let teamMemberAndContactsSection: ContactsSectionController = ContactsSectionController()
    let directorySection = DirectorySectionController()
    let conversationsSection: GroupConversationsSectionController = GroupConversationsSectionController()
    let federationSection = FederationSectionController()

    lazy var topPeopleSection: TopPeopleSectionController = {
        return TopPeopleSectionController(topConversationsDirectory: ZMUserSession.shared()?.topConversationsDirectory)
    }()

    let servicesSection: SearchServicesSectionController
    let inviteTeamMemberSection: InviteTeamMemberSection
    let createGroupSection = CreateGroupSection()

    var pendingSearchTask: SearchTask?
    var isAddingParticipants: Bool
    let isFederationEnabled: Bool
    var searchGroup: SearchGroup = .people {
        didSet {
            updateVisibleSections()
        }
    }

    var filterConversation: ZMConversation?
    let shouldIncludeGuests: Bool

    weak var delegate: SearchResultsViewControllerDelegate?

    var mode: SearchResultsViewControllerMode = .search {
        didSet {
            updateVisibleSections()
        }
    }

    deinit {
        searchDirectory?.tearDown()
    }

    init(userSelection: UserSelection,
         isAddingParticipants: Bool = false,
         shouldIncludeGuests: Bool,
         isFederationEnabled: Bool) {
        self.userSelection = userSelection
        self.isAddingParticipants = isAddingParticipants
        self.mode = .list
        self.shouldIncludeGuests = shouldIncludeGuests
        self.isFederationEnabled = isFederationEnabled

        let team = ZMUser.selfUser().team
        let teamName = team?.name

        contactsSection.selection = userSelection
        contactsSection.title = "peoplepicker.header.contacts_personal".localized
        contactsSection.allowsSelection = isAddingParticipants
        teamMemberAndContactsSection.allowsSelection = isAddingParticipants
        teamMemberAndContactsSection.selection = userSelection
        teamMemberAndContactsSection.title = "peoplepicker.header.contacts".localized
        servicesSection = SearchServicesSectionController(canSelfUserManageTeam: ZMUser.selfUser().canManageTeam)
        conversationsSection.title = team != nil ? "peoplepicker.header.team_conversations".localized(args: teamName ?? "") : "peoplepicker.header.conversations".localized
        inviteTeamMemberSection = InviteTeamMemberSection(team: team)

        super.init(nibName: nil, bundle: nil)

        contactsSection.delegate = self
        teamMemberAndContactsSection.delegate = self
        directorySection.delegate = self
        topPeopleSection.delegate = self
        conversationsSection.delegate = self
        servicesSection.delegate = self
        createGroupSection.delegate = self
        inviteTeamMemberSection.delegate = self
        federationSection.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = searchResultsView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sectionController.collectionView?.reloadData()
        sectionController.collectionView?.collectionViewLayout.invalidateLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sectionController.collectionView = searchResultsView.collectionView

        updateVisibleSections()

        searchResultsView.emptyResultContainer.isHidden = !isResultEmpty
    }

    @objc
    func cancelPreviousSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
    }

    private func performSearch(query: String, options: SearchOptions) {

        pendingSearchTask?.cancel()
        searchResultsView.emptyResultContainer.isHidden = true

        var options = options
        options.updateForSelfUserTeamRole(selfUser: ZMUser.selfUser())

        let request = SearchRequest(query: query.trim(), searchOptions: options, team: ZMUser.selfUser().team)
        if let task = searchDirectory?.perform(request) {
            task.onResult({ [weak self] in self?.handleSearchResult(result: $0, isCompleted: $1)})
            task.start()

            pendingSearchTask = task
        }
    }

    func searchForUsers(withQuery query: String) {
        var options: SearchOptions = [.conversations,
                                      .contacts,
                                      .teamMembers,
                                      .directory]

        if isFederationEnabled {
            options.formUnion(.federated)
        }

        self.performSearch(query: query, options: options)
    }

    func searchForLocalUsers(withQuery query: String) {
        self.performSearch(query: query, options: [.contacts, .teamMembers])
    }

    func searchForServices(withQuery query: String) {
        self.performSearch(query: query, options: [.services])
    }

    func searchContactList() {
        searchForLocalUsers(withQuery: "")
    }

    var isResultEmpty: Bool = true {
        didSet {
            searchResultsView.emptyResultContainer.isHidden = !isResultEmpty
        }
    }

    func handleSearchResult(result: SearchResult, isCompleted: Bool) {
        self.updateSections(withSearchResult: result)

        if isCompleted {
            isResultEmpty = sectionController.visibleSections.isEmpty
        }
    }

    func updateVisibleSections() {
        var sections: [CollectionViewSectionController]
        let team = ZMUser.selfUser().team

        switch(self.searchGroup, isAddingParticipants) {
        case (.services, _):
            sections = [servicesSection]
        case (.people, true):
            switch (mode, team != nil) {
            case (.search, false):
                sections = [contactsSection]
            case (.search, true):
                sections = [teamMemberAndContactsSection]
            case (.selection, false):
                sections = [contactsSection]
            case (.selection, true):
                sections = [teamMemberAndContactsSection]
            case (.list, false):
                sections = [contactsSection]
            case (.list, true):
                sections = [teamMemberAndContactsSection]
            }
        case (.people, false):
            switch (mode, team != nil) {
            case (.search, false):
                sections = [contactsSection, conversationsSection, directorySection, federationSection]
            case (.search, true):
                sections = [teamMemberAndContactsSection, conversationsSection, directorySection, federationSection]
            case (.selection, false):
                sections = [contactsSection]
            case (.selection, true):
                sections = [teamMemberAndContactsSection]
            case (.list, false):
                sections = [createGroupSection, topPeopleSection, contactsSection]
            case (.list, true):
                sections = [createGroupSection, inviteTeamMemberSection, teamMemberAndContactsSection]
            }
        }

        sectionController.sections = sections
    }

    func updateSections(withSearchResult searchResult: SearchResult) {

        var contacts = searchResult.contacts
        var teamContacts = searchResult.teamMembers

        if let filteredParticpants = filterConversation?.localParticipants {
            contacts = contacts.filter({
                guard let user = $0.user else {
                    return true
                }
                return !filteredParticpants.contains(user)
            })
            teamContacts = teamContacts.filter({
                guard let user = $0.user else {
                    return true
                }
                return !filteredParticpants.contains(user)
            })
        }

        contactsSection.contacts = contacts

        // Access mode is not set, or the guests are allowed.
        if shouldIncludeGuests {
            teamMemberAndContactsSection.contacts = Set(teamContacts + contacts).sorted {
                let name0 = $0.name ?? ""
                let name1 = $1.name ?? ""

                return name0.compare(name1) == .orderedAscending
            }
        } else {
            teamMemberAndContactsSection.contacts = teamContacts
        }

        directorySection.suggestions = searchResult.directory
        conversationsSection.groupConversations = searchResult.conversations
        servicesSection.services = searchResult.services
        federationSection.result = searchResult.federation

        sectionController.collectionView?.reloadData()
    }

    func sectionFor(controller: CollectionViewSectionController) -> SearchResultsViewControllerSection {
        if controller === topPeopleSection {
            return .topPeople
        } else if controller === contactsSection {
            return .contacts
        } else if controller === teamMemberAndContactsSection {
            return .teamMembers
        } else if  controller === conversationsSection {
            return .conversations
        } else if controller === directorySection {
            return .directory
        } else if controller === servicesSection {
            return .services
        } else if controller === federationSection {
            return .federation
        } else {
            return .unknown
        }
    }

}

extension SearchResultsViewController: SearchSectionControllerDelegate {

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, didSelectUser user: UserType, at indexPath: IndexPath) {
        if let user = user as? ZMUser {
            delegate?.searchResultsViewController(self, didTapOnUser: user, indexPath: indexPath, section: sectionFor(controller: searchSectionController))
        } else if let service = user as? ServiceUser, service.isServiceUser {
            delegate?.searchResultsViewController(self, didTapOnSeviceUser: service)
        } else if let searchUser = user as? ZMSearchUser {
            delegate?.searchResultsViewController(self, didTapOnUser: searchUser, indexPath: indexPath, section: sectionFor(controller: searchSectionController))
        }
    }

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, didSelectConversation conversation: ZMConversation, at indexPath: IndexPath) {
        delegate?.searchResultsViewController(self, didTapOnConversation: conversation)
    }

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, didSelectRow row: CreateGroupSection.Row, at indexPath: IndexPath) {
        switch row {
        case .createGroup:
            delegate?.searchResultsViewController(self, wantsToPerformAction: .createGroup)
        case .createGuestRoom:
            delegate?.searchResultsViewController(self, wantsToPerformAction: .createGuestRoom)
        }

    }

    func searchSectionController(_ searchSectionController: CollectionViewSectionController, wantsToDisplayError error: LocalizedError) {
        presentLocalizedErrorAlert(error)
    }

}

extension SearchResultsViewController: InviteTeamMemberSectionDelegate {
    func inviteSectionDidRequestTeamManagement() {
        URL.manageTeam(source: .onboarding).openInApp(above: self)
    }
}

extension SearchResultsViewController: SearchServicesSectionDelegate {
    func addServicesSectionDidRequestOpenServicesAdmin() {
        URL.manageTeam(source: .settings).openInApp(above: self)
    }
}
