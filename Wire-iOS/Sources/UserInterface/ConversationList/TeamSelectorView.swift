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
import Classy

internal class LineView: UIView {
    public let views: [UIView]
    init(views: [UIView]) {
        self.views = views
        super.init(frame: .zero)
        layoutViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutViews() {
        
        self.views.forEach(self.addSubview)
        
        guard let first = self.views.first else {
            return
        }
        
        let inset: CGFloat = 24
        
        constrain(self, first) { selfView, first in
            first.leading == selfView.leading
            first.top == selfView.top ~ LayoutPriority(750)
            first.bottom == selfView.bottom ~ LayoutPriority(750)
        }
        
        var previous: UIView = first
        
        self.views.dropFirst().forEach {
            constrain(previous, $0, self) { previous, current, selfView in
                current.leading == previous.trailing + inset
                current.top == selfView.top ~ LayoutPriority(750)
                current.bottom == selfView.bottom ~ LayoutPriority(750)
            }
            previous = $0
        }

        guard let last = self.views.last else {
            return
        }
        
        constrain(self, last) { selfView, last in
            last.trailing == selfView.trailing
        }
    }
}

final internal class TeamSelectorView: UIView {
    public var teams: [TeamType]
    public let teamsViews: [BaseTeamView]
    private let lineView: LineView
    private var topOffsetConstraint: NSLayoutConstraint!
    public var imagesCollapsed: Bool = false {
        didSet {
            self.topOffsetConstraint.constant = imagesCollapsed ? -20 : 0
            
            self.teamsViews.forEach { $0.collapsed = imagesCollapsed }
            
            self.layoutIfNeeded()
        }
    }
    
    init() {
        self.teams = Array(ZMUser.selfUser().teams!)
        
        let personalTeamView = PersonalTeamView()
        
        self.teamsViews = [personalTeamView] + self.teams.map { TeamView(team: $0) }
        self.lineView = LineView(views: self.teamsViews)
        super.init(frame: .zero)
        
        self.addSubview(lineView)
        self.clipsToBounds = true

        constrain(self, self.lineView) { selfView, lineView in
            self.topOffsetConstraint = lineView.centerY == selfView.centerY
            lineView.leading == selfView.leading
            lineView.trailing == selfView.trailing
            lineView.height == selfView.height
        }
        
        self.teamsViews.forEach { $0.onTap = { selectedTeam in
                if let selectedTeam = selectedTeam {
                    self.teams.filter { $0.remoteIdentifier != selectedTeam.remoteIdentifier }.forEach { $0.isActive = false }
                }
                else {
                    self.teams.forEach { $0.isActive = false }
                }
            
                selectedTeam?.isActive = true
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
