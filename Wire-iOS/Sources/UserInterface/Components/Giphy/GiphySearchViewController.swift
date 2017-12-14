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

@objc protocol GiphySearchViewControllerDelegate: NSObjectProtocol {

    func giphySearchViewController(_ giphySearchViewController: GiphySearchViewController, didSelectImageData imageData: Data, searchTerm: String)

}

class GiphyNavigationController: UINavigationController {

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default().variant == .dark ? .lightContent : .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}

class GiphyCollectionViewCell: UICollectionViewCell {

    static let CellIdentifier = "GiphyCollectionViewCell"

    let imageView = FLAnimatedImageView()
    var ziph: Ziph?
    var representation: ZiphyImageRep?

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)

        constrain(self.contentView, self.imageView) { contentView, imageView in
            imageView.edges == contentView.edges
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        self.imageView.animatedImage = nil
        self.ziph = nil
        self.representation = nil
        self.backgroundColor = nil
    }

}

class GiphySearchViewController: UICollectionViewController {

    public var delegate: GiphySearchViewControllerDelegate?

    let searchResultsController: ZiphySearchResultsController
    let masonrylayout: ARCollectionViewMasonryLayout
    let searchBar: UISearchBar = UISearchBar()
    let noResultsLabel = UILabel()
    let conversation: ZMConversation
    var searchTerm: String
    var pendingTimer: Timer?
    var pendingSearchtask: CancelableTask?
    var pendingFetchTask: CancelableTask?
    fileprivate var lastLayoutSize: CGSize = .zero

    public init(withSearchTerm searchTerm: String, conversation: ZMConversation) {
        self.conversation = conversation
        self.searchTerm = searchTerm
        searchResultsController = ZiphySearchResultsController(pageSize: 50, callbackQueue: DispatchQueue.main)
        searchResultsController.ziphyClient = ZiphyClient.wr_ziphyWithDefaultConfiguration()
        masonrylayout = ARCollectionViewMasonryLayout(direction: .vertical)

        super.init(collectionViewLayout: masonrylayout)

        title = ""

        performSearch()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        noResultsLabel.text = "giphy.error.no_result".localized.uppercased()
        noResultsLabel.isHidden = true
        view.addSubview(noResultsLabel)

        configureMasonryLayout(withSize: view.bounds.size)

        collectionView?.accessibilityIdentifier = "giphyCollectionView"
        collectionView?.register(GiphyCollectionViewCell.self, forCellWithReuseIdentifier: GiphyCollectionViewCell.CellIdentifier)

        setupNavigationItem()
        createConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.lastLayoutSize != self.view.bounds.size {
            self.lastLayoutSize = self.view.bounds.size
            flushLayout()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.flushLayout()
        })
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.flushLayout()
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
        searchBar.barStyle = ColorScheme.default().variant == .dark ? .black : .default
        searchBar.searchBarStyle = .minimal

        let closeImage = UIImage(for: .X, iconSize: .tiny, color: .black)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(GiphySearchViewController.onDismiss))

        self.navigationItem.titleView = searchBar//titleViewWrapper
    }

    private func flushLayout() {
        self.configureMasonryLayout(withSize: view.bounds.size)
        self.collectionView?.collectionViewLayout.invalidateLayout()

        self.navigationItem.titleView?.setNeedsLayout()
    }

    public func wrapInsideNavigationController() -> UINavigationController {
        let navigationController = GiphyNavigationController(rootViewController: self)

        var backButtonImage = UIImage(for: .backArrow, iconSize: .tiny, color: .black)
        backButtonImage = backButtonImage?.withInsets(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0), backgroundColor: .clear)
        backButtonImage = backButtonImage?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: -4, right: 0))
        navigationController.navigationBar.backIndicatorImage = backButtonImage
        navigationController.navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        navigationController.navigationBar.backItem?.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationController.navigationBar.tintColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        navigationController.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(magicIdentifier: "style.text.title.font_spec"), NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground)]
        navigationController.navigationBar.barTintColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        navigationController.navigationBar.isTranslucent = false

        return navigationController
    }

    func configureMasonryLayout(withSize size: CGSize) {
        masonrylayout.rank = UInt(ceilf(Float(size.width) / 256.0))
        masonrylayout.dimensionLength = view.bounds.width / CGFloat(masonrylayout.rank)
        masonrylayout.minimumLineSpacing = 1
        masonrylayout.itemMargins = CGSize(width: 1, height: 1)
    }

    func onDismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    func performSearch() {
        pendingTimer = nil

        if searchTerm.isEmpty {
            pendingSearchtask = searchResultsController.trending() { [weak self] (success, error) in
                self?.collectionView?.reloadData()
                self?.noResultsLabel.isHidden = self?.searchResultsController.results.count > 0
            }
        } else {
            pendingSearchtask = searchResultsController.search(withSearchTerm: searchTerm) { [weak self] (success, error) in
                self?.collectionView?.reloadData()
                self?.noResultsLabel.isHidden = self?.searchResultsController.results.count > 0
            }
        }
    }

    func fetchMoreResults() {
        if pendingFetchTask != nil {
            return
        }

        pendingFetchTask = searchResultsController.fetchMoreResults { [weak self] (success, error) in
            self?.collectionView?.reloadData()
            self?.pendingFetchTask = nil
        }
    }

    func performSearchAfter(delay: TimeInterval) {
        pendingSearchtask?.cancel()
        pendingSearchtask = nil
        pendingTimer?.invalidate()

        pendingTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(GiphySearchViewController.performSearch), userInfo: nil, repeats: false)
    }

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResultsController.results.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiphyCollectionViewCell.CellIdentifier, for: indexPath) as! GiphyCollectionViewCell
        let ziph = searchResultsController.results[indexPath.row]

        if let representation = ziph.ziphyImages[ZiphyClient.fromZiphyImageTypeToString(.fixedWidthDownsampled)] {
            cell.ziph = ziph
            cell.representation = representation
            cell.backgroundColor = UIColor(for: ZMUser.pickRandomAccentColor())

            searchResultsController.fetchImageData(forZiph: ziph, imageType: representation.imageType) { (imageData, imageRepresentation, error) in
                if cell.representation == imageRepresentation {
                    cell.imageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
                }
            }
        }

        if indexPath.row == searchResultsController.results.count / 2 {
            fetchMoreResults()
        }

        return cell

    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ziph = searchResultsController.results[indexPath.row]
        var previewImage: FLAnimatedImage?

        if let cell = collectionView.cellForItem(at: indexPath) as? GiphyCollectionViewCell {
            previewImage = cell.imageView.animatedImage
        }

        let confirmationController = GiphyConfirmationViewController(withZiph: ziph, previewImage: previewImage, searchResultController: searchResultsController)
        confirmationController.title = conversation.displayName.uppercased()
        confirmationController.delegate = self
        navigationController?.pushViewController(confirmationController, animated: true)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

extension GiphySearchViewController: ARCollectionViewMasonryLayoutDelegate {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: ARCollectionViewMasonryLayout, variableDimensionForItemAt indexPath: IndexPath) -> CGFloat {
        let ziph = searchResultsController.results[indexPath.row]

        guard let representation = ziph.ziphyImages[ZiphyClient.fromZiphyImageTypeToString(.fixedWidthDownsampled)] else {
            return 0
        }

        return CGFloat(representation.height)
    }

}

