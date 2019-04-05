// 
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

final class ConnectRequestsCell : UICollectionViewCell {
    let itemView = ConversationListItemView()

    private var hasCreatedInitialConstraints = false
    private var currentConnectionRequestsCount: Int = 0
    private var conversationListObserverToken: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConnectRequestsCell()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private
    func setupConnectRequestsCell() {
        clipsToBounds = true
        addSubview(itemView)
        updateAppearance()

        if ZMUserSession.shared != nil {
            conversationListObserverToken = ConversationListChangeInfo.addObserver(self, forList: ZMConversationList.pendingConnectionConversations(inUserSession: ZMUserSession.shared), userSession: ZMUserSession.shared)
        }

        setNeedsUpdateConstraints()
    }

    private
    func updateConstraints() {
        if !hasCreatedInitialConstraints {
            hasCreatedInitialConstraints = true
            itemView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        }
        super.updateConstraints()
    }

    ///TODO: override
    func setSelected(_ selected: Bool) {
        super.setSelected(selected)
        if IS_IPAD_FULLSCREEN {
            itemView.selected = self.selected || highlighted
        }
    }

    ///TODO: override
    func setHighlighted(_ highlighted: Bool) {
        super.setHighlighted(highlighted)
        if IS_IPAD_FULLSCREEN {
            itemView.selected = selected || self.highlighted
        } else {
            itemView.selected = self.highlighted
        }
    }

    private
    func updateAppearance() {
        let connectionRequests = ZMConversationList.pendingConnectionConversations(inUserSession: ZMUserSession.shared)

        let newCount: Int = connectionRequests.count

        if newCount != currentConnectionRequestsCount {
            let connectionUsers = connectionRequests.map(withBlock: { conversation in
                ///TODO: inject a conversation
                return (conversation?.connection.to)!
            })

            currentConnectionRequestsCount = newCount
            let title = String(format: NSLocalizedString("list.connect_request.people_waiting", comment: ""), newCount)
            itemView.configure(with: NSAttributedString(string: title), subtitle: NSAttributedString(), users: connectionUsers)
        }
    }

}

extension ConnectRequestsCell: ZMConversationListObserver {
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        updateAppearance()
    }
}

