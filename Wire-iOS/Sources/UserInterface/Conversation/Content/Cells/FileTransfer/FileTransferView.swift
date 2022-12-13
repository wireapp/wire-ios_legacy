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
import WireDataModel
import UIKit
import WireCommonComponents

final class FileTransferView: UIView, TransferView {
    var fileMessage: ZMConversationMessage?

    weak var delegate: TransferViewDelegate?

    private let progressView = CircularProgressView()
    private let topLabel = UILabel()
    private let bottomLabel = UILabel()
    private let fileTypeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .textForeground)
        return imageView
    }()
    private let fileEyeView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .background)
        return imageView
    }()

    private let loadingView = ThreeDotsLoadingView()
    private let actionButton = IconButton()

    private let labelTextColor: UIColor = .from(scheme: .textForeground)
    private let labelTextBlendedColor: UIColor = .from(scheme: .textDimmed)
    private let labelFont: UIFont = .smallLightFont
    private let labelBoldFont: UIFont = .smallSemiboldFont

    private var allViews: [UIView] = []

    required override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .from(scheme: .placeholderBackground)

        topLabel.numberOfLines = 1
        topLabel.lineBreakMode = .byTruncatingMiddle
        topLabel.accessibilityIdentifier = "FileTransferTopLabel"

        bottomLabel.numberOfLines = 1
        bottomLabel.accessibilityIdentifier = "FileTransferBottomLabel"

        fileTypeIconView.accessibilityIdentifier = "FileTransferFileTypeIcon"

        fileEyeView.setTemplateIcon(.eye, size: 8)

        actionButton.contentMode = .scaleAspectFit
        actionButton.setIconColor(.white, for: .normal)
        actionButton.addTarget(self, action: #selector(FileTransferView.onActionButtonPressed(_:)), for: .touchUpInside)
        actionButton.accessibilityIdentifier = "FileTransferActionButton"

        progressView.accessibilityIdentifier = "FileTransferProgressView"
        progressView.isUserInteractionEnabled = false

        loadingView.isHidden = true

        allViews = [topLabel, bottomLabel, fileTypeIconView, fileEyeView, actionButton, progressView, loadingView]
        allViews.forEach(addSubview)

        createConstraints()
        setupAccessibility()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = L10n.Accessibility.ConversationSearch.Item.hint
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    private func createConstraints() {
        [topLabel,
         actionButton,
         fileTypeIconView,
         fileEyeView,
         progressView,
         bottomLabel,
         loadingView].prepareForLayout()

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            topLabel.leftAnchor.constraint(equalTo: actionButton.rightAnchor, constant: 12),
            topLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),

            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            actionButton.heightAnchor.constraint(equalToConstant: 32),
            actionButton.widthAnchor.constraint(equalToConstant: 32),

            fileTypeIconView.widthAnchor.constraint(equalToConstant: 32),
            fileTypeIconView.heightAnchor.constraint(equalToConstant: 32),
            fileTypeIconView.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            fileTypeIconView.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),

            fileEyeView.centerXAnchor.constraint(equalTo: fileTypeIconView.centerXAnchor),
            fileEyeView.centerYAnchor.constraint(equalTo: fileTypeIconView.centerYAnchor, constant: 3),

            progressView.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            progressView.widthAnchor.constraint(equalTo: actionButton.widthAnchor, constant: -2),
            progressView.heightAnchor.constraint(equalTo: actionButton.heightAnchor, constant: -2),

            bottomLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 2),
            bottomLabel.leftAnchor.constraint(equalTo: topLabel.leftAnchor),
            bottomLabel.rightAnchor.constraint(equalTo: topLabel.rightAnchor),
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(for message: ZMConversationMessage, isInitial: Bool) {
        fileMessage = message
        guard let fileMessageData = message.fileMessageData else {
            return
        }

        configureVisibleViews(with: message, isInitial: isInitial)

        let filepath = (fileMessageData.filename ?? "") as NSString
        let filesize: UInt64 = fileMessageData.size
        let ext = filepath.pathExtension

        let dot = " " + String.MessageToolbox.middleDot + " " && labelFont && labelTextBlendedColor

        guard let filename = message.filename else { return }
        let fileNameAttributed = filename.uppercased() && labelBoldFont && labelTextColor
        let extAttributed = ext.uppercased() && labelFont && labelTextBlendedColor

        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(filesize), countStyle: .binary)
        let fileSizeAttributed = fileSize && labelFont && labelTextBlendedColor

        fileTypeIconView.contentMode = .center
        fileTypeIconView.setTemplateIcon(.document, size: .small)

        fileMessageData.thumbnailImage.fetchImage { [weak self] (image, _) in
            guard let image = image else { return }

            self?.fileTypeIconView.contentMode = .scaleAspectFit
            self?.fileTypeIconView.mediaAsset = image
        }

        actionButton.isUserInteractionEnabled = true

        switch fileMessageData.transferState {

        case .uploading:
            if fileMessageData.size == 0 { fallthrough }
            let statusText = "content.file.uploading".localized(uppercased: true) && labelFont && labelTextBlendedColor
            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + statusText
            topLabel.attributedText = firstLine
            bottomLabel.attributedText = secondLine
        case .uploaded:
            switch fileMessageData.downloadState {
            case .downloaded, .remote:
                let firstLine = fileNameAttributed
                let secondLine = fileSizeAttributed + dot + extAttributed
                topLabel.attributedText = firstLine
                bottomLabel.attributedText = secondLine
            case .downloading:
                let statusText = "content.file.downloading".localized(uppercased: true) && labelFont && labelTextBlendedColor
                let firstLine = fileNameAttributed
                let secondLine = fileSizeAttributed + dot + statusText
                topLabel.attributedText = firstLine
                bottomLabel.attributedText = secondLine
            }
        case .uploadingFailed, .uploadingCancelled:
            let statusText = fileMessageData.transferState == .uploadingFailed ? "content.file.upload_failed".localized : "content.file.upload_cancelled".localized
            let attributedStatusText = statusText.localizedUppercase && labelFont && SemanticColors.LegacyColors.vividRed

            let firstLine = fileNameAttributed
            let secondLine = fileSizeAttributed + dot + attributedStatusText
            topLabel.attributedText = firstLine
            bottomLabel.attributedText = secondLine
        }

        topLabel.accessibilityValue = topLabel.attributedText?.string ?? ""
        bottomLabel.accessibilityValue = bottomLabel.attributedText?.string ?? ""

        guard let fileName = topLabel.text,
                let details = bottomLabel.text else {
            return
        }
        accessibilityLabel = "\(L10n.Accessibility.ConversationSearch.FileName.description): \(fileName), \(details)"
    }

    fileprivate func configureVisibleViews(with message: ZMConversationMessage, isInitial: Bool) {
        guard let state = FileMessageViewState.fromConversationMessage(message) else { return }

        var visibleViews: [UIView] = [topLabel, bottomLabel]

        switch state {
        case .obfuscated:
            visibleViews = []
        case .unavailable:
            visibleViews = [loadingView]
        case .uploading, .downloading:
            visibleViews.append(progressView)
            progressView.setProgress(message.fileMessageData!.progress, animated: !isInitial)
        case .uploaded, .downloaded:
            visibleViews.append(contentsOf: [fileTypeIconView, fileEyeView])
        default:
            break
        }

        if let viewsState = state.viewsStateForFile() {
            visibleViews.append(actionButton)
            actionButton.setIcon(viewsState.playButtonIcon, size: .tiny, for: .normal)
            actionButton.backgroundColor = viewsState.playButtonBackgroundColor
        }

        updateVisibleViews(allViews, visibleViews: visibleViews, animated: !loadingView.isHidden)
    }

    override var tintColor: UIColor! {
        didSet {
            progressView.tintColor = tintColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        actionButton.layer.cornerRadius = actionButton.bounds.size.width / 2.0
    }

    // MARK: - Actions

    @objc func onActionButtonPressed(_ sender: UIButton) {
        guard let message = fileMessage, let fileMessageData = message.fileMessageData else {
            return
        }

        switch fileMessageData.transferState {
        case .uploading:
            if .none != message.fileMessageData!.fileURL {
                delegate?.transferView(self, didSelect: .cancel)
            }
        case .uploadingFailed, .uploadingCancelled:
            delegate?.transferView(self, didSelect: .resend)
        case .uploaded:
            if case .downloading = fileMessageData.downloadState {
                progressView.setProgress(0, animated: false)
                delegate?.transferView(self, didSelect: .cancel)
            } else {
                delegate?.transferView(self, didSelect: .present)
            }
        }
    }
}
