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

// Cell that disaplys the file transfer and it's states
public class FileTransferCell: ConversationCell {
    let containerView = UIView()
    let progressView = CircularProgressView()
    let topLabel = UILabel()
    let bottomLabel = UILabel()
    let fileTypeIconView = UIImageView()
    let loadingView = ThreeDotsLoadingView()
    let actionButton = IconButton()
    
    var labelTextColor: UIColor?
    var labelTextBlendedColor: UIColor?
    var labelFont: UIFont?
    var labelBoldFont: UIFont?
    var allViews : [UIView] = []
    
    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.layer.cornerRadius = 4
        self.containerView.cas_styleClass = "container-view"
        
        self.topLabel.numberOfLines = 1
        self.topLabel.lineBreakMode = .ByTruncatingMiddle
        self.topLabel.accessibilityLabel = "FileTransferTopLabel"

        self.bottomLabel.numberOfLines = 1
        self.bottomLabel.accessibilityLabel = "FileTransferBottomLabel"

        self.fileTypeIconView.accessibilityLabel = "FileTransferFileTypeIcon"

        self.actionButton.contentMode = .ScaleAspectFit
        self.actionButton.addTarget(self, action: #selector(FileTransferCell.onActionButtonPressed(_:)), forControlEvents: .TouchUpInside)
        self.actionButton.accessibilityLabel = "FileTransferActionButton"

        self.progressView.accessibilityLabel = "FileTransferProgressView"
        self.progressView.userInteractionEnabled = false
        
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.loadingView.hidden = true
        
        self.messageContentView.addSubview(self.containerView)
        
        self.allViews = [topLabel, bottomLabel, fileTypeIconView, actionButton, progressView, loadingView]
        self.allViews.forEach(self.containerView.addSubview)
        
        CASStyler.defaultStyler().styleItem(self)
        
        self.createConstraints()
        
        var currentElements = self.accessibilityElements ?? []
        currentElements.appendContentsOf([topLabel, bottomLabel, fileTypeIconView, actionButton, likeButton, messageToolboxView])
        self.accessibilityElements = currentElements
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func createConstraints() {
        constrain(self.messageContentView, self.containerView, self.authorLabel, self.topLabel, self.actionButton) { messageContentView, containerView, authorLabel, topLabel, actionButton in
            containerView.left == authorLabel.left
            containerView.right == messageContentView.rightMargin
            containerView.top == messageContentView.top
            containerView.bottom == messageContentView.bottom ~ 100
            containerView.height == 56
            
            topLabel.top == containerView.top + 12
            topLabel.left == actionButton.right + 12
            topLabel.right == containerView.right - 12
        }
        
        constrain(self.fileTypeIconView, self.actionButton, self.containerView) { fileTypeIconView, actionButton, containerView in
            actionButton.centerY == containerView.centerY
            actionButton.left == containerView.left + 12
            actionButton.height == 32
            actionButton.width == 32
            
            fileTypeIconView.width == 32
            fileTypeIconView.height == 32
            fileTypeIconView.center == actionButton.center
        }
        
        constrain(self.progressView, self.actionButton) { progressView, actionButton in
            progressView.center == actionButton.center
            progressView.width == actionButton.width - 2
            progressView.height == actionButton.height - 2
        }
        
        constrain(self.messageContentView, self.topLabel, self.bottomLabel, self.loadingView) { messageContentView, topLabel, bottomLabel, loadingView in
            bottomLabel.top == topLabel.bottom + 2
            bottomLabel.left == topLabel.left
            bottomLabel.right == topLabel.right
            loadingView.center == loadingView.superview!.center
        }
    }
    
    public override func updateForMessage(changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.updateForMessage(changeInfo)
        self.configureForFileTransferMessage(self.message.fileMessageData!, initialConfiguration: false)
        return needsLayout
    }
    
    override public func configureForMessage(message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configureForMessage(message, layoutProperties: layoutProperties)
        
        if Message.isFileTransferMessage(message) {
            self.configureForFileTransferMessage(message.fileMessageData!, initialConfiguration: true)
        }
    }
    
    private func configureForFileTransferMessage(fileMessageData: ZMFileMessageData, initialConfiguration: Bool) {
        guard let labelBoldFont = self.labelBoldFont,
            let labelFont = self.labelFont,
            let labelTextColor = self.labelTextColor,
            let labelTextBlendedColor = self.labelTextBlendedColor,
            let fileMessageData = message.fileMessageData
        else {
            return
        }
        
        configureVisibleViews(withFileMessageData: fileMessageData, initialConfiguration: initialConfiguration)
        message.requestImageDownload()
        
        let filepath = fileMessageData.filename as NSString
        let filesize: UInt64 = fileMessageData.size
        
        let filename = (filepath.lastPathComponent as NSString).stringByDeletingPathExtension
        let ext = filepath.pathExtension
        
        let dot = " · " && labelFont && labelTextBlendedColor
        let fileNameAttributed = filename.uppercaseString && labelBoldFont && labelTextColor
        let extAttributed = ext.uppercaseString && labelFont && labelTextBlendedColor
        
        let fileSize = NSByteCountFormatter.stringFromByteCount(Int64(filesize), countStyle: .Binary)
        let fileSizeAttributed = fileSize && labelFont && labelTextBlendedColor
        
        if let previewData = fileMessageData.previewData {
            self.fileTypeIconView.contentMode = .ScaleAspectFit
            self.fileTypeIconView.image = UIImage(data: previewData)
        }
        else {
            self.fileTypeIconView.contentMode = .Center
            self.fileTypeIconView.image = UIImage(forIcon: .Document, iconSize: .Tiny, color: UIColor.whiteColor()).imageWithRenderingMode(.AlwaysTemplate)
        }
        
        self.actionButton.userInteractionEnabled = true
        
        switch fileMessageData.transferState {
            
        case .Downloaded:
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + extAttributed
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
            
        case .Downloading:
            let statusText = "content.file.downloading".localized.uppercaseString && labelFont && labelTextBlendedColor
            
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + statusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
            
        case .Uploading:
            let statusText = "content.file.uploading".localized.uppercaseString && labelFont && labelTextBlendedColor
            
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + statusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
        
        case .Uploaded, .FailedDownload:
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + extAttributed
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine

        case .FailedUpload, .CancelledUpload:
            let statusText = fileMessageData.transferState == .FailedUpload ? "content.file.upload_failed".localized : "content.file.upload_cancelled".localized
            let attributedStatusText = statusText.uppercaseString && labelFont && UIColor(forZMAccentColor: .VividRed)

            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + attributedStatusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
        }
        
        
        self.topLabel.accessibilityValue = self.topLabel.attributedText?.string ?? ""
        self.bottomLabel.accessibilityValue = self.bottomLabel.attributedText?.string ?? ""
    }
    
    private func configureVisibleViews(withFileMessageData fileMessageData: ZMFileMessageData, initialConfiguration: Bool) {
        guard let state = FileMessageCellState.fromConversationMessage(message) else { return }
        
        var visibleViews : [UIView] = [topLabel, bottomLabel]
        
        switch state {
        case .Unavailable:
            visibleViews = [loadingView]
        case .Uploading, .Downloading:
            visibleViews.append(progressView)
            self.progressView.setProgress(fileMessageData.progress, animated: !initialConfiguration)
        case .Uploaded, .Downloaded:
            visibleViews.append(fileTypeIconView)
        default:
            break
        }
        
        if let viewsState = state.viewsStateForFile() {
            visibleViews.append(actionButton)
            self.actionButton.setIcon(viewsState.playButtonIcon, withSize: .Tiny, forState: .Normal)
            self.actionButton.backgroundColor = viewsState.playButtonBackgroundColor
        }
        
        self.updateVisibleViews(self.allViews, visibleViews: visibleViews, animated: !self.loadingView.hidden)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.actionButton.layer.cornerRadius = self.actionButton.bounds.size.width / 2.0
    }
    
    // MARK: - Selection
    
    public override var selectionView: UIView! {
        return containerView
    }
    
    public override var selectionRect: CGRect {
        return containerView.bounds
    }

    // MARK: - Actions
    
    public func onActionButtonPressed(sender: UIButton) {
        switch(self.message.fileMessageData!.transferState) {
        case .Downloading:
            self.progressView.setProgress(0, animated: false)
            self.delegate?.conversationCell?(self, didSelectAction: .Cancel)
        case .Uploading:
            if .None != message.fileMessageData!.fileURL {
                self.delegate?.conversationCell?(self, didSelectAction: .Cancel)
            }
        case .FailedUpload:
            fallthrough
        case .CancelledUpload:
            self.delegate?.conversationCell?(self, didSelectAction: .Resend)
        case .FailedDownload:
            self.delegate?.conversationCell?(self, didSelectAction: .Present)
        case .Downloaded:
            self.delegate?.conversationCell?(self, didSelectAction: .Present)
        case .Uploaded:
            self.delegate?.conversationCell?(self, didSelectAction: .Present)
            break
        }
    }
    
    // MARK: - Delete
    
    override public func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = { [weak self] selected, animated in
            UIView.animateWithDuration(animated ? ConversationCellSelectionAnimationDuration : 0) {
                self?.messageContentView.alpha = selected ? ConversationCellSelectedOpacity : 1.0
            }
        }
        
        return properties
    }
    
    override public func messageType() -> MessageType {
        return .File
    }
}
