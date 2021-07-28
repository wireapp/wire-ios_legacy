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
import WireDataModel
import UIKit
import WireCommonComponents

final class FileTransferView: UIView, TransferView {
    var fileMessage: ZMConversationMessage?

    weak var delegate: TransferViewDelegate?

    let progressView = CircularProgressView()
    let topLabel = UILabel()
    let bottomLabel = UILabel()
    let fileTypeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()
    let fileEyeView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .background)
        return imageView
    }()

    private let loadingView = ThreeDotsLoadingView()
    let actionButton = IconButton()

    let labelTextColor: UIColor = .from(scheme: .textForeground)
    let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    let labelFont: UIFont = .smallLightFont
    let labelBoldFont: UIFont = .smallSemiboldFont

    private var allViews: [UIView] = []

    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)

        self.topLabel.numberOfLines = 1
        self.topLabel.lineBreakMode = .byTruncatingMiddle
        self.topLabel.accessibilityIdentifier = "FileTransferTopLabel"

        self.bottomLabel.numberOfLines = 1
        self.bottomLabel.accessibilityIdentifier = "FileTransferBottomLabel"

        self.fileTypeIconView.accessibilityIdentifier = "FileTransferFileTypeIcon"

        self.fileEyeView.setTemplateIcon(.eye, size: 8)

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
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

        constrain(self, self.topLabel, self.bottomLabel, self.loadingView) { _, topLabel, bottomLabel, loadingView in
            bottomLabel.top == topLabel.bottom + 2
            bottomLabel.left == topLabel.left
            bottomLabel.right == topLabel.right
            loadingView.center == loadingView.superview!.center
        }
    }

    func configure(for message: ZMConversationMessage, isInitial: Bool) {
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
        fileTypeIconView.setTemplateIcon(.document, size: .small)

        self.topLabel.accessibilityValue = self.topLabel.attributedText?.string ?? ""
        self.bottomLabel.accessibilityValue = self.bottomLabel.attributedText?.string ?? ""

        guard message.canBeReceived else {
            fileEyeView.setTemplateIcon(.block, size: 8)

            let firstLine = fileNameAttributed
            let secondLine = "feature.flag.restriction.file".localized(uppercased: true) && labelFont && labelTextBlendedColor
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine

            self.actionButton.isUserInteractionEnabled = false
            return
        }

        fileMessageData.thumbnailImage.fetchImage { [weak self] (image, _) in
            guard let image = image else { return }

            self?.fileTypeIconView.contentMode = .scaleAspectFit
            self?.fileTypeIconView.mediaAsset = image
        }

        self.actionButton.isUserInteractionEnabled = true

        switch fileMessageData.transferState {

        case .uploading:
            if fileMessageData.size == 0 { fallthrough }
            let statusText = "content.file.uploading".localized(uppercased: true) && labelFont && labelTextBlendedColor
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + statusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
        case .uploaded:
            switch fileMessageData.downloadState {
            case .downloaded, .remote:
                let firstLine = fileNameAttributed
                let secondLine = fileSizeAttributed + dot + extAttributed
                self.topLabel.attributedText = firstLine
                self.bottomLabel.attributedText = secondLine
            case .downloading:
                let statusText = "content.file.downloading".localized(uppercased: true) && labelFont && labelTextBlendedColor
                let firstLine = fileNameAttributed
                let secondLine = fileSizeAttributed + dot + statusText
                self.topLabel.attributedText = firstLine
                self.bottomLabel.attributedText = secondLine
            }
        case .uploadingFailed, .uploadingCancelled:
            let statusText = fileMessageData.transferState == .uploadingFailed ? "content.file.upload_failed".localized : "content.file.upload_cancelled".localized
            let attributedStatusText = statusText.localizedUppercase && labelFont && UIColor.vividRed

            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + attributedStatusText
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine
        }
    }

    fileprivate func configureVisibleViews(with message: ZMConversationMessage, isInitial: Bool) {
        //check
        guard let state = FileMessageViewState.fromConversationMessage(message) else { return }

        var visibleViews: [UIView] = [topLabel, bottomLabel]

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
            self.actionButton.setIcon(viewsState.playButtonIcon, size: .tiny, for: .normal)
            self.actionButton.backgroundColor = viewsState.playButtonBackgroundColor
        }

        self.updateVisibleViews(self.allViews, visibleViews: visibleViews, animated: !self.loadingView.isHidden)
    }

    override var tintColor: UIColor! {
        didSet {
            self.progressView.tintColor = self.tintColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.actionButton.layer.cornerRadius = self.actionButton.bounds.size.width / 2.0
    }

    // MARK: - Actions

    @objc func onActionButtonPressed(_ sender: UIButton) {
        // do not allow
        guard let message = self.fileMessage, let fileMessageData = message.fileMessageData else {
            return
        }

        switch fileMessageData.transferState {
        case .uploading:
            if .none != message.fileMessageData!.fileURL {
                self.delegate?.transferView(self, didSelect: .cancel)
            }
        case .uploadingFailed, .uploadingCancelled:
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


final class FileTransferView1: UIView {
    var fileMessage: ZMConversationMessage?


    let topLabel = UILabel()
    let bottomLabel = UILabel()
    let fileTypeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()
    let fileEyeView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .background)
        return imageView
    }()

    let labelTextColor: UIColor = .from(scheme: .textForeground)
    let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    let labelFont: UIFont = .smallLightFont
    let labelBoldFont: UIFont = .smallSemiboldFont

    private var allViews: [UIView] = []

    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)

        self.topLabel.numberOfLines = 1
        self.topLabel.lineBreakMode = .byTruncatingMiddle
        self.topLabel.accessibilityIdentifier = "AudioTransferTopLabel"

        self.bottomLabel.numberOfLines = 1
        self.bottomLabel.accessibilityIdentifier = "AudioTransferBottomLabel"

        self.fileTypeIconView.accessibilityIdentifier = "AudioTransferFileTypeIcon"

        self.fileEyeView.setTemplateIcon(.eye, size: 8)

        self.allViews = [topLabel, bottomLabel, fileTypeIconView, fileEyeView]
        self.allViews.forEach(self.addSubview)

        self.createConstraints()

        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [topLabel, bottomLabel, fileTypeIconView, fileEyeView])
        self.accessibilityElements = currentElements
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    private func createConstraints() {
        constrain(self, self.topLabel, self.fileTypeIconView) { selfView, topLabel, fileTypeIconView in
            topLabel.top == selfView.top + 12
            topLabel.left == fileTypeIconView.right + 12
            topLabel.right == selfView.right - 12

            fileTypeIconView.centerY == selfView.centerY
            fileTypeIconView.left == selfView.left + 12
            fileTypeIconView.width == 32
            fileTypeIconView.height == 32
        }

        constrain(self.fileTypeIconView, self.fileEyeView) { fileTypeIconView, fileEyeView in
            fileEyeView.centerX == fileTypeIconView.centerX
            fileEyeView.centerY == fileTypeIconView.centerY + 3
        }

        constrain(self, self.topLabel, self.bottomLabel) { _, topLabel, bottomLabel in
            bottomLabel.top == topLabel.bottom + 2
            bottomLabel.left == topLabel.left
            bottomLabel.right == topLabel.right
        }
    }

    func configure(for message: ZMConversationMessage) {
        self.fileMessage = message
        guard let fileMessageData = message.fileMessageData
            else { return }
        let fileNameAttributed = "conversation.input_bar.message_preview.audio".localized.localizedUppercase && labelBoldFont && labelTextColor


        fileTypeIconView.contentMode = .center
//        fileTypeIconView.setTemplateIcon(.document, size: .small)
        fileTypeIconView.setTemplateIcon(.microphone, size: .small)

        self.topLabel.accessibilityValue = self.topLabel.attributedText?.string ?? ""
        self.bottomLabel.accessibilityValue = self.bottomLabel.attributedText?.string ?? ""

        guard message.canBeReceived else {
//            fileEyeView.setTemplateIcon(.block, size: 8)

            let firstLine = fileNameAttributed
            let secondLine = "feature.flag.restriction.audio".localized(uppercased: true) && labelFont && labelTextBlendedColor
            self.topLabel.attributedText = firstLine
            self.bottomLabel.attributedText = secondLine

            return
        }
    }
}

