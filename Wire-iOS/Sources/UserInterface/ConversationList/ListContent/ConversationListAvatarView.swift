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

/// Source of random values.
public protocol RandomGenerator {
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
        let result = source.withUnsafeBytes { (pointer: UnsafePointer<ContentType>) -> ContentType in
            return pointer.advanced(by: currentStep % source.count).pointee
        }
        step = step + 1

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
    /// Stable random list of the participants in the conversation. The list would be consistent between platforms
    /// because the conversation UUID is used as the random indexes source.
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
    /// 1-2 participants in conversation:
    /// / AA \
    /// \ AA /
    case one
    /// 3-4 participants in conversation:
    /// / AB \
    /// \ AB /
    case two
    /// 5+ participants in conversation:
    /// / AB \
    /// \ CD /
    case four
}

extension Mode {
    fileprivate init(conversation: ZMConversation) {
        switch (conversation.activeParticipants.count, conversation.conversationType) {
        case (0...2, _), (_, .oneOnOne):
            self = .one
        case (3...5, _):
            self = .two
        default:
            self = .four
        }
    }
}

final public class ConversationListAvatarView: UIView {

    public var conversation: ZMConversation? = .none {
        didSet {
            guard let conversation = self.conversation else {
                self.clippingView.subviews.forEach { $0.removeFromSuperview() }
                return
            }

            let stableRandomParticipants = conversation.stableRandomParticipants.filter { !$0.isSelfUser }
            guard stableRandomParticipants.count > 0 else {
                self.clippingView.subviews.forEach { $0.removeFromSuperview() }
                return
            }

            self.accessibilityLabel = "Avatar for \(self.conversation?.displayName)"
            self.mode = Mode(conversation: conversation)

            var index: Int = 0
            self.userImages().forEach {
                $0.userSession = ZMUserSession.shared()
                $0.size = .tiny
                $0.showInitials = (self.mode == .one)
                $0.isCircular = false
                $0.user = stableRandomParticipants[index]
                index = index + 1
            }
            self.setNeedsLayout()
        }
    }

    private var mode: Mode = .two {
        didSet {
            self.clippingView.subviews.forEach { $0.removeFromSuperview() }
            self.userImages().forEach(self.clippingView.addSubview)

            if mode == .one {
                layer.borderWidth = 0
            }
            else {
                layer.borderWidth = .hairline
                layer.borderColor = UIColor(white: 1, alpha: 0.24).cgColor
            }
        }
    }

    func userImages() -> [UserImageView] {
        switch mode {
        case .one:
            return [imageViewLeftTop]

        case .two:
            return [imageViewLeftTop, imageViewRightTop]

        case .four:
            return [imageViewLeftTop, imageViewRightTop, imageViewLeftBottom, imageViewRightBottom]
        }
    }

    let clippingView = UIView()
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
        backgroundColor = UIColor(white: 0, alpha: 0.16)
        layer.masksToBounds = true
        clippingView.clipsToBounds = true
        self.addSubview(clippingView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard self.bounds != .zero else {
            return
        }

        clippingView.frame = self.mode == .one ? self.bounds : self.bounds.insetBy(dx: 2, dy: 2)

        let size: CGSize
        let inset: CGFloat = 2
        let containerSize = self.clippingView.bounds.size

        switch mode {
        case .one:
            size = CGSize(width: containerSize.width, height: containerSize.height)

        case .two:
            size = CGSize(width: (containerSize.width  - inset) / 2.0, height: containerSize.height)

        case .four:
            size = CGSize(width: (containerSize.width - inset) / 2.0, height: (containerSize.height - inset) / 2.0)
        }

        var xPosition: CGFloat = 0
        var yPosition: CGFloat = 0

        self.userImages().forEach {
            $0.frame = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
            if xPosition + size.width >= containerSize.width {
                xPosition = 0
                yPosition = yPosition + size.height + inset
            }
            else {
                xPosition = xPosition + size.width + inset
            }
        }

        updateCornerRadius()
    }

    private func updateCornerRadius() {
        layer.cornerRadius = self.conversation?.conversationType == .group ? 6 : layer.bounds.width / 2.0
        clippingView.layer.cornerRadius = self.conversation?.conversationType == .group ? 4 : clippingView.layer.bounds.width / 2.0
    }
}
