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

        [contentView, headerView, titleLabel, closeButton, tableView].prepareForLayout()

        NSLayoutConstraint.activate([
          headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
          headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
          headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
          headerView.heightAnchor.constraint(equalToConstant: Self.rowHeight),

          titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
          titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
          titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor),
          titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor),

          closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
          closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
          closeButton.heightAnchor.constraint(equalTo: headerView.heightAnchor),
          closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),

          tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
          tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

          tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),

          contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
          contentView.widthAnchor.constraint(equalToConstant: 300),
          contentView.heightAnchor.constraint(equalTo: headerView.heightAnchor, constant: Self.rowHeight * CGFloat(colors.count))
        ])

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

            [checkmarkView, colorView].prepareForLayout()
            NSLayoutConstraint.activate([
              colorView.topAnchor.constraint(equalTo: contentView.topAnchor),
              colorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
              colorView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
              colorView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
              checkmarkView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
              checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])

            checkmarkView.setIcon(.checkmark, size: .small, color: UIColor.white)
            checkmarkView.isHidden = true
        }

        @available(*, unavailable)
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

    @objc
    private func didPressDismiss(_ sender: AnyObject?) {
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

        title = L10n.Localizable.Self.Settings.AccountPictureGroup.color.uppercased()

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
