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

import WireSyncEngine

/// Source of random values.
protocol RandomGenerator {
    func rand<ContentType>() -> ContentType
}

/// Generates the pseudorandom values from the data given.
/// @param data the source of random values.
final class RandomGeneratorFromData: RandomGenerator {
    public let source: Data
    private var step: Int = 0

    init(data: Data) {
        source = data
    }

    public func rand<ContentType>() -> ContentType {
        let currentStep = self.step
        let result = source.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> ContentType in
            return pointer.baseAddress!.assumingMemoryBound(to: ContentType.self).advanced(by: currentStep % (source.count - MemoryLayout<ContentType>.size)).pointee
        }
        step += MemoryLayout<ContentType>.size

        return result
    }

}

extension RandomGeneratorFromData {
    /// Use UUID as plain data to generate random value.
    convenience init(uuid: UUID) {
        self.init(data: (uuid as NSUUID).data()!)
    }
}

extension Array {
    func shuffled(with generator: RandomGenerator) -> Array {

        var workingCopyIndices = [Int](indices)
        var resultIndices = [Int]()
        forEach { _ in
            let rand: UInt = generator.rand() % (UInt)(workingCopyIndices.count)

            resultIndices.append(workingCopyIndices[Int(rand)])
            workingCopyIndices.remove(at: Int(rand))
        }

        return resultIndices.map { self[$0] }
    }
}

extension ZMConversation: StableRandomParticipantsProvider {
    /// Stable random list of the participants in the conversation. The list would be consistent between platforms
    /// because the conversation UUID is used as the random indexes source.
    var stableRandomParticipants: [UserType] {
        let allUsers = sortedActiveParticipants
        guard let remoteIdentifier = self.remoteIdentifier else {
            return allUsers
        }

        let rand = RandomGeneratorFromData(uuid: remoteIdentifier)

        return allUsers.shuffled(with: rand)
    }
}

enum Mode: Equatable {
    /// 0 participants in conversation:
    /// /    \
    /// \    /
    case none
    /// 1-2 participants in conversation:
    /// / AA \
    /// \ AA /
    case one(serviceUser: Bool)
    /// 2+ participants in conversation:
    /// / AB \
    /// \ CD /
    case four
}

extension Mode {

    /// create a Mode for different cases
    ///
    /// - Parameters:
    ///   - conversationType: when conversationType is nil, it is a incoming connection request
    ///   - users: number of users involved in the conversation
    fileprivate init(conversationType: ZMConversationType? = nil, users: [UserType]) {
        switch (users.count, conversationType) {
        case (0, _):
            self = .none
        case (1, .group?):
            let isServiceUser = users[0].isServiceUser
            self = isServiceUser ? .one(serviceUser: isServiceUser) : .four
        case (1, _):
            self = .one(serviceUser: users[0].isServiceUser)
        default:
            self = .four
        }
    }

    var showInitials: Bool {
        if case .one = self {
            return true
        } else {
            return false
        }
    }

    var shape: AvatarImageView.Shape {
        switch self {
        case .one(serviceUser: true): return .relative
        default: return .rectangle
        }
    }
}

typealias ConversationAvatarViewConversation = ConversationLike & StableRandomParticipantsProvider

final class ConversationAvatarView: UIView {
    enum Context {
        // one or more users requesting connection to self user
        case connect(users: [UserType])
        // an established conversation or self user has a pending request to other users
        case conversation(conversation: ConversationAvatarViewConversation)
    }

    func configure(context: Context) {
        switch context {
        case .connect(let users):
            self.users = users
            mode = Mode(users: users)
        case .conversation(let conversation):
            self.conversation = conversation
            mode = Mode(conversationType: conversation.conversationType, users: users)
        }
    }

    private var users: [UserType] = []

