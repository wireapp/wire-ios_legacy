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
import zmessaging
import Cartography
import Classy

public protocol ColorPickerControllerDelegate {
    func colorPicker(colorPicker: ColorPickerController, didSelectColor color: UIColor)
    func colorPickerWantsToDismiss(colotPicker: ColorPickerController)
}

@objc public class ColorPickerController: UIViewController {
    public let overlayView = UIView()
    public let contentView = UIView()
    public let tableView = UITableView()
    public let headerView = UIView()
    public let titleLabel = UILabel()
    public let closeButton = IconButton()

    static private let rowHeight: CGFloat = 44
    
    public let colors: [UIColor]
    public var currentColor: UIColor?
    public var delegate: ColorPickerControllerDelegate?
    
    public init(colors: [UIColor]) {
        self.colors = colors
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .Custom
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var title: String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.contentView)
        
        self.contentView.layer.cornerRadius = 10
        self.contentView.clipsToBounds = true
        self.contentView.backgroundColor = .whiteColor()
        
        self.closeButton.setIcon(.X, withSize: .Tiny, forState: .Normal)
        self.closeButton.addTarget(self, action: #selector(ColorPickerController.didPressDismiss(_:)), forControlEvents: .TouchUpInside)
        self.closeButton.setIconColor(.darkGrayColor(), forState: .Normal)
        
        self.titleLabel.font = UIFont(magicIdentifier: "style.text.small.font_spec_light")
        
        self.headerView.addSubview(self.titleLabel)
        self.headerView.addSubview(self.closeButton)
        
        self.contentView.addSubview(self.tableView)
        self.contentView.addSubview(self.headerView)
        
        constrain(self.contentView, self.headerView, self.titleLabel, self.closeButton) { contentView, headerView, titleLabel, closeButton in
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
        
        constrain(self.contentView, self.tableView, self.headerView) { contentView, tableView, headerView in
            tableView.left == contentView.left
            tableView.bottom == contentView.bottom
            tableView.right == contentView.right
            
            tableView.top == headerView.bottom
        }
        
        constrain(self.view, self.contentView, self.headerView) { view, contentView, headerView in
            contentView.center == view.center
            contentView.width == 300
            contentView.height == headerView.height + self.dynamicType.rowHeight * CGFloat(self.colors.count)
        }
        
        self.tableView.registerClass(PickerCell.self, forCellReuseIdentifier: PickerCell.reuseIdentifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .None
    }
    
    public override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private class PickerCell: UITableViewCell {
        private let checkmarkView = UIImageView()
        private let colorView = UIView()
        
        override var reuseIdentifier: String? {
            get {
                return self.dynamicType.reuseIdentifier
            }
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.selectionStyle = .None
            
            self.contentView.addSubview(self.colorView)
            self.contentView.addSubview(self.checkmarkView)
            
            constrain(self.contentView, self.checkmarkView, self.colorView) { contentView, checkmarkView, colorView in
                colorView.edges == contentView.edges
                checkmarkView.center == contentView.center
            }
            
            self.checkmarkView.image = UIImage(forIcon: .Checkmark, iconSize: .Small, color: .whiteColor())
            self.checkmarkView.hidden = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        static var reuseIdentifier: String {
            get {
                return self.description()
            }
        }
        
        var color: UIColor? {
            didSet {
                self.colorView.backgroundColor = color
            }
        }

        override func setSelected(selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            self.checkmarkView.hidden = !selected
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            self.colorView.backgroundColor = .clearColor()
            self.checkmarkView.hidden = true
        }
        
    }
    
    @objc public func didPressDismiss(sender: AnyObject?) {
        self.delegate?.colorPickerWantsToDismiss(self)
    }
}

extension ColorPickerController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.colors.count
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.dynamicType.rowHeight
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = self.tableView.dequeueReusableCellWithIdentifier(PickerCell.reuseIdentifier) as? PickerCell else {
            fatal("Cannot create cell")
        }
        
        cell.color = self.colors[indexPath.row]
        cell.selected = cell.color == self.currentColor
        if cell.selected {
            tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
        }
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.colorPicker(self, didSelectColor: self.colors[indexPath.row])
        self.currentColor = self.colors[indexPath.row]
    }
}



public class AccentColorPickerController: ColorPickerController {
    public init() {
        super.init(colors: ZMAccentColor.all().map { $0.color })
        self.title = "self.settings.account_picture_group.color".localized.uppercaseString
        if let currentColorIndex = ZMAccentColor.all().indexOf(ZMUser.selfUser().accentColorValue) {
            self.currentColor = self.colors[currentColorIndex]
        }
        self.delegate = self
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.scrollEnabled = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AccentColorPickerController: ColorPickerControllerDelegate {
    public func colorPicker(colorPicker: ColorPickerController, didSelectColor color: UIColor) {
        guard let colorIndex = self.colors.indexOf(color) else {
            return
        }
        
        ZMUserSession.sharedSession().performChanges { 
            ZMUser.selfUser().accentColorValue = ZMAccentColor.all()[colorIndex]
        }
    }

    public func colorPickerWantsToDismiss(colotPicker: ColorPickerController) {
        self.dismissViewControllerAnimated(true, completion: .None)
    }
}


