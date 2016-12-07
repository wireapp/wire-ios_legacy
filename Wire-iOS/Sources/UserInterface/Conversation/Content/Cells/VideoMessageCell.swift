//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography
import CocoaLumberjackSwift
import Classy

extension ZMConversationMessage {
    public func videoCanBeSavedToCameraRoll() -> Bool {
        if let fileMessageData = self.fileMessageData,
            let fileURL = fileMessageData.fileURL,
            UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fileURL.path) && fileMessageData.isVideo() {
            return true
        }
        else {
            return false
        }
    }
}

/// Displays the video message with different states
public final class VideoMessageCell: ConversationCell {
    private let previewImageView = UIImageView()
    private let progressView = CircularProgressView()
    private let playButton = IconButton()
    private let bottomGradientView = GradientView()
    private let timeLabel = UILabel()
    private let loadingView = ThreeDotsLoadingView()
    private var topMargin : NSLayoutConstraint?
    private let obfuscationView = ObfuscationView(icon: .videoMessage)

    private let normalColor = UIColor.black.withAlphaComponent(0.4)
    private let failureColor = UIColor.red.withAlphaComponent(0.24)
    private var allViews : [UIView] = []
    
    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.previewImageView.translatesAutoresizingMaskIntoConstraints = false
        self.previewImageView.contentMode = .scaleAspectFill
        self.previewImageView.clipsToBounds = true
        self.previewImageView.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorPlaceholderBackground)
        
        self.playButton.translatesAutoresizingMaskIntoConstraints = false
        self.playButton.addTarget(self, action: #selector(VideoMessageCell.onActionButtonPressed(_:)), for: .touchUpInside)
        self.playButton.accessibilityLabel = "VideoActionButton"
        self.playButton.layer.masksToBounds = true
        
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.progressView.isUserInteractionEnabled = false
        self.progressView.accessibilityLabel = "VideoProgressView"
        self.progressView.deterministic = true
        
        self.bottomGradientView.translatesAutoresizingMaskIntoConstraints = false
        self.bottomGradientView.gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]
        
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.timeLabel.numberOfLines = 1
        self.timeLabel.accessibilityLabel = "VideoActionTimeLabel"
        
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.loadingView.isHidden = true

        self.allViews = [previewImageView, playButton, bottomGradientView, progressView, timeLabel, loadingView, obfuscationView]
        self.allViews.forEach(messageContentView.addSubview)
        
        CASStyler.default().styleItem(self)
        
        self.createConstraints()
        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [previewImageView, playButton, timeLabel, progressView, likeButton, messageToolboxView])
        self.accessibilityElements = currentElements

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func createConstraints() {
        constrain(self.messageContentView, self.previewImageView, self.progressView, self.playButton, self.bottomGradientView) { messageContentView, previewImageView, progressView, playButton, bottomGradientView in
            messageContentView.width == messageContentView.height * (4.0 / 3.0)
            topMargin = (previewImageView.edges == messageContentView.edges).first
            playButton.center == previewImageView.center
            playButton.width == 56
            playButton.height == playButton.width
            progressView.center == playButton.center
            progressView.width == playButton.width - 2
            progressView.height == playButton.height - 2
            bottomGradientView.left == messageContentView.left
            bottomGradientView.right == messageContentView.right
            bottomGradientView.bottom == messageContentView.bottom
            bottomGradientView.height == 56
        }
        
        constrain(bottomGradientView, timeLabel, previewImageView, loadingView) { bottomGradientView, sizeLabel, previewImageView, loadingView in
            sizeLabel.right == bottomGradientView.right - 16
            sizeLabel.centerY == bottomGradientView.centerY
            loadingView.center == previewImageView.center
        }

        constrain(previewImageView, countdownContainerView, obfuscationView) { previewImageView, countDownContainer, obfuscationView in
            countDownContainer.top == previewImageView.top + 8
            obfuscationView.edges == previewImageView.edges
        }
    }
    
    open override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.update(forMessage: changeInfo)
        
        if let fileMessageData = self.message.fileMessageData {
            self.configureForVideoMessage(fileMessageData, initialConfiguration: false)
        }

        return needsLayout
    }
    
    override open func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        
        if Message.isVideoMessage(message), let fileMessageData = message.fileMessageData {
            self.configureForVideoMessage(fileMessageData, initialConfiguration: true)
        }
        else {
            fatalError("Wrong message type: \(type(of: message)): \(message)")
        }
    }
    
    private func configureForVideoMessage(_ fileMessageData: ZMFileMessageData, initialConfiguration: Bool) {
        guard let fileMessageData = message.fileMessageData else {
            return
        }
        
        message.requestImageDownload()
        configureVisibleViews(forfileMessageData: fileMessageData, initialConfiguration: initialConfiguration)
        topMargin?.constant = layoutProperties.showSender ? 12 : 0
    }

    private func configureVisibleViews(forfileMessageData fileMessageData: ZMFileMessageData, initialConfiguration: Bool) {
        guard let state = FileMessageCellState.fromConversationMessage(message) else { return }
        
        var visibleViews : [UIView] = [previewImageView]
        
        
        if (state == .unavailable) {
            visibleViews = [previewImageView, loadingView]
            self.previewImageView.image = nil
        } else {
            updateTimeLabel(withFileMessageData: fileMessageData)
            
            if let previewData = fileMessageData.previewData {
                visibleViews.append(contentsOf: [previewImageView, bottomGradientView, timeLabel, playButton])
                self.previewImageView.image = UIImage(data: previewData)
                self.timeLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: .dark)
            } else {
                visibleViews.append(contentsOf: [previewImageView, timeLabel, playButton])
                self.previewImageView.image = nil
                self.timeLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground)
            }
        }
        
        if state == .uploading || state == .downloading {
            self.progressView.setProgress(fileMessageData.progress, animated: !initialConfiguration)
            visibleViews.append(progressView)
        }
        
        if let viewsState = state.viewsStateForVideo() {
            self.playButton.setIcon(viewsState.playButtonIcon, with: .actionButton, for: .normal)
            self.playButton.backgroundColor = viewsState.playButtonBackgroundColor
        }

        if state == .obfuscated {
            visibleViews = [obfuscationView]
        }
        
        self.updateVisibleViews(self.allViews, visibleViews: visibleViews, animated: !self.loadingView.isHidden)
    }
    
    private func updateTimeLabel(withFileMessageData fileMessageData: ZMFileMessageData) {
        let duration = Int(roundf(Float(fileMessageData.durationMilliseconds) / 1000.0))
        var timeLabelText = ByteCountFormatter.string(fromByteCount: Int64(fileMessageData.size), countStyle: .binary)
        
        if duration != 0 {
            let (seconds, minutes) = (duration % 60, duration / 60)
            let time = String(format: "%d:%02d", minutes, seconds)
            timeLabelText = time + " · " + timeLabelText
        }
        
        self.timeLabel.text = timeLabelText
        self.timeLabel.accessibilityValue = self.timeLabel.text
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.playButton.layer.cornerRadius = self.playButton.bounds.size.width / 2.0
    }
    
    // MARK: - Actions

    open func onActionButtonPressed(_ sender: UIButton) {
        guard let fileMessageData = self.message.fileMessageData else { return }
        
        switch(fileMessageData.transferState) {
        case .downloading:
            self.progressView.setProgress(0, animated: false)
            self.delegate?.conversationCell?(self, didSelect: .cancel)
        case .uploading:
            if .none != fileMessageData.fileURL {
                self.delegate?.conversationCell?(self, didSelect: .cancel)
            }
        case .cancelledUpload, .failedUpload:
            self.delegate?.conversationCell?(self, didSelect: .resend)
        case .uploaded, .downloaded, .failedDownload:
            self.delegate?.conversationCell?(self, didSelect: .present)
        }
    }

    // MARK: - Selection
    
    open override var selectionView: UIView! {
        return previewImageView
    }
    
    open override var selectionRect: CGRect {
        return previewImageView.bounds
    }
    
    // MARK: - Menu
    
    open func setSelectedByMenu(_ selected: Bool, animated: Bool) {
        
        let animation = {
            self.messageContentView.alpha = selected ? ConversationCellSelectedOpacity : 1.0;
        }
        
        if (animated) {
            UIView.animate(withDuration: ConversationCellSelectionAnimationDuration, animations: animation)
        } else {
            animation()
        }
    }
    
    override open func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = setSelectedByMenu

        var additionalItems = [UIMenuItem]()
        
        if message.videoCanBeSavedToCameraRoll() {
            let saveItem = UIMenuItem(title:"content.file.save_video".localized, action:#selector(wr_saveVideo))
            additionalItems.append(saveItem)
        }
        
        if let fileMessageData = message.fileMessageData,
            let _ = fileMessageData.fileURL {
            let forwardItem = UIMenuItem(title:"content.message.forward".localized, action:#selector(forward(_:)))

            additionalItems.append(forwardItem)
        }
        
        properties.additionalItems = additionalItems

        return properties
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(wr_saveVideo) {
            if self.message.videoCanBeSavedToCameraRoll() {
                return true
            }
        }
        else if action == #selector(forward(_:)) {
            if let fileMessageData = message.fileMessageData,
                let _ = fileMessageData.fileURL {
                return true
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    open func wr_saveVideo() {
        if let fileMessageData = self.message.fileMessageData,
            let fileURL = fileMessageData.fileURL,
            self.message.videoCanBeSavedToCameraRoll() {
            
            let selector = "video:didFinishSavingWithError:contextInfo:"
            UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, self, Selector(selector), nil)
        }
    }
    
    func video(_ videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let error = error {
            DDLogError("Cannot save video: \(error)")
        }
    }

}
