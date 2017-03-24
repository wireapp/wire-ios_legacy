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

public protocol RandomGenerator {
    func rand<ContentType>() -> ContentType
}

final class RandomGeneratorFromData: RandomGenerator {
    public let source: Data
    private var step: Int = 0
    
    init(data: Data) {
        source = data
    }
    
    public func rand<ContentType>() -> ContentType {
        let currentStep = self.step
        let result = source.withUnsafeBytes { (pointer: UnsafePointer<ContentType>) -> ContentType in
            return pointer.advanced(by: currentStep % source.count).pointee
        }
        step = step + 1
        
        return result// ^ ContentType(Int(step / source.count))
    }

}

extension RandomGeneratorFromData {
    convenience init(uuid: UUID) {
        self.init(data: (uuid as NSUUID).data()!)
    }
}

extension Array {
    public func shuffled(with generator: RandomGenerator) -> Array {
        
        var workingCopy = Array(self)
        var result = Array()

        self.forEach { _ in
            let rand: UInt = generator.rand() % UInt(workingCopy.count)
        
            result.append(workingCopy[Int(rand)])
            workingCopy.remove(at: Int(rand))
        }

        return result
    }
}

extension ZMConversation {
    var stableRandomParticipants: [ZMUser] {
        let allUsers = self.activeParticipants.array as! [ZMUser]
        guard let remoteIdentifier = self.remoteIdentifier else {
            return allUsers
        }
        
        let rand = RandomGeneratorFromData(uuid: remoteIdentifier)
        
        return allUsers.shuffled(with: rand)
    }
}


fileprivate enum Mode {
    case one
    case two
    case four
}

extension Mode {
    fileprivate init(conversation: ZMConversation) {
        if conversation.activeParticipants.count < 2 {
            self = .one
        }
        else if conversation.activeParticipants.count <= 5 {
            self = .two
        }
        else {
            self = .four
        }
    }
}

final public class GroupConversationAvatarView: UIView {

    public var conversation: ZMConversation? = .none {
        didSet {
            guard let conversation = self.conversation, conversation.activeParticipants.count > 0 else {
                return
            }
            self.mode = Mode(conversation: conversation)
            
            let stableRandomParticipants = conversation.stableRandomParticipants
            var index: Int = 0
            self.userImages().forEach {
                $0.size = .tiny
                $0.initials.removeFromSuperview()
                $0.isCircular = false
                $0.user = stableRandomParticipants[index]
                index = index + 1
            }
            self.setNeedsLayout()
        }
    }
    
    private var mode: Mode = .two {
        didSet {
            self.subviews.forEach { $0.removeFromSuperview() }
            self.userImages().forEach(self.addSubview)
        }
    }
    
    func userImages() -> [UserImageView] {
        switch mode {
        case .one:
            return [imageViewLeftTop]
            
        case .two:
            return [imageViewLeftTop, imageViewRightTop]
            
        case .four:
            return [imageViewLeftTop, imageViewRightTop, imageViewLeftBottom, imageViewRightTop]
        }
    }
    
    let imageViewLeftTop = UserImageView()
    lazy var imageViewRightTop: UserImageView = {
        return UserImageView()
    }()
    
    lazy var imageViewLeftBottom: UserImageView = {
        return UserImageView()
    }()
    
    lazy var imageViewRightBottom: UserImageView = {
        return UserImageView()
    }()
    
    init() {
        super.init(frame: .zero)
        updateCornerRadius()
        self.layer.masksToBounds = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let size: CGSize
        
        switch mode {
        case .one:
            size = CGSize(width: self.bounds.width, height: self.bounds.height)
            
        case .two:
            size = CGSize(width: self.bounds.width / 2.0, height: self.bounds.height)
            
        case .four:
            size = CGSize(width: self.bounds.width / 2.0, height: self.bounds.height / 2.0)
        }
        
        var xPosition: CGFloat = 0
        var yPosition: CGFloat = 0
        
        self.userImages().forEach {
            $0.frame = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
            if xPosition + size.width >= self.bounds.width {
                xPosition = 0
                yPosition = yPosition + size.height
            }
            else {
                xPosition = xPosition + size.width
            }
        }
        
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        layer.cornerRadius = 8
    }
}


@objc public final class ConversationListAvatarView: UIView {

    fileprivate enum AvatarMode {
        case oneOnOne(ZMUser?), group
    }

    public var conversation: ZMConversation? {
        didSet {
            updateViewVisibility()
            updateAlpha()
        }
    }

    public lazy var userImageView: UserImageView = {
        return UserImageView()
    }()
    public let groupImageView = GroupConversationAvatarView()

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
        [userImageView, groupImageView].forEach(addSubview)
        groupImageView.isHidden = true
    }

    private func createConstraints() {
        constrain(self, userImageView, groupImageView) { view, userImageView, groupImageView in
            userImageView.edges == view.edges
            userImageView.size == view.size
            groupImageView.edges == view.edges
        }
    }

    private func updateViewVisibility() {
        guard let conversation = conversation else { return }
        let mode = conversation.avatarMode
        
        switch mode {
        case .oneOnOne(let user):
            userImageView.isHidden = false
            groupImageView.isHidden = true
            userImageView.user = user
        case .group:
            groupImageView.isHidden = false
            userImageView.isHidden = true
            groupImageView.conversation = conversation
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
            return .group
        default: return .oneOnOne(connection?.to)
        }
    }
}
