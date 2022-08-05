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
import WireDataModel

protocol GiphySearchViewControllerDelegate: AnyObject {
    func giphySearchViewController(_ giphySearchViewController: GiphySearchViewController, didSelectImageData imageData: Data, searchTerm: String)
}

final class GiphySearchViewController: VerticalColumnCollectionViewController {

    weak var delegate: GiphySearchViewControllerDelegate?

    let searchResultsController: ZiphySearchResultsController
    let searchBar: TextSearchInputView = TextSearchInputView()
    let noResultsLabel = UILabel()
    let conversation: ZMConversation

    var ziphs: [Ziph] = [] {
        didSet {
            collectionView?.reloadData()
            noResultsLabel.isHidden = self.ziphs.count > 0
        }
    }

    var searchTerm: String
    var pendingTimer: Timer?
    var pendingSearchtask: CancelableTask?
    var pendingFetchTask: CancelableTask?

    // MARK: - Initialization

    convenience init(searchTerm: String, conversation: ZMConversation) {
        let searchResultsController = ZiphySearchResultsController(client: .default, pageSize: 50, maxImageSize: 3)
        self.init(searchTerm: searchTerm, conversation: conversation, searchResultsController: searchResultsController)
    }

    init(searchTerm: String, conversation: ZMConversation, searchResultsController: ZiphySearchResultsController) {
        self.conversation = conversation
        self.searchTerm = searchTerm
        self.searchResultsController = searchResultsController

        let columnCount = AdaptiveColumnCount(compact: 2, regular: 3, large: 4)
        super.init(interItemSpacing: 1, interColumnSpacing: 1, columnCount: columnCount)

        title = conversation.displayName.localizedUppercase
        performSearch()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        searchBar.iconView.setIcon(.search, size: .tiny, color: SemanticColors.SearchBar.backgroundButton)
        searchBar.clearButton.setIconColor(SemanticColors.SearchBar.backgroundButton, for: .normal)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cleanUpPendingTask()
        cleanUpPendingTimer()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    fileprivate func cleanUpPendingTask() {
        pendingSearchtask?.cancel()
        pendingSearchtask = nil
    }

    fileprivate func cleanUpPendingTimer() {
        pendingTimer?.invalidate()
        pendingTimer = nil
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNoResultLabel()
        setupCollectionView()
        setupNavigationItem()
        createConstraints()
        applyStyle()
    }

    private func setupNoResultLabel() {
        extendedLayoutIncludesOpaqueBars = true

        noResultsLabel.text = "giphy.error.no_result".localized(uppercased: true)
        noResultsLabel.isHidden = true
        view.addSubview(noResultsLabel)
        view.addSubview(searchBar)
    }

    private func setupCollectionView() {
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.accessibilityIdentifier = "giphyCollectionView"
        collectionView?.register(GiphyCollectionViewCell.self, forCellWithReuseIdentifier: GiphyCollectionViewCell.CellIdentifier)
        edgesForExtendedLayout = []
    }

    private func setupNavigationItem() {
        searchBar.searchInput.text = searchTerm
        searchBar.placeholderString = "giphy.search_placeholder".localized(uppercased: true)
        searchBar.delegate = self
        let closeImage = StyleKitIcon.cross.makeImage(size: .tiny, color: .black)
        let closeItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(onDismiss))
        closeItem.accessibilityLabel = "general.close".localized

        navigationItem.rightBarButtonItem = closeItem
    }

