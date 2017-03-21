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


import Cartography


class TwoUserImageView: UIView {

    private let leftImageView = UserImageView(magicPrefix: "content.author_image")
    private let rightImageView = UserImageView(magicPrefix: "content.author_image")


    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        [leftImageView, rightImageView].forEach(addSubview)
        bringSubview(toFront: rightImageView)
    }

    private func createConstraints() {
        constrain(self, leftImageView, rightImageView) { view, leftImageView, rightImageView in
            leftImageView.leading == view.leading
            leftImageView.top == view.top
            rightImageView.trailing == view.trailing
            rightImageView.bottom == view.bottom

            leftImageView.height == 16
            leftImageView.width == leftImageView.height
            rightImageView.height == leftImageView.height
            rightImageView.width == leftImageView.height
        }
     }

    func setUsers(left: ZMUser?, right: ZMUser?) {
        leftImageView.user = left
        rightImageView.user = right
    }
}


@objc public final class ConversationListAvatarView: UIView {

    fileprivate enum AvatarMode {
        case single(ZMUser?), double(ZMUser?, ZMUser?)
    }

    public var conversation: ZMConversation? {
        didSet {
            updateViewVisibility()
            updateAlpha()
        }
    }

    private let userImageView = UserImageView(magicPrefix: "content.author_image")
    private let twoUserImageView = TwoUserImageView()

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
        updateViewVisibility()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 24, height: 24)
    }

    private func setupViews() {
        [userImageView, twoUserImageView].forEach(addSubview)
        twoUserImageView.isHidden = true
    }

    private func createConstraints() {
        constrain(self, userImageView, twoUserImageView) { view, userImageView, twoUserImageView in
            userImageView.edges == view.edges
            userImageView.size == view.size
            twoUserImageView.edges == view.edges
        }
    }

    private func updateViewVisibility() {
        guard let mode = conversation?.avatarMode else { return }
        switch mode {
        case .single(let user):
            userImageView.isHidden = false
            twoUserImageView.isHidden = true
            userImageView.user = user
        case .double(let left, let right):
            twoUserImageView.isHidden = false
            userImageView.isHidden = true
            twoUserImageView.setUsers(left: left, right: right)
        }
    }

    private func updateAlpha() {
        guard let type = conversation?.conversationType else { return }
        switch type {
        case .oneOnOne, .group: alpha = 1
        case .connection: alpha = 0.5
        default: return
        }
    }

}


fileprivate extension ZMConversation {

    var avatarMode: ConversationListAvatarView.AvatarMode {
        switch conversationType {
        case .group:
            let descriptor = NSSortDescriptor(key: "displayName", ascending: false)
            let sorted = otherActiveParticipants.sortedArray(using: [descriptor]).flatMap { $0 as? ZMUser }
            if sorted.count >= 2 {
                return .double(sorted[0], sorted[1])
            } else {
                return .single(sorted.first)
            }
        default:
            return .single(connection?.to)
        }
    }

}
