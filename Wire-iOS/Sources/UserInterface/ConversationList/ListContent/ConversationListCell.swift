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
import WireSyncEngine
import avs

typealias MatcherConversation = Conversation & ConversationStatusProvider & TypingStatusProvider & VoiceChannelProvider

typealias ConversationListCellConversation = MatcherConversation & StableRandomParticipantsProvider

final class ConversationListCell: SwipeMenuCollectionCell,
                                  SectionListCellType {
    static let IgnoreOverscrollTimeInterval: TimeInterval = 0.005
    static let OverscrollRatio: CGFloat = 2.5

    static var cachedSize: CGSize = .zero

    var conversation: ConversationListCellConversation? {
        didSet {
            guard !(conversation === oldValue) else { return }

            typingObserverToken = nil
            if let conversation = conversation as? ZMConversation {
                typingObserverToken = conversation.addTypingObserver(self)
                setupConversationObserver(conversation: conversation)
            }

            updateAppearance()
        }
    }

    let itemView: ConversationListItemView = ConversationListItemView()

    weak var delegate: ConversationListCellDelegate?

    private var titleBottomMarginConstraint: NSLayoutConstraint?
    private var typingObserverToken: Any?

    // MARK: - SectionListCellType
    var sectionName: String?
    var cellIdentifier: String?

    private var hasCreatedInitialConstraints = false
    let menuDotsView: AnimatedListMenuView = AnimatedListMenuView()
    private var overscrollStartDate: Date?
    private var conversationObserverToken: Any?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConversationListCell()
    }

    deinit {
        AVSMediaManagerClientChangeNotification.remove(self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConversationListCell() {
        separatorLineViewDisabled = true
        maxVisualDrawerOffset = SwipeMenuCollectionCell.MaxVisualDrawerOffsetRevealDistance
        overscrollFraction = CGFloat.greatestFiniteMagnitude // Never overscroll
        clipsToBounds = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onRightAccessorySelected(_:)))
        itemView.rightAccessory.addGestureRecognizer(tapGestureRecognizer)
        swipeView.addSubview(itemView)

        menuView.addSubview(menuDotsView)

        setNeedsUpdateConstraints()

        AVSMediaManagerClientChangeNotification.add(self)
        backgroundColor = SemanticColors.View.backgroundConversationListTableViewCell
        addBorder(for: .bottom)
    }

    override func drawerScrollingEnded(withOffset offset: CGFloat) {
        if menuDotsView.progress >= 1 {
            var overscrolled = false
            if offset > frame.width / ConversationListCell.OverscrollRatio {
                overscrolled = true
            } else if let overscrollStartDate = overscrollStartDate {
                let diff = Date().timeIntervalSince(overscrollStartDate)
                overscrolled = diff > ConversationListCell.IgnoreOverscrollTimeInterval
            }

            if overscrolled {
                delegate?.conversationListCellOverscrolled(self)
            }
        }
        overscrollStartDate = nil
    }

    override var accessibilityValue: String? {
        get {
            return delegate?.indexPath(for: self)?.description
        }

        set {
            // no op
        }
    }

    override var accessibilityIdentifier: String? {
        get {
            return identifier
        }

        set {
            // no op
        }
    }

    override var isSelected: Bool {
        didSet {
            if isIPadRegular() {
                itemView.selected  = isSelected || isHighlighted
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if isIPadRegular() {
                itemView.selected  = isSelected || isHighlighted
            } else {
                itemView.selected  =  isHighlighted
            }
        }
    }

    override func updateConstraints() {
        super.updateConstraints()

        if hasCreatedInitialConstraints {
            return
        }
        hasCreatedInitialConstraints = true

        [itemView, menuDotsView, menuView].prepareForLayout()

        itemView.fitIn(view: swipeView)

        if let superview = menuDotsView.superview {
            let menuDotsViewEdges = [

                superview.leadingAnchor.constraint(equalTo: menuDotsView.leadingAnchor),
                superview.topAnchor.constraint(equalTo: menuDotsView.topAnchor),
                superview.trailingAnchor.constraint(equalTo: menuDotsView.trailingAnchor),
                superview.bottomAnchor.constraint(equalTo: menuDotsView.bottomAnchor)
            ]

            NSLayoutConstraint.activate(menuDotsViewEdges)
        }
    }

    // MARK: - DrawerOverrides
    override func drawerScrollingStarts() {
        overscrollStartDate = nil
    }

    override func setVisualDrawerOffset(_ visualDrawerOffset: CGFloat, updateUI doUpdate: Bool) {
        super.setVisualDrawerOffset(visualDrawerOffset, updateUI: doUpdate)

        // After X % of reveal we consider animation should be finished
        let progress = visualDrawerOffset / SwipeMenuCollectionCell.MaxVisualDrawerOffsetRevealDistance
        menuDotsView.setProgress(progress, animated: true)
        if progress >= 1 && overscrollStartDate == nil {
            overscrollStartDate = Date()
        }

        itemView.visualDrawerOffset = visualDrawerOffset
    }

    func updateAppearance() {
        itemView.update(for: conversation)
    }

    func size(inCollectionViewSize collectionViewSize: CGSize) -> CGSize {
        if !ConversationListCell.cachedSize.equalTo(CGSize.zero) && ConversationListCell.cachedSize.width == collectionViewSize.width {
            return ConversationListCell.cachedSize
        }

        let fullHeightString = "Ü"
        itemView.configure(with: NSAttributedString(string: fullHeightString), subtitle: NSAttributedString(string: fullHeightString, attributes: ZMConversation.statusRegularStyle()))

        let fittingSize = CGSize(width: collectionViewSize.width, height: 0)

        itemView.frame = CGRect(x: 0, y: 0, width: fittingSize.width, height: 0)

        var cellSize = itemView.systemLayoutSizeFitting(fittingSize)
        cellSize.width = collectionViewSize.width
        ConversationListCell.cachedSize = cellSize
        return cellSize
    }

    class func invalidateCachedCellSize() {
        cachedSize = CGSize.zero
    }

    @objc
    private func onRightAccessorySelected(_ sender: UIButton?) {
        guard let conversation = conversation as? ZMConversation else { return }

        let activeMediaPlayer = AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer

        if activeMediaPlayer != nil &&
            activeMediaPlayer?.sourceMessage?.conversationLike === conversation {
            toggleMediaPlayer()
        } else if conversation.canJoinCall {
            delegate?.conversationListCellJoinCallButtonTapped(self)
        }
    }

    func toggleMediaPlayer() {
        let mediaPlaybackManager = AppDelegate.shared.mediaPlaybackManager

        if mediaPlaybackManager?.activeMediaPlayer?.state == .playing {
            mediaPlaybackManager?.pause()
        } else {
            mediaPlaybackManager?.play()
        }

        updateAppearance()
    }

    // MARK: - ConversationChangeInfo
    func setupConversationObserver(conversation: ZMConversation) {
        conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
    }
}

// MARK: - Typing

extension ConversationListCell: ZMTypingChangeObserver {
    func typingDidChange(conversation: ZMConversation, typingUsers: [UserType]) {
        updateAppearance()
    }
}

// MARK: - AVSMediaManagerClientChangeNotification

extension ConversationListCell: AVSMediaManagerClientObserver {
    func mediaManagerDidChange(_ notification: AVSMediaManagerClientChangeNotification?) {
        guard !ProcessInfo.processInfo.isRunningTests else { return }

        // AUDIO-548 AVMediaManager notifications arrive on a background thread.
        DispatchQueue.main.async(execute: {
            if notification?.microphoneMuteChanged != nil {
                self.updateAppearance()
            }
        })
    }
}
