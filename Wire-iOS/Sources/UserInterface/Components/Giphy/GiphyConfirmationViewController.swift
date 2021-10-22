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

import UIKit
import Cartography
import Ziphy
import FLAnimatedImage
import WireCommonComponents

protocol GiphyConfirmationViewControllerDelegate {

    func giphyConfirmationViewController(_ giphyConfirmationViewController: GiphyConfirmationViewController, didConfirmImageData imageData: Data)

}

final class GiphyConfirmationViewController: UIViewController {

    var imagePreview = FLAnimatedImageView()
    var acceptButton = Button(style: .full)
    var cancelButton = Button(style: .empty)
    var buttonContainer = UIView()
    var delegate: GiphyConfirmationViewControllerDelegate?
    let searchResultController: ZiphySearchResultsController?
    let ziph: Ziph?
    var imageData: Data?

    /// init method with optional arguments for remove dependency for testing
    ///
    /// - Parameters:
    ///   - ziph: provide nil for testing only
    ///   - previewImage: image for preview
    ///   - searchResultController: provide nil for testing only
    init(withZiph ziph: Ziph?, previewImage: FLAnimatedImage?, searchResultController: ZiphySearchResultsController?) {
        self.ziph = ziph
        self.searchResultController = searchResultController

        super.init(nibName: nil, bundle: nil)

        if let previewImage = previewImage {
            imagePreview.animatedImage = previewImage
        }

        let closeImage = StyleKitIcon.cross.makeImage(size: .tiny, color: .black)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector
            (GiphySearchViewController.onDismiss))

        view.backgroundColor = .from(scheme: .background)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        extendedLayoutIncludesOpaqueBars = true

        let titleLabel = UILabel()
        titleLabel.font = FontSpec(.small, .semibold).font!
        titleLabel.textColor = UIColor.from(scheme: .textForeground)
        titleLabel.text = title?.localizedUppercase
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        view.backgroundColor = .black
        acceptButton.isEnabled = false
        acceptButton.setTitle("giphy.confirm".localized, for: .normal)
        acceptButton.addTarget(self, action: #selector(GiphyConfirmationViewController.onAccept), for: .touchUpInside)
        cancelButton.setTitle("giphy.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(GiphyConfirmationViewController.onCancel), for: .touchUpInside)

        imagePreview.contentMode = .scaleAspectFit

        view.addSubview(imagePreview)
        view.addSubview(buttonContainer)

        [cancelButton, acceptButton].forEach(buttonContainer.addSubview)

        configureConstraints()
        fetchImage()
    }

    func fetchImage() {
        guard let ziph = ziph, let searchResultController = searchResultController else { return }

        searchResultController.fetchImageData(for: ziph, imageType: .downsized) { [weak self] result in
            guard case let .success(imageData) = result else {
                return
            }

            self?.imagePreview.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
            self?.imageData = imageData
            self?.acceptButton.isEnabled = true
        }
    }

    @objc func onDismiss() {
        dismiss(animated: true, completion: nil)
    }

    @objc func onCancel() {
        _ = navigationController?.popViewController(animated: true)
    }

    @objc func onAccept() {
        if let imageData = imageData {
            delegate?.giphyConfirmationViewController(self, didConfirmImageData: imageData)
        }
    }

    func configureConstraints() {

        imagePreview.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imagePreview.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            imagePreview.topAnchor.constraint(equalTo: safeTopAnchor),
            imagePreview.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor)
        ])

        constrain(buttonContainer, cancelButton, acceptButton) { container, leftButton, rightButton in
            leftButton.height == 40
            leftButton.width >= 100
            leftButton.left == container.left
            leftButton.top == container.top
            leftButton.bottom == container.bottom

            rightButton.height == 40
            rightButton.right == container.right
            rightButton.top == container.top
            rightButton.bottom == container.bottom

            leftButton.width == rightButton.width
            leftButton.right == rightButton.left - 16
        }

        constrain(view, buttonContainer) { container, buttonContainer in
            buttonContainer.left >= container.left + 32
            buttonContainer.right <= container.right - 32
            buttonContainer.bottom == container.bottom - 32
            buttonContainer.width == 476 ~ 700.0
            buttonContainer.centerX == container.centerX
        }
    }
}
