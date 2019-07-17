
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class TeamAccountView: BaseAccountView {

    public override var collapsed: Bool {
        didSet {
            self.imageView.isHidden = collapsed
        }
    }

    private let imageView: TeamImageView
    private var teamObserver: NSObjectProtocol!
    private var conversationListObserver: NSObjectProtocol!

    override init?(account: Account, user: ZMUser? = nil) {

        if let content = user?.team?.teamImageViewContent ?? account.teamImageViewContent {
            imageView = TeamImageView(content: content)
        } else {
            return nil
        }

        super.init(account: account, user: user)

        isAccessibilityElement = true
        accessibilityTraits = .button
        shouldGroupAccessibilityChildren = true

        imageView.contentMode = .scaleAspectFill

        imageViewContainer.addSubview(imageView)

        selectionView.pathGenerator = { size in
            let radius = 4
            let radii = CGSize(width: radius, height: radius)
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                    byRoundingCorners: UIRectCorner.allCorners,
                                    cornerRadii: radii)

            //            let scale = (size.width - 3) / path.bounds.width
            //            path.apply(CGAffineTransform(scaleX: scale, y: scale))
            return path
        }

        constrain(imageViewContainer, imageView) { imageViewContainer, imageView in
            imageView.edges == inset(imageViewContainer.edges, 2, 2)
        }

        update()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tapGesture)

        if let team = user?.team {
            teamObserver = TeamChangeInfo.add(observer: self, for: team)
            team.requestImage()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func update() {
        super.update()
        accessibilityValue = String(format: "conversation_list.header.self_team.accessibility_value".localized, self.account.teamName ?? "") + " " + accessibilityState
        accessibilityIdentifier = "\(self.account.teamName ?? "") team"
    }

}

extension TeamAccountView: TeamObserver {
    func teamDidChange(_ changeInfo: TeamChangeInfo) {
        guard let content = changeInfo.team.teamImageViewContent else { return }

        imageView.content = content
    }
}
