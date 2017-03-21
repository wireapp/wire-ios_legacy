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


public class GroupConversationAvatarView: UIView {

    public let countLabel = UILabel()

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
        updateCornerRadius()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }

    private func setupViews() {
        addSubview(countLabel)
    }

    private func createConstraints() {
        constrain(self, countLabel) { view, countLabel in
            countLabel.centerY == view.centerY
            countLabel.centerX == view.centerX
        }
     }

    private func updateCornerRadius() {
        layer.cornerRadius = 8
    }
}


@objc public final class ConversationListAvatarView: UIView {

    fileprivate enum AvatarMode {
        case oneOnOne(ZMUser?), group(UInt, UIColor?)
    }

    public var conversation: ZMConversation? {
        didSet {
            updateViewVisibility()
            updateAlpha()
        }
    }

    public let userImageView = UserImageView()
    public let participantsCountView = GroupConversationAvatarView()

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
        [userImageView, participantsCountView].forEach(addSubview)
        participantsCountView.isHidden = true
    }

    private func createConstraints() {
        constrain(self, userImageView, participantsCountView) { view, userImageView, participantsCountView in
            userImageView.edges == view.edges
            userImageView.size == view.size
            participantsCountView.edges == view.edges
        }
    }

    private func updateViewVisibility() {
        guard let mode = conversation?.avatarMode else { return }
        switch mode {
        case .oneOnOne(let user):
            userImageView.isHidden = false
            participantsCountView.isHidden = true
            userImageView.user = user
        case .group(let count, let color):
            participantsCountView.isHidden = false
            userImageView.isHidden = true
            participantsCountView.countLabel.text = String(count)
            participantsCountView.backgroundColor = color
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
            let color = sorted.first?.accentColor ?? ZMUser.selfUser().accentColor
            return .group(UInt(otherActiveParticipants.count), color)
        default: return .oneOnOne(connection?.to)
        }
    }

}
