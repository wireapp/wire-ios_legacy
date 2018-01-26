//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension StartUIViewController: SearchResultsViewControllerDelegate {
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnUser user: ZMSearchableUser, indexPath: IndexPath, section: SearchResultsViewControllerSection) {
        
        if let user = user as? AnalyticsConnectionStateProvider {
            Analytics.shared().tagSelectedUnconnectedUser(with: user, context: .startUI)
        }
        
        switch section {
        case .topPeople: Analytics.shared().tagSelectedTopContact()
        case .contacts: Analytics.shared().tagSelectedSearchResultUser(with: UInt(indexPath.row))
        case .directory: Analytics.shared().tagSelectedSuggestedUser(with: UInt(indexPath.row))
        default: break
        }
        
        if !user.isConnected && !user.isTeamMember {
            self.presentProfileViewController(for: user, at: indexPath)
        }
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didDoubleTapOnUser user: ZMSearchableUser, indexPath: IndexPath) {
    
        if let unboxedUser = BareUserToUser(user), unboxedUser.isConnected, !unboxedUser.isBlocked {
            
            if self.userSelection.users.count == 1 && !self.userSelection.users.contains(unboxedUser) {
                return
            }
            
            self.delegate.startUI(self, didSelectUsers: NSSet(object: user) as! Set<AnyHashable>, for: .createOrOpenConversation)
        }
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnConversation conversation: ZMConversation) {
        if conversation.conversationType == .group {
            self.delegate.startUI!(self, didSelect: conversation)
        }
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnSeviceUser user: ServiceUser) {
        
        let detail = ServiceDetailViewController(serviceUser: user)
        
        detail.completion = { result in
            switch result {
                
            case .success(let conversation):
                self.delegate.startUI!(self, didSelect: conversation)
            case .failure(let error):
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, cancelButtonTitle: "Ok")
                self.present(alert, animated: true, completion: nil)
                self.delegate.startUIDidCancel(self)
            }
        }
        
        self.navigationController?.pushViewController(detail, animated: true)
    }
}
