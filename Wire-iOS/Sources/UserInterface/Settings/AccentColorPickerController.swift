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
    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: AccentColorOption)
    func colorPickerWantsToDismiss(_ colotPicker: ColorPickerController)
}

class AccentColorOption: Equatable {
    static func == (lhs: AccentColorOption, rhs: AccentColorOption) -> Bool {
        return lhs.accentColor == rhs.accentColor
    }

    let accentColor: AccentColor
    let color: UIColor
    var colorName: String = "No Color Name"
    var isSelected: Bool = false

    init(accentColor: AccentColor) {
        self.accentColor = accentColor
        self.color = UIColor(for: self.accentColor)
        self.colorName = getColorName(accentColor: self.accentColor)
    }

    private func getColorName(accentColor: AccentColor) -> String {
        switch accentColor {
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        case .yellow:
            return "Yellow"
        case .red:
            return "Red"
        case .amber:
            return "Amber"
        case .petrol:
            return "Petrol"
        case .purple:
            return "Purple"
        }
    }
}

class ColorPickerController: UIViewController {
    let tableView = UITableView()

    static fileprivate let rowHeight: CGFloat = 56

    let colors: [AccentColorOption]
    var currentColor: UIColor?
    var delegate: ColorPickerControllerDelegate?

    init(colors: [AccentColorOption]) {
        self.colors = colors
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.Background.settingsView
        view.addSubview(tableView)

        [tableView].prepareForLayout()

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.heightAnchor.constraint(equalToConstant: Self.rowHeight * CGFloat(colors.count)),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.register(PickerCell.self, forCellReuseIdentifier: PickerCell.reuseIdentifier)
        tableView.backgroundColor = .red
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    fileprivate class PickerCell: UITableViewCell {
        fileprivate let checkmarkView = UIImageView()
        fileprivate let colorView = UIView()
        fileprivate let colorNameLabel: UILabel = {
            let label = UILabel()
            label.font = .normalLightFont
            label.textColor = SemanticColors.LabelsColor.textColorPickerCell
            return label
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none

            contentView.addSubview(colorView)
            contentView.addSubview(checkmarkView)
            contentView.addSubview(colorNameLabel)

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

            backgroundColor = SemanticColors.Background.settingsTableCell
            addBottomBorderWithInset(color: SemanticColors.Background.ColorPickerCellBorder)

            colorView.layer.cornerRadius = 14
            colorNameLabel.text = "Color Name"

            checkmarkView.tintColor = SemanticColors.LabelsColor.textColorPickerCell
            checkmarkView.setTemplateIcon(.checkmark, size: .small)
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
            // TODO: MAKE SURE THAT THIS IS CORRECT FONT!
            colorNameLabel.font = selected ? .normalSemiboldFont : .normalLightFont
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

        cell.color = colors[indexPath.row].color
        cell.colorNameLabel.text = colors[indexPath.row].colorName
        cell.isSelected = cell.color == currentColor
        if cell.isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.colorPicker(self, didSelectColor: colors[indexPath.row])
        currentColor = colors[indexPath.row].color
    }
}

final class AccentColorPickerController: ColorPickerController {
    fileprivate let allAccentColors: [AccentColor]

    init() {
        allAccentColors = AccentColor.allSelectable()

        super.init(colors: allAccentColors.map { AccentColorOption(accentColor: $0) })

        title = L10n.Localizable.Self.Settings.AccountPictureGroup.color

        if let accentColor = AccentColor(ZMAccentColor: ZMUser.selfUser().accentColorValue), let currentColorIndex = allAccentColors.firstIndex(of: accentColor) {
            currentColor = colors[currentColorIndex].color
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
    func colorPicker(_ colorPicker: ColorPickerController, didSelectColor color: AccentColorOption) {
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
