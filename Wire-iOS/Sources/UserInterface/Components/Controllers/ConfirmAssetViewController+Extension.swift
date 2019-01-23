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

extension ConfirmAssetViewController {
    @objc func setupStyle() {
        view.backgroundColor = UIColor.from(scheme: .background)
        imageToolbarSeparatorView?.backgroundColor = UIColor.from(scheme: .separator)
        topPanel?.backgroundColor = UIColor.from(scheme: .background)

        titleLabel?.font = UIFont.mediumSemiboldFont
        titleLabel?.textColor = UIColor.from(scheme: .textForeground)

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

}

extension ConfirmAssetViewController: CanvasViewControllerDelegate {
    func canvasViewController(_ canvasViewController: CanvasViewController, didExportImage image: UIImage) {
        onConfirm?(image)
    }
}
