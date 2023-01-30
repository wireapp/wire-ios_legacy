//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import UIKit
import AVKit
import FLAnimatedImage
import WireCommonComponents

final class ConfirmAssetViewController: UIViewController {
    enum Asset {
        /// Can either be UIImage or FLAnimatedImage
        case image(mediaAsset: MediaAsset)
        case video(url: URL)
    }

    typealias Confirm = ((_ editedImage: UIImage?) -> Void)
    struct Context {
        let asset: Asset
        let onConfirm: Confirm?
        let onCancel: Completion?

        init(asset: Asset, onConfirm: Confirm? = nil, onCancel: Completion? = nil) {
            self.asset = asset
            self.onConfirm = onConfirm
            self.onCancel = onCancel
        }
    }

    var asset: Asset {
        return context.asset
    }

    let context: Context

    var previewTitle: String? {
        didSet {
            titleLabel.text = previewTitle
            view.setNeedsUpdateConstraints()
        }
    }

    private var playerViewController: AVPlayerViewController?
    private var imagePreviewView: FLAnimatedImageView?

    private var imageToolbarViewInsideImage: ImageToolbarView?
    private var imageToolbarView: ImageToolbarView?

    private let topPanel: UIView = UIView()
    private let titleLabel: DynamicFontLabel = DynamicFontLabel(fontSpec: .headerSemiboldFont,
                                                                color: SemanticColors.Label.textDefault)
    private let bottomPanel: UIView = UIView()
    private let confirmButtonsStack: UIStackView = UIStackView()
    private let acceptImageButton: Button = Button(style: .accentColorTextButtonStyle,
                                                         cornerRadius: 16,
                                                         fontSpec: .buttonBigSemibold)
    private let rejectImageButton: Button = Button(style: .secondaryTextButtonStyle,
                                                   cornerRadius: 16,
                                                   fontSpec: .buttonBigSemibold)
    private let contentLayoutGuide: UILayoutGuide = UILayoutGuide()
    private let imageToolbarSeparatorView: UIView = UIView()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    init(context: Context) {
        self.context = context

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch asset {
        case .image(let mediaAsset):
            createPreviewPanel(image: mediaAsset)
        case .video(let url):
            createVideoPanel(videoURL: url)
        }

        createTopPanel()
        createBottomPanel()
        createContentLayoutGuide()
        createConstraints()

        setupStyle()
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    // MARK: - View Creation
    private func createContentLayoutGuide() {
        view.addLayoutGuide(contentLayoutGuide)
    }

    private func createTopPanel() {
        view.addSubview(topPanel)

        titleLabel.text = previewTitle
        topPanel.addSubview(titleLabel)
    }

    private func setupStyle() {
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        view.backgroundColor = SemanticColors.View.backgroundDefault
        imageToolbarSeparatorView.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        topPanel.backgroundColor = SemanticColors.View.backgroundDefault

        titleLabel.textColor = SemanticColors.Label.textDefault
    }

    /// Show editing options only if the image is not animated
    var showEditingOptions: Bool {
        switch asset {
        case .image(let mediaAsset):
            return mediaAsset is UIImage
        case .video:
            return false
        }
    }

    private var imageToolbarFitsInsideImage: Bool {
        switch asset {
        case .image(let image):
            return image.size.width > 192 && image.size.height > 96
        case .video:
            return false
        }
    }

    private func createVideoPanel(videoURL: URL) {
        let playerViewController = AVPlayerViewController()

        playerViewController.player = AVPlayer(url: videoURL)
        playerViewController.player?.play()
        playerViewController.showsPlaybackControls = true
        playerViewController.view.backgroundColor = SemanticColors.View.backgroundDefaultWhite

        view.addSubview(playerViewController.view)

        self.playerViewController = playerViewController
    }

    /// open canvas screen if the image is sketchable(e.g. not an animated GIF)
    private func openSketch(in editMode: CanvasViewControllerEditMode) {
        guard case .image(let mediaAsset) = asset,
            let image = mediaAsset as? UIImage else {
            return
        }

        let canvasViewController = CanvasViewController()
        canvasViewController.sketchImage = image
        canvasViewController.delegate = self
        canvasViewController.title = previewTitle
        canvasViewController.select(editMode: editMode, animated: false)

        let navigationController = canvasViewController.wrapInNavigationController(setBackgroundColor: true)

        present(navigationController, animated: true)
    }

    // MARK: - View Creation
    private func createPreviewPanel(image: MediaAsset) {
        let imagePreviewView = FLAnimatedImageView()

        imagePreviewView.contentMode = .scaleAspectFit
        imagePreviewView.isUserInteractionEnabled = true
        view.addSubview(imagePreviewView)

        imagePreviewView.mediaAsset = image

        if showEditingOptions && imageToolbarFitsInsideImage {
            let imageToolbarViewInsideImage = ImageToolbarView(withConfiguraton: .preview)
            imageToolbarViewInsideImage.isPlacedOnImage = true
            imageToolbarViewInsideImage.sketchButton.addTarget(self, action: #selector(sketchEdit(_:)), for: .touchUpInside)
            imageToolbarViewInsideImage.emojiButton.addTarget(self, action: #selector(emojiEdit(_:)), for: .touchUpInside)
            imagePreviewView.addSubview(imageToolbarViewInsideImage)

            self.imageToolbarViewInsideImage = imageToolbarViewInsideImage
        }

        self.imagePreviewView = imagePreviewView
    }

    private func createBottomPanel() {
        view.addSubview(bottomPanel)

        if showEditingOptions && !imageToolbarFitsInsideImage {
            let imageToolbarView = ImageToolbarView(withConfiguraton: .preview)
            imageToolbarView.sketchButton.addTarget(self, action: #selector(sketchEdit(_:)), for: .touchUpInside)
            imageToolbarView.emojiButton.addTarget(self, action: #selector(emojiEdit(_:)), for: .touchUpInside)
            bottomPanel.addSubview(imageToolbarView)

            imageToolbarView.addSubview(imageToolbarSeparatorView)

            self.imageToolbarView = imageToolbarView
        }

        confirmButtonsStack.spacing = 16
        confirmButtonsStack.axis = NSLayoutConstraint.Axis.horizontal
        confirmButtonsStack.distribution = UIStackView.Distribution.fillEqually
        confirmButtonsStack.alignment = UIStackView.Alignment.fill

        bottomPanel.addSubview(confirmButtonsStack)

        rejectImageButton.addTarget(self, action: #selector(rejectImage(_:)), for: .touchUpInside)
        rejectImageButton.setTitle(NSLocalizedString("image_confirmer.cancel", comment: ""), for: .normal)
        confirmButtonsStack.addArrangedSubview(rejectImageButton)

        acceptImageButton.addTarget(self, action: #selector(acceptImage(_:)), for: .touchUpInside)
        acceptImageButton.setTitle(NSLocalizedString("image_confirmer.confirm", comment: ""), for: .normal)
        confirmButtonsStack.addArrangedSubview(acceptImageButton)
    }

    // MARK: - Actions
    @objc
    private func acceptImage(_ sender: Any?) {
        context.onConfirm?(nil)
    }

    @objc
    private func rejectImage(_ sender: Any?) {
        context.onCancel?()
    }

    @objc
    private func sketchEdit(_ sender: Any?) {
        openSketch(in: .draw)
    }

    @objc
    private func emojiEdit(_ sender: Any?) {
        openSketch(in: .emoji)
    }

    private func createConstraints() {
        topPanel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
        imageToolbarView?.translatesAutoresizingMaskIntoConstraints = false
        imageToolbarSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        confirmButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        acceptImageButton.translatesAutoresizingMaskIntoConstraints = false
        rejectImageButton.translatesAutoresizingMaskIntoConstraints = false
        imagePreviewView?.translatesAutoresizingMaskIntoConstraints = false
        playerViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        imageToolbarViewInsideImage?.translatesAutoresizingMaskIntoConstraints = false

        acceptImageButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rejectImageButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let margin: CGFloat = 24

        // Base constraints for all cases
        var constraints: [NSLayoutConstraint] = [
            // contentLayoutGuide
            contentLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentLayoutGuide.topAnchor.constraint(equalTo: topPanel.bottomAnchor),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor),

            // topPanel
            topPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPanel.topAnchor.constraint(equalTo: safeTopAnchor),
            topPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPanel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            // titleLabel
            titleLabel.leadingAnchor.constraint(equalTo: topPanel.leadingAnchor, constant: margin),
            titleLabel.topAnchor.constraint(equalTo: topPanel.topAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: topPanel.trailingAnchor, constant: -margin),
            titleLabel.bottomAnchor.constraint(greaterThanOrEqualTo: topPanel.bottomAnchor, constant: -4),

            // bottomPanel
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            bottomPanel.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: -margin),

            // confirmButtonsStack
            confirmButtonsStack.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
            confirmButtonsStack.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor),
            confirmButtonsStack.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor),

            // confirmButtons
            acceptImageButton.heightAnchor.constraint(equalToConstant: 48),
            rejectImageButton.heightAnchor.constraint(equalToConstant: 48)
        ]

        // Image Toolbar
        if let toolbar = imageToolbarView {
            constraints += [
                // toolbar
                toolbar.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
                toolbar.topAnchor.constraint(equalTo: bottomPanel.topAnchor),
                toolbar.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: 48),

                // buttons
                confirmButtonsStack.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: margin)
            ]

            // Separator
            constraints += [
                imageToolbarSeparatorView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
                imageToolbarSeparatorView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
                imageToolbarSeparatorView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
                imageToolbarSeparatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ]
        } else {
            constraints += [
                confirmButtonsStack.topAnchor.constraint(equalTo: bottomPanel.topAnchor)
            ]
        }

        switch asset {
        // Preview Image
        case .image(let mediaAsset):
            let imageSize: CGSize = mediaAsset.size

            if let imagePreviewView = imagePreviewView {

            constraints += [
                // dimension
                imagePreviewView.heightAnchor.constraint(equalTo: imagePreviewView.widthAnchor, multiplier: imageSize.height / imageSize.width),

                // centering
                imagePreviewView.centerXAnchor.constraint(equalTo: contentLayoutGuide.centerXAnchor),
                imagePreviewView.centerYAnchor.constraint(equalTo: contentLayoutGuide.centerYAnchor),

                // limits
                imagePreviewView.leadingAnchor.constraint(greaterThanOrEqualTo: contentLayoutGuide.leadingAnchor),
                imagePreviewView.topAnchor.constraint(greaterThanOrEqualTo: contentLayoutGuide.topAnchor, constant: margin),
                imagePreviewView.trailingAnchor.constraint(lessThanOrEqualTo: contentLayoutGuide.trailingAnchor),
                imagePreviewView.bottomAnchor.constraint(lessThanOrEqualTo: contentLayoutGuide.bottomAnchor, constant: -margin)
            ]

            // Image Toolbar Inside Image
            if let imageToolbarViewInsideImage = imageToolbarViewInsideImage {
                constraints += [
                    imageToolbarViewInsideImage.leadingAnchor.constraint(equalTo: imagePreviewView.leadingAnchor),
                    imageToolbarViewInsideImage.trailingAnchor.constraint(equalTo: imagePreviewView.trailingAnchor),
                    imageToolbarViewInsideImage.bottomAnchor.constraint(equalTo: imagePreviewView.bottomAnchor),
                    imageToolbarViewInsideImage.heightAnchor.constraint(equalToConstant: 48)
                ]
            }
            }
        // Player View
        case .video:
            if let playerView = playerViewController?.view {
                constraints += [
                    playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    playerView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: -margin),
                    playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    playerView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: -margin)
                ]
            }
        }

        NSLayoutConstraint.activate(constraints)
    }
}

extension ConfirmAssetViewController: CanvasViewControllerDelegate {
    func canvasViewController(_ canvasViewController: CanvasViewController, didExportImage image: UIImage) {
        context.onConfirm?(image)
    }
}
