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

final public class FileTransferView: UIView, TransferView {
    public var fileMessage: ZMConversationMessage?

    weak public var delegate: TransferViewDelegate?

    public let progressView = CircularProgressView()
    public let topLabel = UILabel()
    public let bottomLabel = UILabel()
    public let fileTypeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()
    public let fileEyeView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .background)
        return imageView
    }()

    private let loadingView = ThreeDotsLoadingView()
    public let actionButton = IconButton()
    
    public let labelTextColor: UIColor = .from(scheme: .textForeground)
    public let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    public let labelFont: UIFont = .smallLightFont
    public let labelBoldFont: UIFont = .smallSemiboldFont

    private var allViews : [UIView] = []
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)
        
        self.topLabel.numberOfLines = 1
        self.topLabel.lineBreakMode = .byTruncatingMiddle
        self.topLabel.accessibilityIdentifier = "FileTransferTopLabel"
        
        self.bottomLabel.numberOfLines = 1
        self.bottomLabel.accessibilityIdentifier = "FileTransferBottomLabel"
        
        self.fileTypeIconView.accessibilityIdentifier = "FileTransferFileTypeIcon"
        
        self.fileEyeView.image = UIImage(for: .eye, iconSize: .messageStatus, color: UIColor.white).withRenderingMode(.alwaysTemplate)
        
        self.actionButton.contentMode = .scaleAspectFit
        actionButton.setIconColor(.white, for: .normal)
        self.actionButton.addTarget(self, action: #selector(FileTransferView.onActionButtonPressed(_:)), for: .touchUpInside)
        self.actionButton.accessibilityIdentifier = "FileTransferActionButton"
        
        self.progressView.accessibilityIdentifier = "FileTransferProgressView"
        self.progressView.isUserInteractionEnabled = false
        
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.loadingView.isHidden = true
        
        self.allViews = [topLabel, bottomLabel, fileTypeIconView, fileEyeView, actionButton, progressView, loadingView]
        self.allViews.forEach(self.addSubview)
        
        
        
        self.createConstraints()
        
        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [topLabel, bottomLabel, fileTypeIconView, fileEyeView, actionButton])
        self.accessibilityElements = currentElements
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }
    
    private func createConstraints() {
        constrain(self, self.topLabel, self.actionButton) { selfView, topLabel, actionButton in
            topLabel.top == selfView.top + 12
            topLabel.left == actionButton.right + 12
            topLabel.right == selfView.right - 12
        }
        
        constrain(self.fileTypeIconView, self.actionButton, self) { fileTypeIconView, actionButton, selfView in
            actionButton.centerY == selfView.centerY
            actionButton.left == selfView.left + 12
            actionButton.height == 32
            actionButton.width == 32
            
            fileTypeIconView.width == 32
            fileTypeIconView.height == 32
            fileTypeIconView.center == actionButton.center
        }
        
        constrain(self.fileTypeIconView, self.fileEyeView) { fileTypeIconView, fileEyeView in
            fileEyeView.centerX == fileTypeIconView.centerX
            fileEyeView.centerY == fileTypeIconView.centerY + 3
        }
        
        constrain(self.progressView, self.actionButton) { progressView, actionButton in
            progressView.center == actionButton.center
            progressView.width == actionButton.width - 2
            progressView.height == actionButton.height - 2
        }
        
        constrain(self, self.topLabel, self.bottomLabel, self.loadingView) { messageContentView, topLabel, bottomLabel, loadingView in
            bottomLabel.top == topLabel.bottom + 2
            bottomLabel.left == topLabel.left
            bottomLabel.right == topLabel.right
            loadingView.center == loadingView.superview!.center
        }
    }
    
    public func configure(for message: ZMConversationMessage, isInitial: Bool) {
        self.fileMessage = message
        guard let fileMessageData = message.fileMessageData
            else { return }
        
        configureVisibleViews(with: message, isInitial: isInitial)
        
        let filepath = (fileMessageData.filename ?? "") as NSString
        let filesize: UInt64 = fileMessageData.size
        
        let filename = (filepath.lastPathComponent as NSString).deletingPathExtension
        let ext = filepath.pathExtension
        
        let dot = " " + String.MessageToolbox.middleDot + " " && labelFont && labelTextBlendedColor
        let fileNameAttributed = filename.uppercased() && labelBoldFont && labelTextColor
        let extAttributed = ext.uppercased() && labelFont && labelTextBlendedColor
        
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(filesize), countStyle: .binary)
        let fileSizeAttributed = fileSize && labelFont && labelTextBlendedColor
        
        fileTypeIconView.contentMode = .center
        fileTypeIconView.image = UIImage(for: .document, iconSize: .small, color: UIColor.white).withRenderingMode(.alwaysTemplate)
        
        fileMessageData.thumbnailImage.fetchImage { [weak self] (image, _) in
            guard let image = image else { return }
            
            self?.fileTypeIconView.contentMode = .scaleAspectFit
            self?.fileTypeIconView.setMediaAsset(image) 
        }
        
        self.actionButton.isUserInteractionEnabled = true
        
        switch fileMessageData.transferState {
            
        case .downloaded:
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + extAttributed
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
            
        case .downloading:
            let statusText = "content.file.downloading".localized.uppercased() && labelFont && labelTextBlendedColor
            
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + statusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
            
        case .uploading:
            let statusText = "content.file.uploading".localized.uppercased() && labelFont && labelTextBlendedColor
            
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + statusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
            
        case .uploaded, .failedDownload, .unavailable:
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + extAttributed
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
            
        case .failedUpload, .cancelledUpload:
            let statusText = fileMessageData.transferState == .failedUpload ? "content.file.upload_failed".localized : "content.file.upload_cancelled".localized
            let attributedStatusText = statusText.uppercased() && labelFont && UIColor.vividRed
            
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + attributedStatusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
        }
        
        
        self.topLabel.accessibilityValue = self.topLabel.attributedText?.string ?? ""
        self.bottomLabel.accessibilityValue = self.bottomLabel.attributedText?.string ?? ""
    }
    
    fileprivate func configureVisibleViews(with message: ZMConversationMessage, isInitial: Bool) {
        guard let state = FileMessageViewState.fromConversationMessage(message) else { return }
        
        var visibleViews : [UIView] = [topLabel, bottomLabel]
        
        switch state {
        case .obfuscated:
            visibleViews = []
        case .unavailable:
            visibleViews = [loadingView]
        case .uploading, .downloading:
            visibleViews.append(progressView)
            self.progressView.setProgress(message.fileMessageData!.progress, animated: !isInitial)
        case .uploaded, .downloaded:
            visibleViews.append(contentsOf: [fileTypeIconView, fileEyeView])
        default:
            break
        }
        
        if let viewsState = state.viewsStateForFile() {
            visibleViews.append(actionButton)
            self.actionButton.setIcon(viewsState.playButtonIcon, with: .tiny, for: .normal)
            self.actionButton.backgroundColor = viewsState.playButtonBackgroundColor
        }
        
        self.updateVisibleViews(self.allViews, visibleViews: visibleViews, animated: !self.loadingView.isHidden)
    }
    
    public override var tintColor: UIColor! {
        didSet {
            self.progressView.tintColor = self.tintColor
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.actionButton.layer.cornerRadius = self.actionButton.bounds.size.width / 2.0
    }
    
    // MARK: - Actions
    
    @objc public func onActionButtonPressed(_ sender: UIButton) {
        guard let message = self.fileMessage, let fileMessageData = message.fileMessageData else {
            return
        }
        
        switch(fileMessageData.transferState) {
        case .downloading:
            self.progressView.setProgress(0, animated: false)
            self.delegate?.transferView(self, didSelect: .cancel)
        case .uploading:
            if .none != message.fileMessageData!.fileURL {
                self.delegate?.transferView(self, didSelect: .cancel)
            }
        case .failedUpload, .cancelledUpload:
            self.delegate?.transferView(self, didSelect: .resend)
        case .failedDownload:
            self.delegate?.transferView(self, didSelect: .present)
        case .downloaded:
            self.delegate?.transferView(self, didSelect: .present)
        case .uploaded:
            self.delegate?.transferView(self, didSelect: .present)
        case .unavailable:
            break
        }
    }
}
