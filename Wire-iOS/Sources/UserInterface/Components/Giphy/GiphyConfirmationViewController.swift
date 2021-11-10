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
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: closeImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(GiphySearchViewController.onDismiss))

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

    private func configureConstraints() {

        let widthConstraint = buttonContainer.widthAnchor.constraint(equalToConstant: 476)

        widthConstraint.priority = .defaultHigh

        [imagePreview, buttonContainer, cancelButton, acceptButton].prepareForLayout()

        NSLayoutConstraint.activate([
            imagePreview.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            imagePreview.topAnchor.constraint(equalTo: safeTopAnchor),
            imagePreview.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),

            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            cancelButton.leftAnchor.constraint(equalTo: buttonContainer.leftAnchor),
            cancelButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            acceptButton.heightAnchor.constraint(equalToConstant: 40),
            acceptButton.rightAnchor.constraint(equalTo: buttonContainer.rightAnchor),
            acceptButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            acceptButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            cancelButton.widthAnchor.constraint(equalTo: acceptButton.widthAnchor),
            cancelButton.rightAnchor.constraint(equalTo: acceptButton.leftAnchor, constant: -16),

            buttonContainer.leftAnchor.constraint(greaterThanOrEqualTo: buttonContainer.leftAnchor, constant: 32),
            buttonContainer.rightAnchor.constraint(lessThanOrEqualTo: buttonContainer.rightAnchor, constant: -32),
            buttonContainer.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: -32),
            widthConstraint,
            buttonContainer.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor)
        ])
    }
}
