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

extension ZMConversationMessage {
    public func videoCanBeSavedToCameraRoll() -> Bool {
        if let fileMessageData = self.fileMessageData,
            let fileURL = fileMessageData.fileURL,
            let filePath = fileURL.path
            where UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath) && fileMessageData.isVideo() {
            return true
        }
        else {
            return false
        }
    }
}

/// Displays the video message with different states
@objc public class VideoMessageCell: ConversationCell {
    private let previewImageView = UIImageView()
    private let progressView = CircularProgressView()
    private let playButton = IconButton()
    private let bottomGradientView = GradientView()
    private let timeLabel = UILabel()
    private let loadingView = ThreeDotsLoadingView()
    private var topMargin : NSLayoutConstraint?
    
    private let normalColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
    private let failureColor = UIColor.redColor().colorWithAlphaComponent(0.24)
    private var allViews : [UIView] = []
    
    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.previewImageView.translatesAutoresizingMaskIntoConstraints = false
        self.previewImageView.contentMode = .ScaleAspectFill
        self.previewImageView.clipsToBounds = true
        self.previewImageView.backgroundColor = UIColor.wr_colorFromColorScheme(ColorSchemeColorPlaceholderBackground)
        
        self.playButton.translatesAutoresizingMaskIntoConstraints = false
        self.playButton.addTarget(self, action: #selector(VideoMessageCell.onActionButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.playButton.accessibilityLabel = "VideoActionButton"
        self.playButton.layer.masksToBounds = true
        
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.progressView.userInteractionEnabled = false
        self.progressView.accessibilityLabel = "VideoProgressView"
        self.progressView.deterministic = true
        
        self.bottomGradientView.translatesAutoresizingMaskIntoConstraints = false
        self.bottomGradientView.gradientLayer.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().colorWithAlphaComponent(0.4).CGColor]
        
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.timeLabel.numberOfLines = 1
        self.timeLabel.accessibilityLabel = "VideoActionTimeLabel"
        
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.loadingView.hidden = true
        
        self.allViews = [previewImageView, playButton, bottomGradientView, progressView, timeLabel, loadingView]
        self.allViews.forEach(messageContentView.addSubview)
        
        CASStyler.defaultStyler().styleItem(self)
        
        self.createConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func createConstraints() {
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
    }
    
    public override func updateForMessage(changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.updateForMessage(changeInfo)
        
        if let fileMessageData = self.message.fileMessageData {
            self.configureForVideoMessage(fileMessageData, initialConfiguration: false)
        }
        
        return needsLayout
    }
    
    override public func configureForMessage(message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configureForMessage(message, layoutProperties: layoutProperties)
        
        if Message.isVideoMessage(message), let fileMessageData = message.fileMessageData {
            self.configureForVideoMessage(fileMessageData, initialConfiguration: true)
        }
        else {
            fatalError("Wrong message type: \(message.dynamicType): \(message)")
        }
    }
    
    private func configureForVideoMessage(fileMessageData: ZMFileMessageData, initialConfiguration: Bool) {
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
        
        
        if (state == .Unavailable) {
            visibleViews = [previewImageView, loadingView]
            self.previewImageView.image = nil
        } else {
            updateTimeLabel(withFileMessageData: fileMessageData)
            
            if let previewData = fileMessageData.previewData {
                visibleViews.appendContentsOf([previewImageView, bottomGradientView, timeLabel, playButton])
                self.previewImageView.image = UIImage(data: previewData)
                self.timeLabel.textColor = UIColor.wr_colorFromColorScheme(ColorSchemeColorTextForeground, variant: .Dark)
            } else {
                visibleViews.appendContentsOf([previewImageView, timeLabel, playButton])
                self.previewImageView.image = nil
                self.timeLabel.textColor = UIColor.wr_colorFromColorScheme(ColorSchemeColorTextForeground)
            }
        }
        
        if state == .Uploading || state == .Downloading {
            self.progressView.setProgress(fileMessageData.progress, animated: !initialConfiguration)
            visibleViews.append(progressView)
        }
        
        if let viewsState = state.viewsStateForVideo() {
            self.playButton.setIcon(viewsState.playButtonIcon, withSize: .ActionButton, forState: .Normal)
            self.playButton.backgroundColor = viewsState.playButtonBackgroundColor
        }
        
        self.updateVisibleViews(self.allViews, visibleViews: visibleViews, animated: !self.loadingView.hidden)
    }
    
    private func updateTimeLabel(withFileMessageData fileMessageData: ZMFileMessageData) {
        let duration = Int(roundf(Float(fileMessageData.durationMilliseconds) / 1000.0))
        var timeLabelText = NSByteCountFormatter.stringFromByteCount(Int64(fileMessageData.size), countStyle: .Binary)
        
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

    public func onActionButtonPressed(sender: UIButton) {
        guard let fileMessageData = self.message.fileMessageData else { return }
        
        switch(fileMessageData.transferState) {
        case .Downloading:
            self.progressView.setProgress(0, animated: false)
            self.delegate?.conversationCell?(self, didSelectAction: .Cancel)
        case .Uploading:
            if .None != fileMessageData.fileURL {
                self.delegate?.conversationCell?(self, didSelectAction: .Cancel)
            }
        case .CancelledUpload, .FailedUpload:
            self.delegate?.conversationCell?(self, didSelectAction: .Resend)
        case .Uploaded, .Downloaded, .FailedDownload:
            self.delegate?.conversationCell?(self, didSelectAction: .Present)
        }
    }

    // MARK: - Selection
    
    public override var selectionView: UIView! {
        return previewImageView
    }
    
    public override var selectionRect: CGRect {
        return previewImageView.bounds
    }
    
    // MARK: - Menu
    
    public func setSelectedByMenu(selected: Bool, animated: Bool) {
        
        let animation = {
            self.messageContentView.alpha = selected ? ConversationCellSelectedOpacity : 1.0;
        }
        
        if (animated) {
            UIView.animateWithDuration(ConversationCellSelectionAnimationDuration, animations: animation)
        } else {
            animation()
        }
    }
    
    override public func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = setSelectedByMenu

        if message.videoCanBeSavedToCameraRoll() {
            let menuItem = UIMenuItem(title:"content.file.save_video".localized, action:#selector(wr_saveVideo))
            properties.additionalItems = [menuItem]
        } else {
            properties.additionalItems = []
        }

        return properties
    }

    override public func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == #selector(wr_saveVideo) {
            if self.message.videoCanBeSavedToCameraRoll() {
                return true
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    public func wr_saveVideo() {
        if let fileMessageData = self.message.fileMessageData,
            let fileURL = fileMessageData.fileURL,
            let filePath = fileURL.path
            where self.message.videoCanBeSavedToCameraRoll() {
            
            let selector = "video:didFinishSavingWithError:contextInfo:"
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, Selector(selector), nil)
        }
    }
    
    func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let error = error {
            DDLogError("Cannot save video: \(error)")
        }
    }
}