    private var conversation: ConversationAvatarViewConversation? = .none {
        didSet {

            guard let conversation = conversation else {
                self.clippingView.subviews.forEach { $0.isHidden = true }
                return
            }

            accessibilityLabel = "Avatar for \(conversation.displayName)"

            let usersOnAvatar: [UserType]
            let stableRandomParticipants = conversation.stableRandomParticipants.filter { !$0.isSelfUser }

            if stableRandomParticipants.isEmpty,
                let connectedUser = conversation.connectedUserType {
                usersOnAvatar = [connectedUser]
            } else {
                usersOnAvatar = stableRandomParticipants
            }

            users = usersOnAvatar
        }
    }

    private(set) var mode: Mode = .one(serviceUser: false) {
        didSet {
            self.clippingView.subviews.forEach { $0.isHidden = true }
            self.userImages().forEach { $0.isHidden = false }

            if case .one = mode {
                layer.borderWidth = 0
                backgroundColor = .clear
            } else {
                layer.borderWidth = .hairline
                layer.borderColor = UIColor(white: 1, alpha: 0.24).cgColor
                backgroundColor = UIColor(white: 0, alpha: 0.16)
            }

            var index: Int = 0
            self.userImages().forEach {
                $0.userSession = ZMUserSession.shared()
                $0.shouldDesaturate = false
                $0.size = mode == .four ? .tiny : .small
                if index < users.count {
                    $0.user = users[index]
                } else {
                    $0.user = nil
                    $0.container.isOpaque = false
                    $0.container.backgroundColor = UIColor(white: 0, alpha: 0.24)
                    $0.avatar = .none
                }

                $0.allowsInitials = mode.showInitials
                $0.shape = mode.shape
                index += 1
            }

            setNeedsLayout()
        }
    }

    private var userImageViews: [UserImageView] {
        return [imageViewLeftTop, imageViewRightTop, imageViewLeftBottom, imageViewRightBottom]
    }

    func userImages() -> [UserImageView] {
        switch mode {
        case .none:
            return []

        case .one:
            return [imageViewLeftTop]

        case .four:
            return userImageViews
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.ConversationAvatarView.iconSize, height: CGFloat.ConversationAvatarView.iconSize)
    }

    let clippingView = UIView()
    let imageViewLeftTop: UserImageView = {
        let userImageView = BadgeUserImageView()
        userImageView.initialsFont = .mediumSemiboldFont

        return userImageView
    }()
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
        userImageViews.forEach(self.clippingView.addSubview)
        updateCornerRadius()
        autoresizesSubviews = false
        layer.masksToBounds = true
        clippingView.clipsToBounds = true
        self.addSubview(clippingView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let interAvatarInset: CGFloat = 2
    var containerSize: CGSize {
        return self.clippingView.bounds.size
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard self.bounds != .zero else {
            return
        }

        clippingView.frame = self.bounds.insetBy(dx: 2, dy: 2)

        switch mode {
        case .none:
            break
        case .one:
            self.userImages().forEach {
                $0.frame = clippingView.bounds
            }
        case .four:
            layoutMultipleAvatars(with: CGSize(width: (containerSize.width - interAvatarInset) / 2.0, height: (containerSize.height - interAvatarInset) / 2.0))
        }

        updateCornerRadius()
    }

    private func layoutMultipleAvatars(with size: CGSize) {
        var xPosition: CGFloat = 0
        var yPosition: CGFloat = 0

        self.userImages().forEach {
            $0.frame = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
            if xPosition + size.width >= containerSize.width {
                xPosition = 0
                yPosition += size.height + interAvatarInset
            } else {
                xPosition += size.width + interAvatarInset
            }
        }
    }

    private func updateCornerRadius() {
        switch mode {
        case .one(serviceUser: let serviceUser):
            layer.cornerRadius = serviceUser ? 0 : layer.bounds.width / 2.0
            clippingView.layer.cornerRadius = serviceUser ? 0 : clippingView.layer.bounds.width / 2.0
        default:
            layer.cornerRadius = 6
            clippingView.layer.cornerRadius = 4
        }
    }
}
