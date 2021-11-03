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

protocol GiphySearchViewControllerDelegate: class {
    func giphySearchViewController(_ giphySearchViewController: GiphySearchViewController, didSelectImageData imageData: Data, searchTerm: String)
}

final class GiphySearchViewController: VerticalColumnCollectionViewController {

    weak var delegate: GiphySearchViewControllerDelegate?

    let searchResultsController: ZiphySearchResultsController
    let searchBar: UISearchBar = UISearchBar()
    let noResultsLabel = UILabel()
    let conversation: ZMConversation

    var ziphs: [Ziph] = []
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

        title = ""
        performSearch()
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
    }

    private func setupCollectionView() {
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.accessibilityIdentifier = "giphyCollectionView"
        collectionView?.register(GiphyCollectionViewCell.self, forCellWithReuseIdentifier: GiphyCollectionViewCell.CellIdentifier)
        let offset = navigationController?.navigationBar.frame.maxY ?? 0
        edgesForExtendedLayout = []
        collectionView.contentInset = UIEdgeInsets(top: offset,
                                                   left: 0,
                                                   bottom: 0,
                                                   right: 0)
    }

    private func setupNavigationItem() {
        searchBar.text = searchTerm
        searchBar.delegate = self
        searchBar.tintColor = .accent()
        searchBar.placeholder = "giphy.search_placeholder".localized
        searchBar.barStyle = ColorScheme.default.variant == .dark ? .black : .default
        searchBar.searchBarStyle = .minimal

        let closeImage = StyleKitIcon.cross.makeImage(size: .tiny, color: .black)

        let closeItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(onDismiss))
        closeItem.accessibilityLabel = "general.close".localized

        navigationItem.rightBarButtonItem = closeItem
        self.navigationItem.titleView = searchBar
    }

    private func createConstraints() {
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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

        return navigationController
    }

    @objc func onDismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
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
                self?.setInitialSearchResults(ziphs)
            } else {
                self?.setInitialSearchResults([])
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

    private func setInitialSearchResults(_ results: [Ziph]) {
        self.ziphs = results
        self.collectionView?.reloadData()
        self.noResultsLabel.isHidden = self.ziphs.count > 0
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

// MARK: - UISearchBarDelegate

extension GiphySearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTerm = searchBar.text ?? ""
        performSearchAfter(delay: 0.3)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