final class FileTransferView2: UIView {
    var fileMessage: ZMConversationMessage?

    let topLabel = UILabel()
    let fileTypeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()

    let labelTextColor: UIColor = .from(scheme: .textForeground)
    let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    let labelFont: UIFont = .smallLightFont
    let labelBoldFont: UIFont = .smallSemiboldFont

    private var allViews: [UIView] = []

    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)

        self.topLabel.numberOfLines = 3
        self.topLabel.lineBreakMode = .byTruncatingMiddle
        self.topLabel.accessibilityIdentifier = "VideoTransferTopLabel"

        self.fileTypeIconView.accessibilityIdentifier = "VideoTransferFileTypeIcon"

        self.allViews = [topLabel, fileTypeIconView]
        self.allViews.forEach(self.addSubview)

        self.createConstraints()

        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [topLabel, fileTypeIconView])
        self.accessibilityElements = currentElements

        fileTypeIconView.clipsToBounds = true
        fileTypeIconView.layer.cornerRadius = 16
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    private func createConstraints() {
        constrain(self, self.topLabel, self.fileTypeIconView) { selfView, topLabel, fileTypeIconView in
            fileTypeIconView.centerY == selfView.centerY - 12
            fileTypeIconView.centerX == selfView.centerX
            fileTypeIconView.width == 32
            fileTypeIconView.height == 32

            topLabel.centerX == selfView.centerX
            topLabel.top == fileTypeIconView.bottom + 12
        }
    }

    func configure(for message: ZMConversationMessage) {
        self.fileMessage = message
        guard let fileMessageData = message.fileMessageData
            else { return }


        fileTypeIconView.contentMode = .center
        fileTypeIconView.setTemplateIcon(.play, size: .tiny)
        fileTypeIconView.backgroundColor = .white

        self.topLabel.accessibilityValue = self.topLabel.attributedText?.string ?? ""

        guard message.canBeReceived else {
            let firstLine = "feature.flag.restriction.video".localized(uppercased: true) && labelFont && labelTextBlendedColor
            self.topLabel.attributedText = firstLine

            return
        }
    }
}

