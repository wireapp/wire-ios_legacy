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
import Classy

final class VideoMessageView: UIView, TransferView {
    public var fileMessage: ZMConversationMessage?
    weak public var delegate: TransferViewDelegate?
    
    public var timeLabelHidden: Bool = false {
        didSet {
            self.timeLabel.isHidden = timeLabelHidden
        }
    }
    
    private let previewImageView = UIImageView()
    private let progressView = CircularProgressView()
    private let playButton = IconButton()
    private let bottomGradientView = GradientView()
    private let timeLabel = UILabel()
    private let loadingView = ThreeDotsLoadingView()
    
    private let normalColor = UIColor.black.withAlphaComponent(0.4)
    private let failureColor = UIColor.red.withAlphaComponent(0.24)
    private var allViews : [UIView] = []
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)

        self.previewImageView.contentMode = .scaleAspectFill
        self.previewImageView.clipsToBounds = true
        self.previewImageView.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorPlaceholderBackground)

        self.playButton.addTarget(self, action: #selector(VideoMessageView.onActionButtonPressed(_:)), for: .touchUpInside)
        self.playButton.accessibilityLabel = "VideoActionButton"
        self.playButton.layer.masksToBounds = true

        self.progressView.isUserInteractionEnabled = false
        self.progressView.accessibilityLabel = "VideoProgressView"
        self.progressView.deterministic = true

        self.bottomGradientView.gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]

        self.timeLabel.numberOfLines = 1
        self.timeLabel.accessibilityLabel = "VideoActionTimeLabel"

        self.loadingView.isHidden = true
        
        self.allViews = [previewImageView, playButton, bottomGradientView, progressView, timeLabel, loadingView]
        self.allViews.forEach(self.addSubview)
        
        CASStyler.default().styleItem(self)
        
        self.createConstraints()
        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [previewImageView, playButton, timeLabel, progressView])
        self.accessibilityElements = currentElements
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func createConstraints() {
        constrain(self, self.previewImageView, self.progressView, self.playButton, self.bottomGradientView) { selfView, previewImageView, progressView, playButton, bottomGradientView in
            selfView.width == selfView.height * (4.0 / 3.0) ~ 750
            previewImageView.edges == selfView.edges
            playButton.center == previewImageView.center
            playButton.width == 56
            playButton.height == playButton.width
            progressView.center == playButton.center
            progressView.width == playButton.width - 2
            progressView.height == playButton.height - 2
            bottomGradientView.left == selfView.left
            bottomGradientView.right == selfView.right
            bottomGradientView.bottom == selfView.bottom
            bottomGradientView.height == 56
        }
        
        constrain(bottomGradientView, timeLabel, previewImageView, loadingView) { bottomGradientView, timeLabel, previewImageView, loadingView in
            timeLabel.right == bottomGradientView.right - 16
            timeLabel.bottom == bottomGradientView.bottom - 16
            loadingView.center == previewImageView.center
        }
    }
    
    public func configure(for message: ZMConversationMessage, isInitial: Bool) {
        self.fileMessage = message
        
        guard let fileMessage = self.fileMessage,
              let fileMessageData = fileMessage.fileMessageData,
              let state = FileMessageViewState.fromConversationMessage(fileMessage) else { return }
        
        fileMessage.requestImageDownload()
        
        var visibleViews : [UIView] = [previewImageView]
        
        
        if (state == .unavailable) {
            visibleViews = [previewImageView, loadingView]
            self.previewImageView.image = nil
        } else {
            updateTimeLabel(withFileMessageData: fileMessageData)
            
            if let previewData = fileMessageData.previewData {
                visibleViews.append(contentsOf: [previewImageView, bottomGradientView, playButton])
                self.previewImageView.image = UIImage(data: previewData)
                self.timeLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: .dark)
            } else {
                visibleViews.append(contentsOf: [previewImageView, playButton])
                self.previewImageView.image = nil
                self.timeLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground)
            }
            
            if !self.timeLabelHidden {
                visibleViews.append(timeLabel)
            }
        }
        
        if state == .uploading || state == .downloading {
            self.progressView.setProgress(fileMessageData.progress, animated: !isInitial)
            visibleViews.append(progressView)
        }
        
        if let viewsState = state.viewsStateForVideo() {
            self.playButton.setIcon(viewsState.playButtonIcon, with: .actionButton, for: .normal)
            self.playButton.backgroundColor = viewsState.playButtonBackgroundColor
        }
        
        if state == .obfuscated {
            visibleViews = []
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
    
    override open var tintColor: UIColor! {
        didSet {
            self.progressView.tintColor = self.tintColor
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.playButton.layer.cornerRadius = self.playButton.bounds.size.width / 2.0
    }
    
    // MARK: - Actions
    
    open func onActionButtonPressed(_ sender: UIButton) {
        guard let fileMessageData = self.fileMessage?.fileMessageData else { return }
        
        switch(fileMessageData.transferState) {
        case .downloading:
            self.progressView.setProgress(0, animated: false)
            self.delegate?.transferView(self, didSelect: .cancel)
        case .uploading:
            if .none != fileMessageData.fileURL {
                self.delegate?.transferView(self, didSelect: .cancel)
            }
        case .cancelledUpload, .failedUpload:
            self.delegate?.transferView(self, didSelect: .resend)
        case .uploaded, .downloaded, .failedDownload:
            self.delegate?.transferView(self, didSelect: .present)
        }
    }
    
}
