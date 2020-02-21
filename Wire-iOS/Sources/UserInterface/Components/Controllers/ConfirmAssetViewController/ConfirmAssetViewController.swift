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
import AVKit
import FLAnimatedImage

extension ConfirmAssetViewController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    @objc func setupStyle() {
        applyColorScheme(ColorScheme.default.variant)

        titleLabel.font = UIFont.mediumSemiboldFont
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        acceptImageButton.layer.cornerRadius = 8
        acceptImageButton.titleLabel?.font = .smallSemiboldFont

        rejectImageButton.layer.cornerRadius = 8
        rejectImageButton.titleLabel?.font = .smallSemiboldFont
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        view.backgroundColor = UIColor.from(scheme: .background)
        imageToolbarSeparatorView?.backgroundColor = UIColor.from(scheme: .separator)
        topPanel.backgroundColor = UIColor.from(scheme: .background)

        titleLabel.textColor = UIColor.from(scheme: .textForeground)

        acceptImageButton.setTitleColor(.white, for: .normal)
        acceptImageButton.setTitleColor(.whiteAlpha40, for: .highlighted)
        acceptImageButton.setBackgroundImageColor(UIColor.accent(), for: .normal)
        acceptImageButton.setBackgroundImageColor(UIColor.accentDarken, for: .highlighted)

        rejectImageButton.setTitleColor(UIColor.from(scheme: .textForeground, variant: colorSchemeVariant), for: .normal)
        rejectImageButton.setTitleColor(UIColor.from(scheme: .textDimmed, variant: colorSchemeVariant), for: .highlighted)
        rejectImageButton.setBackgroundImageColor(UIColor.from(scheme: .secondaryAction, variant: colorSchemeVariant), for: .normal)
        rejectImageButton.setBackgroundImageColor(UIColor.from(scheme: .secondaryActionDimmed, variant: colorSchemeVariant), for: .highlighted)
    }

    
    @objc func createVideoPanel() {
        playerViewController = AVPlayerViewController()
        
        guard let videoURL = videoURL,
            let playerViewController = playerViewController else { return }
        
        playerViewController.player = AVPlayer(url: videoURL)
        playerViewController.player?.play()
        playerViewController.showsPlaybackControls = true
        playerViewController.view.backgroundColor = UIColor.from(scheme: .textBackground)
        
        view.addSubview(playerViewController.view)
    }

    /// open canvas screen if the image is sketchable(e.g. not an animated GIF)
    @objc(openSketchInEditMode:)
    func openSketch(in editMode: CanvasViewControllerEditMode) {
        guard let image = image as? UIImage else {
            return
        }

        let canvasViewController = CanvasViewController()
        canvasViewController.sketchImage = image
        canvasViewController.delegate = self
        canvasViewController.title = previewTitle
        canvasViewController.select(editMode: editMode, animated: false)

        let navigationController = canvasViewController.wrapInNavigationController()
        navigationController.modalTransitionStyle = .crossDissolve

        present(navigationController, animated: true)
    }
    
    @objc
    var imageToolbarFitsInsideImage: Bool {
        return image?.size.width > 192 && image?.size.height > 96
    }
    
    // MARK: - View Creation
    @objc
    func createPreviewPanel() {
        let imagePreviewView = FLAnimatedImageView()
        imagePreviewView.contentMode = .scaleAspectFit
        imagePreviewView.isUserInteractionEnabled = true
        view.addSubview(imagePreviewView)
        
        imagePreviewView.setMediaAsset(image)
        
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
}

extension ConfirmAssetViewController: CanvasViewControllerDelegate {
    func canvasViewController(_ canvasViewController: CanvasViewController, didExportImage image: UIImage) {
        onConfirm?(image)
    }
}
