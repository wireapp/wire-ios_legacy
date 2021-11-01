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
import UIKit
import WireDataModel
import WireCommonComponents

final class VideoMessageView: UIView, TransferView {
    var fileMessage: ZMConversationMessage?
    weak var delegate: TransferViewDelegate?

    var timeLabelHidden: Bool = false {
        didSet {
            self.timeLabel.isHidden = timeLabelHidden
        }
    }

    private let previewImageView = UIImageView()
    private let progressView = CircularProgressView()
    private let playButton: IconButton = {
        let button = IconButton()
        button.setIconColor(.white, for: .normal)
        return button
    }()
    private let bottomGradientView = GradientView()
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .smallLightFont

        return label
    }()
    private let loadingView = ThreeDotsLoadingView()

    private let normalColor = UIColor.black.withAlphaComponent(0.4)
    private let failureColor = UIColor.red.withAlphaComponent(0.24)
    private var allViews: [UIView] = []
    private var state: FileMessageViewState = .unavailable

    required override init(frame: CGRect) {
        super.init(frame: frame)

        self.previewImageView.contentMode = .scaleAspectFill
        self.previewImageView.clipsToBounds = true
        self.previewImageView.backgroundColor = UIColor.from(scheme: .placeholderBackground)

        self.playButton.addTarget(self, action: #selector(VideoMessageView.onActionButtonPressed(_:)), for: .touchUpInside)
        self.playButton.accessibilityIdentifier = "VideoActionButton"
        self.playButton.accessibilityLabel = "VideoActionButton"
        self.playButton.layer.masksToBounds = true

        self.progressView.isUserInteractionEnabled = false
        self.progressView.accessibilityIdentifier = "VideoProgressView"
        self.progressView.deterministic = true

        self.bottomGradientView.gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]

        self.timeLabel.numberOfLines = 1
        self.timeLabel.accessibilityIdentifier = "VideoActionTimeLabel"

        self.loadingView.isHidden = true

        self.allViews = [previewImageView, playButton, bottomGradientView, progressView, timeLabel, loadingView]
        self.allViews.forEach(self.addSubview)

        createConstraints()
        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [previewImageView, playButton, timeLabel, progressView])
        self.accessibilityElements = currentElements

        setNeedsLayout()
        layoutIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {

        [self,
         previewImageView,
         progressView,
         playButton,
         bottomGradientView,
         timeLabel,
         loadingView].prepareForLayout()

        let sizeConstraint = widthAnchor.constraint(equalTo: heightAnchor, constant: 4/3)

        sizeConstraint.priority = UILayoutPriority(750)

        NSLayoutConstraint.activate(
            [sizeConstraint,
             previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
             previewImageView.topAnchor.constraint(equalTo: topAnchor),
             previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
             previewImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

             playButton.centerXAnchor.constraint(equalTo: previewImageView.centerXAnchor),
             playButton.centerYAnchor.constraint(equalTo: previewImageView.centerYAnchor),
             playButton.widthAnchor.constraint(equalToConstant: 56),
             playButton.widthAnchor.constraint(equalTo: playButton.heightAnchor),

             progressView.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
             progressView.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),

             progressView.widthAnchor.constraint(equalTo: playButton.widthAnchor, constant: -2),
             progressView.heightAnchor.constraint(equalTo: playButton.heightAnchor, constant: -2),

             bottomGradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
             bottomGradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
             bottomGradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
             bottomGradientView.heightAnchor.constraint(equalToConstant: 56),

             timeLabel.rightAnchor.constraint(equalTo: bottomGradientView.rightAnchor, constant: -16),
             timeLabel.bottomAnchor.constraint(equalTo: bottomGradientView.bottomAnchor, constant: -16),

             loadingView.centerXAnchor.constraint(equalTo: previewImageView.centerXAnchor),
             loadingView.centerYAnchor.constraint(equalTo: previewImageView.centerYAnchor)]
        )
    }

    func configure(for message: ZMConversationMessage, isInitial: Bool) {
        self.fileMessage = message

        guard let fileMessage = self.fileMessage,
            let fileMessageData = fileMessage.fileMessageData,
            let state = FileMessageViewState.fromConversationMessage(fileMessage) else { return }

        self.state = state
        self.previewImageView.image = nil

        if state != .unavailable {
            updateTimeLabel(withFileMessageData: fileMessageData)
            self.timeLabel.textColor = UIColor.from(scheme: .textForeground)

            fileMessageData.thumbnailImage.fetchImage { [weak self] (image, _) in
                guard let image = image else { return }
                self?.updatePreviewImage(image)
            }
        }

        if state == .uploading || state == .downloading {
            self.progressView.setProgress(fileMessageData.progress, animated: !isInitial)
        }

        if let viewsState = state.viewsStateForVideo() {
            self.playButton.setIcon(viewsState.playButtonIcon, size: 28, for: .normal)
            self.playButton.backgroundColor = viewsState.playButtonBackgroundColor
        }

        updateVisibleViews()
    }

    private func visibleViews(for state: FileMessageViewState) -> [UIView] {
        guard state != .obfuscated else {
            return []
        }

        guard state != .unavailable else {
            return [loadingView]
        }

        var visibleViews: [UIView] = [playButton, previewImageView]

        switch state {
        case .uploading, .downloading:
            visibleViews.append(progressView)
        default:
            break
        }

        if !previewImageView.isHidden && previewImageView.image != nil {
            visibleViews.append(bottomGradientView)
        }

        if !timeLabelHidden {
            visibleViews.append(timeLabel)
        }

        return visibleViews
    }

    private func updatePreviewImage(_ image: MediaAsset) {
        previewImageView.mediaAsset = image
        timeLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        updateVisibleViews()
    }

    private func updateTimeLabel(withFileMessageData fileMessageData: ZMFileMessageData) {
        let duration = Int(roundf(Float(fileMessageData.durationMilliseconds) / 1000.0))
        var timeLabelText = ByteCountFormatter.string(fromByteCount: Int64(fileMessageData.size), countStyle: .binary)

        if duration != 0 {
            let (seconds, minutes) = (duration % 60, duration / 60)
            let time = String(format: "%d:%02d", minutes, seconds)
            timeLabelText = time + " " + String.MessageToolbox.middleDot + " " + timeLabelText
        }

        self.timeLabel.text = timeLabelText
        self.timeLabel.accessibilityValue = self.timeLabel.text
    }

    private func updateVisibleViews() {
        updateVisibleViews(allViews, visibleViews: visibleViews(for: state), animated: !self.loadingView.isHidden)
    }

    override var tintColor: UIColor! {
        didSet {
            self.progressView.tintColor = self.tintColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.playButton.layer.cornerRadius = self.playButton.bounds.size.width / 2.0
    }

    // MARK: - Actions

    @objc
    func onActionButtonPressed(_ sender: UIButton) {
        guard let fileMessageData = self.fileMessage?.fileMessageData else { return }

        switch fileMessageData.transferState {
        case .uploading:
            if .none != fileMessageData.fileURL {
                self.delegate?.transferView(self, didSelect: .cancel)
            }
        case .uploadingCancelled, .uploadingFailed:
            self.delegate?.transferView(self, didSelect: .resend)
        case .uploaded:
            if case .downloading = fileMessageData.downloadState {
                self.progressView.setProgress(0, animated: false)
                self.delegate?.transferView(self, didSelect: .cancel)
            } else {
                self.delegate?.transferView(self, didSelect: .present)
            }
        }
    }

}
