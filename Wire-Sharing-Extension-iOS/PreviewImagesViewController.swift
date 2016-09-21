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

class PreviewImagesViewController: UIViewController, UIScrollViewDelegate {
    
    /// MARK: - Module interface
    
    internal var numberOfPreviewImages: Int = 0 {
        didSet {
            self.setupPreviewImageViewsForPreviewCount(numberOfPreviewImages)
            self.previewImagesPageControl.numberOfPages = numberOfPreviewImages
            self.previewImagesPageControl.currentPage = 0
        }
    }
    
    internal func setImage(_ image: UIImage?, forPreviewAtIndex index: Int) {
        self.previewImageViews[index].image = image
    }
    
    /// MARK: - IBOutlets
    
    @IBOutlet fileprivate weak var previewImagesScrollView: UIScrollView!
    @IBOutlet fileprivate weak var previewImagesPageControl: UIPageControl!
    
    fileprivate var previewImageViews = Array<UIImageView>()

    /// MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Layout
    
    internal var previewImageSize: CGFloat {
        get {
            return 70
        }
    }
    
    fileprivate func rectForPreviewImageAtIndex(_ index: Int) -> CGRect {
        let offset: CGFloat = 2
        let imageSize = self.previewImageSize
        let offsetedImageSize: CGFloat = imageSize - 2.0 * offset
        return CGRect(x: offset + CGFloat(index) * imageSize, y: offset, width: offsetedImageSize, height: offsetedImageSize)
    }
    
    fileprivate func setupPreviewImageViewsForPreviewCount(_ count:Int) {
        for view in self.previewImageViews {
            view.removeFromSuperview()
        }
        self.previewImageViews.removeAll(keepingCapacity: true)
        
        let imageSize = self.previewImageSize
        self.previewImagesScrollView.contentSize = CGSize(width: imageSize * CGFloat(count), height: imageSize)
        for i in 0 ..< count {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = true
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            self.previewImagesScrollView.addSubview(imageView)
            self.previewImageViews.append(imageView)
            imageView.frame = self.rectForPreviewImageAtIndex(i)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func pageControllPressed(_ sender: AnyObject) {
        let index = self.previewImagesPageControl.currentPage
        self.previewImagesScrollView.scrollRectToVisible(self.rectForPreviewImageAtIndex(index), animated: true)
    }
    
    @IBAction func tapToScroll(_ sender: AnyObject) {
        let newPage = (self.previewImagesPageControl.currentPage + 1) % self.numberOfPreviewImages
        self.previewImagesScrollView.scrollRectToVisible(self.rectForPreviewImageAtIndex(newPage),
            animated: false)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == self.previewImagesScrollView) {
            // + 0.5 makes page to be changed on the middle of transition
            let numberOfPage = Int(CGFloat(self.previewImageViews.count) * (scrollView.contentOffset.x / scrollView.contentSize.width) + 0.5)
            self.previewImagesPageControl.currentPage = numberOfPage
        }
    }

}
