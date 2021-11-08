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

import Foundation
import UIKit
import WireSyncEngine
import Cartography
import WireCommonComponents

protocol ColorPickerControllerDelegate {
    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: UIColor)
    func colorPickerWantsToDismiss(_ colotPicker: ColorPickerController)
}

class ColorPickerController: UIViewController {
    let overlayView = UIView()
    let contentView = UIView()
    let tableView = UITableView()
    let headerView = UIView()
    let titleLabel = UILabel()
    let closeButton = IconButton()

    static fileprivate let rowHeight: CGFloat = 44

    let colors: [UIColor]
    var currentColor: UIColor?
    var delegate: ColorPickerControllerDelegate?

    init(colors: [UIColor]) {
        self.colors = colors
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(contentView)

        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.white

        closeButton.setIcon(.cross, size: .tiny, for: [])
        closeButton.addTarget(self, action: #selector(ColorPickerController.didPressDismiss(_:)), for: .touchUpInside)
        closeButton.setIconColor(UIColor.darkGray, for: .normal)

        titleLabel.font = FontSpec(.small, .light).font!

        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        contentView.addSubview(tableView)
        contentView.addSubview(headerView)

        constrain(contentView, headerView, titleLabel, closeButton) { contentView, headerView, titleLabel, closeButton in
            headerView.left == contentView.left
            headerView.top == contentView.top
            headerView.right == contentView.right
            headerView.height == 44

            titleLabel.center == headerView.center
            titleLabel.left >= headerView.left
            titleLabel.right <= closeButton.left

            closeButton.centerY == headerView.centerY
            closeButton.right == headerView.right
            closeButton.height == headerView.height
            closeButton.width == closeButton.height
        }

        constrain(contentView, tableView, headerView) { contentView, tableView, headerView in
            tableView.left == contentView.left
            tableView.bottom == contentView.bottom
            tableView.right == contentView.right

            tableView.top == headerView.bottom
        }

        constrain(view, contentView, headerView) { view, contentView, headerView in
            contentView.center == view.center
            contentView.width == 300
            contentView.height == headerView.height + type(of: self).rowHeight * CGFloat(colors.count)
        }

        tableView.register(PickerCell.self, forCellReuseIdentifier: PickerCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    fileprivate class PickerCell: UITableViewCell {
        fileprivate let checkmarkView = UIImageView()
        fileprivate let colorView = UIView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none

            contentView.addSubview(colorView)
            contentView.addSubview(checkmarkView)

            constrain(contentView, checkmarkView, colorView) { contentView, checkmarkView, colorView in
                colorView.edges == contentView.edges
                checkmarkView.center == contentView.center
            }

            checkmarkView.setIcon(.checkmark, size: .small, color: UIColor.white)
            checkmarkView.isHidden = true
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var color: UIColor? {
            didSet {
                colorView.backgroundColor = color
            }
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            checkmarkView.isHidden = !selected
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            colorView.backgroundColor = UIColor.clear
            checkmarkView.isHidden = true
        }

    }

    @objc func didPressDismiss(_ sender: AnyObject?) {
        delegate?.colorPickerWantsToDismiss(self)
    }
}

extension ColorPickerController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return type(of: self).rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: PickerCell.reuseIdentifier) as? PickerCell else {
            fatal("Cannot create cell")
        }

        cell.color = colors[(indexPath as NSIndexPath).row]
        cell.isSelected = cell.color == currentColor
        if cell.isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.colorPicker(self, didSelectColor: colors[(indexPath as NSIndexPath).row])
        currentColor = colors[(indexPath as NSIndexPath).row]
    }
}

final class AccentColorPickerController: ColorPickerController {
    fileprivate let allAccentColors: [AccentColor]

    init() {
        allAccentColors = AccentColor.allSelectable()

        super.init(colors: allAccentColors.map { UIColor(for: $0) })
        title = "settings.account_picture_group.color".localized(uppercased: true)

        if let accentColor = AccentColor(ZMAccentColor: ZMUser.selfUser().accentColorValue), let currentColorIndex = allAccentColors.firstIndex(of: accentColor) {
            currentColor = colors[currentColorIndex]
        }
        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isScrollEnabled = false
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccentColorPickerController: ColorPickerControllerDelegate {
    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: UIColor) {
        guard let colorIndex = colors.firstIndex(of: color) else {
            return
        }

        ZMUserSession.shared()?.perform {
            ZMUser.selfUser().accentColorValue = self.allAccentColors[colorIndex].zmAccentColor
        }
    }

    func colorPickerWantsToDismiss(_ colotPicker: ColorPickerController) {
        dismiss(animated: true, completion: .none)
    }
}
