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
    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: AccentColor)
    func colorPickerWantsToDismiss(_ colotPicker: ColorPickerController)
}

class ColorPickerController: UIViewController {
    let tableView = UITableView()

    static fileprivate let rowHeight: CGFloat = 56

    fileprivate let colors: [AccentColor]
    fileprivate var selectedColor: AccentColor?
    fileprivate var delegate: ColorPickerControllerDelegate?

    init(colors: [AccentColor]) {
        self.colors = colors
        super.init(nibName: nil, bundle: nil)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    private func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(tableView)

        tableView.register(PickerCell.self, forCellReuseIdentifier: PickerCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        self.navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }

    private func createConstraints() {
        [tableView].prepareForLayout()

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.heightAnchor.constraint(equalToConstant: Self.rowHeight * CGFloat(colors.count)),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    fileprivate class PickerCell: UITableViewCell {
        fileprivate let checkmarkView = UIImageView()
        fileprivate let colorView = UIView()
        fileprivate let colorNameLabel: UILabel = {
            let label = UILabel()
            label.font = .normalLightFont
            label.textColor = SemanticColors.Label.textDefault
            return label
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupViews()
            createConstraints()
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var color: AccentColor? {
            didSet {
                if let color = color {
                    colorView.backgroundColor = UIColor(for: color)
                }
            }
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            checkmarkView.isHidden = !selected
            colorNameLabel.font = selected ? .normalSemiboldFont : .normalLightFont
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            colorView.backgroundColor = UIColor.clear
            checkmarkView.isHidden = true
        }

        private func setupViews() {
            selectionStyle = .none

            [colorView, checkmarkView, colorNameLabel].forEach {
                            contentView.addSubview($0)
            }

            backgroundColor = SemanticColors.View.backgroundUserCell
            addBorder(for: .bottom)
            colorView.layer.cornerRadius = 14
            checkmarkView.setTemplateIcon(.checkmark, size: .small)
            checkmarkView.tintColor = SemanticColors.Label.textDefault
            checkmarkView.isHidden = true
        }

        private func createConstraints() {
            [checkmarkView, colorView, colorNameLabel].prepareForLayout()
            NSLayoutConstraint.activate([
                colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                colorView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
                colorView.heightAnchor.constraint(equalToConstant: 28),
                colorView.widthAnchor.constraint(equalToConstant: 28),

                colorNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                colorNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 64),

                checkmarkView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
                checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
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

        cell.color = colors[indexPath.row]
        cell.colorNameLabel.text = colors[indexPath.row].name
        cell.isSelected = cell.color == selectedColor
        if cell.isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.colorPicker(self, didSelectColor: colors[indexPath.row])
        selectedColor = colors[indexPath.row]
    }
}

final class AccentColorPickerController: ColorPickerController {
    fileprivate let allAccentColors: [AccentColor]

    init() {
        allAccentColors = AccentColor.allSelectable()

        super.init(colors: allAccentColors)

        setupControllerTitle()

        if let accentColor = AccentColor(ZMAccentColor: ZMUser.selfUser().accentColorValue), let currentColorIndex = allAccentColors.firstIndex(of: accentColor) {
            selectedColor = colors[currentColorIndex]
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

    private func setupControllerTitle() {
        navigationItem.setupNavigationBarTitle(title: L10n.Localizable.Self.Settings.AccountPictureGroup.color.capitalized)
    }
}

extension AccentColorPickerController: ColorPickerControllerDelegate {
    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: AccentColor) {
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