final class FileTransferView3: UIView {
    var fileMessage: ZMConversationMessage?

    let topLabel = UILabel()
    let fileTypeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()

    let labelTextColor: UIColor = .from(scheme: .textForeground)
    let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    let labelFont: UIFont = .smallLightFont
    let labelBoldFont: UIFont = .smallSemiboldFont

    private var allViews: [UIView] = []

    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)

        self.topLabel.numberOfLines = 3
        self.topLabel.lineBreakMode = .byTruncatingMiddle
        self.topLabel.accessibilityIdentifier = "PictureTransferTopLabel"

        self.fileTypeIconView.accessibilityIdentifier = "PictureTransferFileTypeIcon"

        self.allViews = [topLabel, fileTypeIconView]
        self.allViews.forEach(self.addSubview)

        self.createConstraints()

        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [topLabel, fileTypeIconView])
        self.accessibilityElements = currentElements

//        fileTypeIconView.clipsToBounds = true
//        fileTypeIconView.layer.cornerRadius = 16
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    private func createConstraints() {
        constrain(self, self.topLabel, self.fileTypeIconView) { selfView, topLabel, fileTypeIconView in
            fileTypeIconView.centerY == selfView.centerY - 12
            fileTypeIconView.centerX == selfView.centerX
            fileTypeIconView.width == 32
            fileTypeIconView.height == 32

            topLabel.centerX == selfView.centerX
            topLabel.top == fileTypeIconView.bottom + 12
        }
    }

    func configure(for message: ZMConversationMessage) {
        self.fileMessage = message
        guard let fileMessageData = message.fileMessageData
            else { return }


        fileTypeIconView.contentMode = .center
        fileTypeIconView.setTemplateIcon(.photo, size: .small)
       // fileTypeIconView.backgroundColor = .red

        self.topLabel.accessibilityValue = self.topLabel.attributedText?.string ?? ""

        guard message.canBeReceived else {
            let firstLine = "feature.flag.restriction.picture".localized(uppercased: true) && labelFont && labelTextBlendedColor
            self.topLabel.attributedText = firstLine

            return
        }
    }
}
