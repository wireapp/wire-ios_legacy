//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireSystem

protocol SketchColorPickerControllerDelegate: AnyObject {
    func sketchColorPickerController(_ controller: SketchColorPickerController, changedSelectedColor color: UIColor)
}

private let zmLog = ZMSLog(tag: "SketchColorPickerController")

/// The color picker for the sketching

final class SketchColorPickerController: UIViewController {

    /// Used only as fallback in case no brush width is set
    private let SketchColorPickerDefaultBrushWidth: CGFloat = 6

    weak var delegate: SketchColorPickerControllerDelegate?
    var sketchColors: [UIColor] = [] {
        didSet {
            if sketchColors == oldValue {
                return
            }

            resetColorToBrushWidthMapper()

            colorsCollectionView.reloadData()
            colorsCollectionView.selectItem(at: IndexPath(row: selectedColorIndex, section: 0), animated: false, scrollPosition: [])
        }
    }

    private var brushWidths: [CGFloat] = [6, 12, 18] {
        didSet {
            if brushWidths == oldValue {
                return
            }

            resetColorToBrushWidthMapper()
        }
    }

    var selectedColorIndex: Int = 0 {
        didSet {
            colorsCollectionView.selectItem(at: IndexPath(row: selectedColorIndex, section: 0), animated: false, scrollPosition: [])

            delegate?.sketchColorPickerController(self, changedSelectedColor: selectedColor)
        }
    }

    /// Read only: Use the selectedColorIndex to change the selected color
    private var selectedColor: UIColor {
        assert(sketchColors.indices.contains(selectedColorIndex), "Colors out of bounds")

        return sketchColors[selectedColorIndex]
    }

    private var colorToBrushWidthMapper: [UIColor: CGFloat]?
    lazy var colorsCollectionView: UICollectionView = {
        return UICollectionView(frame: .zero, collectionViewLayout: colorsCollectionViewLayout)
    }()

    private var colorsCollectionViewLayout: UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 44, height: 40)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        return flowLayout
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpColorsCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        colorsCollectionViewLayout.invalidateLayout()
    }

    private func resetColorToBrushWidthMapper() {
        let brushWidth = brushWidths.first ?? SketchColorPickerDefaultBrushWidth

        var colorToBrushWidthMapper: [UIColor: CGFloat] = [:]
        for color in sketchColors {
            colorToBrushWidthMapper[color] = brushWidth
        }

        self.colorToBrushWidthMapper = colorToBrushWidthMapper
        selectedColorIndex = 0
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.colorsCollectionViewLayout.invalidateLayout()
        })
    }

    /// Returns the current brush width for the given color
    func brushWidth(for color: UIColor) -> CGFloat {
        return colorToBrushWidthMapper?[color] ?? SketchColorPickerDefaultBrushWidth
    }

    private func bumpBrushWidth(for color: UIColor) -> CGFloat {
        let count = brushWidths.count
        guard let currentValue: CGFloat = colorToBrushWidthMapper?[color] else {
            return SketchColorPickerDefaultBrushWidth
        }

        var index: Int?
        index = brushWidths.firstIndex(of: currentValue) ?? NSNotFound

        let nextIndex = ((index ?? 0) + 1) % count
        let nextValue = brushWidths[nextIndex]
        colorToBrushWidthMapper?[color] = nextValue

        return nextValue
    }

    private func setUpColorsCollectionView() {
        colorsCollectionView.showsHorizontalScrollIndicator = false
        colorsCollectionView.backgroundColor = SemanticColors.View.backgroundDefaultWhite
        view.addSubview(colorsCollectionView)

        SketchColorCollectionViewCell.register(in: colorsCollectionView)

        colorsCollectionView.dataSource = self
        colorsCollectionView.delegate = self

        colorsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        colorsCollectionView.fitIn(view: view)
    }
}

extension SketchColorPickerController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorToBrushWidthMapper?.count ?? 0
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let color = sketchColors[indexPath.row]
        let brushWidth: CGFloat = colorToBrushWidthMapper?[color] ?? SketchColorPickerDefaultBrushWidth

        let cell = collectionView.dequeueReusableCell(ofType: SketchColorCollectionViewCell.self, for: indexPath)
        cell.sketchColor = color
        cell.brushWidth = brushWidth

        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = sketchColors[indexPath.row]
        if selectedColor == color {
            // The color is already selected -> Change the brush size for this color
            let brushWidth = bumpBrushWidth(for: color)
            let cell = collectionView.cellForItem(at: indexPath) as? SketchColorCollectionViewCell
            cell?.brushWidth = brushWidth
        }

        selectedColorIndex = sketchColors.firstIndex(of: color) ?? NSNotFound
    }

    private var contentWidth: CGFloat {
        return numberOfItems * colorsCollectionViewLayout.itemSize.width + (max(numberOfItems - 1, 0)) * colorsCollectionViewLayout.minimumInteritemSpacing
    }

    private var frameWidth: CGFloat {
        return colorsCollectionView.frame.size.width
    }

    private var numberOfItems: CGFloat {
        return CGFloat(sketchColors.count)
    }

    private var allItemsAreIncluded: Bool {
        return contentWidth < frameWidth
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if allItemsAreIncluded {
            // All items are included, just use the default item box
            return colorsCollectionViewLayout.itemSize
        }
        // Some items dont fit, so we increase the item box to make the last
        // item visible for the half of its width, to give the user a hint that
        // he can scroll
        let itemWidth: CGFloat = contentWidth / numberOfItems
        let numberOfItemsVisible: CGFloat = round(frameWidth / itemWidth)
        let leftOver = frameWidth - numberOfItemsVisible * itemWidth + itemWidth / 2.0
        return CGSize(width: colorsCollectionViewLayout.itemSize.width + (leftOver / numberOfItemsVisible), height: colorsCollectionViewLayout.itemSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        if allItemsAreIncluded {
            // Align content in center of frame
            let horizontalInset = frameWidth - contentWidth
            return UIEdgeInsets(top: 0, left: horizontalInset / 2, bottom: 0, right: horizontalInset / 2)
        }

        return .zero
    }
}