    private func createConstraints() {
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            searchBar.topAnchor.constraint(equalTo: view.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 56),

            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func applyStyle() {
        collectionView?.backgroundColor = UIColor.from(scheme: .background)
        noResultsLabel.textColor = UIColor.from(scheme: .textPlaceholder)
        noResultsLabel.font = UIFont.smallLightFont
    }

    // MARK: - Presentation

    func wrapInsideNavigationController() -> UINavigationController {
        let navigationController = GiphyNavigationController(rootViewController: self)

        let backButtonImage = StyleKitIcon.backArrow.makeImage(size: .tiny, color: .black)
            .with(insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0), backgroundColor: .clear)?
            .withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: -4, right: 0))
        navigationController.navigationBar.backIndicatorImage = backButtonImage
        navigationController.navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        navigationController.navigationBar.backItem?.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationController.navigationBar.tintColor = UIColor.from(scheme: .textForeground)
        navigationController.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: ColorScheme.default.variant)
        navigationController.navigationBar.barTintColor = UIColor.from(scheme: .background)
        navigationController.navigationBar.isTranslucent = false

        if #available(iOS 15, *) {
            navigationController.view.backgroundColor = UIColor.from(scheme: .barBackground, variant: ColorScheme.default.variant)
        }

        return navigationController
    }

    @objc func onDismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Collection View

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.ziphs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiphyCollectionViewCell.CellIdentifier, for: indexPath) as! GiphyCollectionViewCell
        let ziph = ziphs[indexPath.item]

        guard let representation = ziph.images[.preview] else {
            return cell
        }

        cell.ziph = ziph
        cell.representation = representation
        cell.backgroundColor = UIColor(for: AccentColor.random)
        cell.isAccessibilityElement = true
        cell.accessibilityTraits.insert(.image)
        cell.accessibilityLabel = ziph.title

        searchResultsController.fetchImageData(for: ziph, imageType: .preview) { result in
            guard case let .success(imageData) = result else {
                return
            }

            guard cell.ziph?.identifier == ziph.identifier else {
                return
            }

            cell.imageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, sizeOfItemAt indexPath: IndexPath) -> CGSize {
        let ziph = self.ziphs[indexPath.item]

        guard let representation = ziph.previewImage else {
            return .zero
        }

        return CGSize(width: representation.width.rawValue, height: representation.height.rawValue)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ziph = self.ziphs[indexPath.item]
        var previewImage: FLAnimatedImage?

        if let cell = collectionView.cellForItem(at: indexPath) as? GiphyCollectionViewCell {
            previewImage = cell.imageView.animatedImage
        }

        pushConfirmationViewController(ziph: ziph, previewImage: previewImage)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height / 2 {
            fetchMoreResults()
        }

        searchBar.resignFirstResponder()
    }

}

// MARK: - Search

extension GiphySearchViewController {

    private func performSearch() {
        cleanUpPendingTimer()

        let callback: ZiphyListRequestCallback = { [weak self] result in
            if case let .success(ziphs) = result {
                self?.ziphs = ziphs
            } else {
                self?.ziphs = []
            }
        }

        if searchTerm.isEmpty {
            pendingSearchtask = searchResultsController.trending(callback)
        } else {
            pendingSearchtask = searchResultsController.search(withTerm: searchTerm, callback)
        }
    }

    func performSearchAfter(delay: TimeInterval) {
        cleanUpPendingTask()
        cleanUpPendingTimer()

        pendingTimer = .scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.performSearch()
        }
    }

}

// MARK: - Pagination

extension GiphySearchViewController {

    private func fetchMoreResults() {
        if pendingFetchTask != nil {
            return
        }

        pendingFetchTask = searchResultsController.fetchMoreResults { [weak self] result in
            if case let .success(ziphs) = result {
                self?.insertSearchResults(ziphs)
            }

            self?.pendingFetchTask = nil
        }
    }

    private func insertSearchResults(_ results: [Ziph]) {
        ziphs.append(contentsOf: results)

        let updatedIndices = ziphs.indices.suffix(results.count).map {
            IndexPath(item: $0, section: 0)
        }

        collectionView?.insertItems(at: updatedIndices)
    }

    @discardableResult
    func pushConfirmationViewController(ziph: Ziph?, previewImage: FLAnimatedImage?, animated: Bool = true) -> GiphyConfirmationViewController {
        let confirmationController = GiphyConfirmationViewController(withZiph: ziph, previewImage: previewImage, searchResultController: searchResultsController)
        confirmationController.title = conversation.displayName.localizedUppercase
        confirmationController.delegate = self
        navigationController?.pushViewController(confirmationController, animated: animated)

        return confirmationController
    }

}

// MARK: - GiphyConfirmationViewControllerDelegate

extension GiphySearchViewController: GiphyConfirmationViewControllerDelegate {

    func giphyConfirmationViewController(_ giphyConfirmationViewController: GiphyConfirmationViewController, didConfirmImageData imageData: Data) {
        delegate?.giphySearchViewController(self, didSelectImageData: imageData, searchTerm: searchTerm)
    }

}

// MARK: - TextSearchInputViewDelegate

extension GiphySearchViewController: TextSearchInputViewDelegate {

    func searchView(_ searchView: TextSearchInputView, didChangeQueryTo query: String) {

        searchTerm = searchBar.query
        performSearchAfter(delay: 0.3)
    }

    func searchViewShouldReturn(_ searchView: TextSearchInputView) -> Bool {
        return TextSearchQuery.isValid(query: searchBar.query)
    }

}
