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


import UIKit
import Cartography
// TODO: SMB: remove fake teams
class MockTeam: TeamType {
    public var conversations: Set<ZMConversation> = Set()
    public var name: String? = ""
    public var teamPictureAssetKey: String? = .none
    public var isActive: Bool = true
    public var remoteIdentifier: UUID? = .none
}


func createTeams(createFamily: Bool = false) -> [TeamType] {
    let workspaceName = "W"
    
    var teams: [TeamType] = []
    
    let workTeam: TeamType = {
        let workTeam = MockTeam()
        workTeam.name = workspaceName
        workTeam.isActive = false
        return workTeam
    }()
    
    teams.append(workTeam)
    
    if createFamily {
        let familyTeam: TeamType = {
            let familyTeam = MockTeam()
            familyTeam.name = "Family"
            familyTeam.isActive = true
            return familyTeam
        }()
        
        teams.append(familyTeam)
    }
    
    return teams
}

extension ConversationListViewController {
    
    public func createTopBar() {
        let profileButton = IconButton()
        
        profileButton.setIcon(.selfProfile, with: .tiny, for: UIControlState())
        profileButton.addTarget(self, action: #selector(presentSettings), for: .touchUpInside)
        profileButton.accessibilityIdentifier = "bottomBarSettingsButton"
        profileButton.setIconColor(.white, for: .normal)
        
        if let imageView = profileButton.imageView, let user = ZMUser.selfUser() {
            let newDevicesDot = NewDevicesDot(user: user)
            profileButton.addSubview(newDevicesDot)
            
            constrain(newDevicesDot, imageView) { newDevicesDot, imageView in
                newDevicesDot.top == imageView.top - 3
                newDevicesDot.trailing == imageView.trailing + 3
                newDevicesDot.width == 8
                newDevicesDot.height == 8
            }
        }
        
        self.topBar = ConversationListTopBar()
        
        // TODO: SMB: remove fake teams
        
        self.topBar.teams = createTeams()
        
        self.contentContainer.addSubview(self.topBar)
        self.topBar.contentScrollView = self.listContentController.collectionView
        self.topBar.leftView = profileButton
    }
}
