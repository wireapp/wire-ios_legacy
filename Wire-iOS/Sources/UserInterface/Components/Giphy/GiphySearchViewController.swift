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

@objc protocol GiphySearchViewControllerDelegate: NSObjectProtocol {
    func giphySearchViewController(_ giphySearchViewController: GiphySearchViewController, didSelectImageData imageData: Data, searchTerm: String)
}

@objcMembers class GiphySearchViewController: VerticalColumnCollectionViewController {

    public weak var delegate: GiphySearchViewControllerDelegate?

    let searchResultsController: ZiphySearchResultsController
    let searchBar: UISearchBar = UISearchBar()
    let noResultsLabel = UILabel()
    let conversation: ZMConversation
    var searchTerm: String
    var pendingTimer: Timer?
    var pendingSearchtask: CancelableTask?
    var pendingFetchTask: CancelableTask?
    fileprivate var lastLayoutSize: CGSize = .zero

    fileprivate var ziphs: [Ziph] /*{
        didSet {
            self.collectionView?.reloadData()
            self.noResultsLabel.isHidden = self.ziphs.count > 0
        }
    }*/

    public init(withSearchTerm searchTerm: String, conversation: ZMConversation) {
        self.conversation = conversation
        self.searchTerm = searchTerm
        searchResultsController = ZiphySearchResultsController(client: .default, pageSize: 50, maxImageSize: 3)
        ziphs = []

        let columnCount = AdaptiveColumnCount(compact: 2, regular: 3, large: 4)
        super.init(interItemSpacing: 1, interColumnSpacing: 1, columnCount: columnCount)

        title = ""

        performSearch()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cleanUpPendingTask()
        cleanUpPendingTimer()
    }

    func cleanUpPendingTask() {
        pendingSearchtask?.cancel()
        pendingSearchtask = nil
    }

    func cleanUpPendingTimer() {
        pendingTimer?.invalidate()
        pendingTimer = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        extendedLayoutIncludesOpaqueBars = true

        noResultsLabel.text = "giphy.error.no_result".localized.uppercased()
        noResultsLabel.isHidden = true
        view.addSubview(noResultsLabel)

        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.accessibilityIdentifier = "giphyCollectionView"
        collectionView?.register(GiphyCollectionViewCell.self, forCellWithReuseIdentifier: GiphyCollectionViewCell.CellIdentifier)

        setupNavigationItem()
        createConstraints()
    }

    private func createConstraints() {
        constrain(view, noResultsLabel) { container, noResultsLabel in
            noResultsLabel.center == container.center
        }
    }

    private func setupNavigationItem() {
        searchBar.text = searchTerm
        searchBar.delegate = self
        searchBar.tintColor = .accent()
        searchBar.placeholder = "giphy.search_placeholder".localized
        searchBar.barStyle = ColorScheme.default.variant == .dark ? .black : .default
        searchBar.searchBarStyle = .minimal

        let closeImage = UIImage(for: .X, iconSize: .tiny, color: .black)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(GiphySearchViewController.onDismiss))

        self.navigationItem.titleView = searchBar
    }

    public func wrapInsideNavigationController() -> UINavigationController {
        let navigationController = GiphyNavigationController(rootViewController: self)

        var backButtonImage = UIImage(for: .backArrow, iconSize: .tiny, color: .black)
        backButtonImage = backButtonImage?.withInsets(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0), backgroundColor: .clear)
        backButtonImage = backButtonImage?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: -4, right: 0))
        navigationController.navigationBar.backIndicatorImage = backButtonImage
        navigationController.navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        navigationController.navigationBar.backItem?.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationController.navigationBar.tintColor = UIColor(scheme: .textForeground)
        navigationController.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: ColorScheme.default.variant)
        navigationController.navigationBar.barTintColor = UIColor(scheme: .background)
        navigationController.navigationBar.isTranslucent = false

        return navigationController
    }

    @objc func onDismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Search

    func performSearch() {
        cleanUpPendingTimer()

        if searchTerm.isEmpty {
            pendingSearchtask = searchResultsController.trending() { [weak self] result in
                if case let .success(ziphs) = result {
                    self?.setInitialSearchResults(ziphs)
                } else {
                    self?.setInitialSearchResults([])
                }
            }
        } else {
            pendingSearchtask = searchResultsController.search(withTerm: searchTerm) { [weak self] result in
                if case let .success(ziphs) = result {
                    self?.setInitialSearchResults(ziphs)
                } else {
                    self?.setInitialSearchResults([])
                }
            }
        }
    }

    func performSearchAfter(delay: TimeInterval) {
        cleanUpPendingTask()
        cleanUpPendingTimer()

        pendingTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.performSearch()
        }
    }

    func setInitialSearchResults(_ results: [Ziph]) {
        self.ziphs = results
        self.collectionView?.reloadData()
        self.noResultsLabel.isHidden = self.ziphs.count > 0
    }

    // MARK: - Pagination

    func fetchMoreResults() {
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

    func insertSearchResults(_ results: [Ziph]) {
        ziphs.append(contentsOf: results)

        let updatedIndices = ziphs.indices.suffix(results.count).map {
            IndexPath(item: $0, section: 0)
        }

        collectionView?.insertItems(at: updatedIndices)
    }

    // MARK: - Collection View

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.ziphs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiphyCollectionViewCell.CellIdentifier, for: indexPath) as! GiphyCollectionViewCell
        let ziph = ziphs[indexPath.row]

        guard let representation = ziph.images[.preview] else {
            return cell
        }

        cell.ziph = ziph
        cell.representation = representation
        cell.backgroundColor = UIColor(for: ZMUser.pickRandomAccentColor())
        cell.isAccessibilityElement = true
        cell.accessibilityTraits |= UIAccessibilityTraitImage
        cell.accessibilityLabel = ziph.title

        searchResultsController.fetchImageData(for: ziph, imageType: .preview) { result in
            guard case let .success(imageData) = result else {
                return
            }

            cell.imageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, sizeOfItemAt indexPath: IndexPath) -> CGSize {
        let ziph = self.ziphs[indexPath.row]

        guard let representation = ziph.images[.preview] else {
            return .zero
        }

        return CGSize(width: representation.width.rawValue, height: representation.height.rawValue)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ziph = self.ziphs[indexPath.row]
        var previewImage: FLAnimatedImage?

        if let cell = collectionView.cellForItem(at: indexPath) as? GiphyCollectionViewCell {
            previewImage = cell.imageView.animatedImage
        }

        pushConfirmationViewController(ziph: ziph, previewImage: previewImage)
    }

    @discardableResult
    func pushConfirmationViewController(ziph: Ziph?, previewImage: FLAnimatedImage?, animated: Bool = true) -> GiphyConfirmationViewController {
        let confirmationController = GiphyConfirmationViewController(withZiph: ziph, previewImage: previewImage, searchResultController: searchResultsController)
        confirmationController.title = conversation.displayName.uppercased()
        confirmationController.delegate = self
        navigationController?.pushViewController(confirmationController, animated: animated)

        return confirmationController
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height / 2 {
            fetchMoreResults()
        }

        searchBar.resignFirstResponder()
    }

}

extension GiphySearchViewController: GiphyConfirmationViewControllerDelegate {

    func giphyConfirmationViewController(_ giphyConfirmationViewController: GiphyConfirmationViewController, didConfirmImageData imageData: Data) {
        delegate?.giphySearchViewController(self, didSelectImageData: imageData, searchTerm: searchTerm)
    }

}

extension GiphySearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTerm = searchBar.text ?? ""
        performSearchAfter(delay: 0.3)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
