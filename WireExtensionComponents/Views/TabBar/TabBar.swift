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


import Cartography


@objc
public enum TabBarStyle : UInt {
    case `default`, light, dark, colored
}


public protocol TabBarDelegate : class {
    
    func didSelectIndex(_ index: Int)
    
}

@objc
open class TabBar: UIView {
    
    open fileprivate(set) var style : TabBarStyle
    open fileprivate(set) var items : [UITabBarItem] = []
    open fileprivate(set) var selectedIndex : Int {
        didSet {
            updateArrowPosition()
            updateButtonSelection()
        }
    }
    open weak var delegate : TabBarDelegate?
    
    fileprivate var selectedButton : UIButton {
        get {
            return self.buttonRow.subviews[selectedIndex] as! UIButton
        }
    }
    
    fileprivate let buttonRow : UIView
    fileprivate let leftLineView : UIView
    fileprivate let rightLineView : UIView
    fileprivate let arrowView : UIImageView
    fileprivate var arrowPosition : NSLayoutConstraint! = nil
    
    required public init(items: [UITabBarItem], style: TabBarStyle, selectedIndex: Int = 0) {
        
        assert(items.count > 0, "TabBar must be initialized with at least one item")
        
        self.items = items
        self.selectedIndex = selectedIndex
        self.leftLineView = UIView()
        self.rightLineView = UIView()
        self.arrowView = UIImageView()
        self.buttonRow = UIView()
        self.style = style
        
        super.init(frame: CGRect.zero)
        
        setupViews()
        createConstraints()
        updateButtonSelection()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        for button in items.map(self.itemButton) {
            self.buttonRow.addSubview(button)
        }
        
        let lineColor = (self.style == TabBarStyle.colored) ? UIColor.white : ColorScheme.default().color(withName: ColorSchemeColorSeparator, variant: colorSchemeVariant())
        self.arrowView.image = WireStyleKit.imageOfTab(with: lineColor)
        self.leftLineView.backgroundColor = lineColor
        self.rightLineView.backgroundColor = lineColor
        
        self.addSubview(self.buttonRow)
        self.addSubview(self.leftLineView)
        self.addSubview(self.rightLineView)
        self.addSubview(self.arrowView)
    }
    
    fileprivate func createConstraints() {
        
        constrain(buttonRow.subviews.first!) { firstButton in
            firstButton.leading == firstButton.superview!.leading
        }
        
        constrain(buttonRow.subviews.last!) { lastButton in
            lastButton.trailing == lastButton.superview!.trailing
        }
        
        for button in buttonRow.subviews {
            constrain(button) { button in
                button.top == button.superview!.top
                button.bottom == button.superview!.bottom
            }
        }
        
        var previous = buttonRow.subviews.first!
        for current in buttonRow.subviews.dropFirst() {
            constrain(previous, current) { previous, current in
                previous.trailing == current.leading
                previous.width == current.width
            }
            previous = current
        }
        
        constrain(self.buttonRow) { buttonRow in
            buttonRow.top == buttonRow.superview!.top
            buttonRow.left >= buttonRow.superview!.left
            buttonRow.right <= buttonRow.superview!.right
            buttonRow.centerX == buttonRow.superview!.centerX
            buttonRow.height == 40
            buttonRow.width == 375 ~ 750.0
        }
        
        constrain(self.leftLineView, self.buttonRow, self.arrowView) { leftLineView, buttonRow, arrowView in
            leftLineView.height == 1
            leftLineView.top == buttonRow.bottom
            leftLineView.left == leftLineView.superview!.left
            leftLineView.right == arrowView.left
            leftLineView.bottom == leftLineView.superview!.bottom
        }
        
        constrain(self.rightLineView, self.buttonRow, self.arrowView) { rightLineView, buttonRow, arrowView in
            rightLineView.height == 1
            rightLineView.top == buttonRow.bottom
            rightLineView.left == arrowView.right
            rightLineView.right == rightLineView.superview!.right
            rightLineView.bottom == rightLineView.superview!.bottom
        }
        
        constrain(self.arrowView, self.selectedButton) { arrowView, selectedButton in
            arrowView.bottom == arrowView.superview!.bottom
            self.arrowPosition = arrowView.centerX == selectedButton.centerX
        }
    }
    
    fileprivate func updateButtonSelection() {
        for view in self.buttonRow.subviews {
            if let button = view as? Button {
                button.isSelected = false
            }
        }
        
        self.selectedButton.isSelected = true
    }
    
    fileprivate func updateArrowPosition() {
        self.removeConstraint(self.arrowPosition)
        
        constrain(self.arrowView, self.selectedButton) { arrowView, selectedButton in
            self.arrowPosition = arrowView.centerX == selectedButton.centerX
        }
    }
    
    fileprivate func itemButton (_ item: UITabBarItem) -> Button {
        let button = Button.init(type: .custom)
        button.textTransform = .upper
        button.setTitle(item.title, for: .normal)
        button.addTarget(self, action: #selector(TabBar.itemSelected(_:)), for: .touchUpInside)
        button.cas_styleClass = styleClass()
        return button
    }
    
    func setSelectedIndex( _ index: Int, animated: Bool) {
        if (animated) {
            UIView.animate(withDuration: 0.35, animations: {
                self.selectedIndex = index
                self.layoutIfNeeded()
            }) 
        } else {
            self.selectedIndex = index
            self.layoutIfNeeded()
        }
    }
    
    /// MARK - Styling
    
    fileprivate func styleClass() -> String {
        switch (self.style) {
        case .default:
            return "tab"
        case .light:
            return "tab-light"
        case .dark:
            return "tab-dark"
        case .colored:
            return "tab-monochrome"
        }
    }
    
    fileprivate func colorSchemeVariant() -> ColorSchemeVariant {
        switch (self.style) {
        case .light:
            return .light
        case .dark:
            return .dark
        default:
            return ColorScheme.default().variant
        }
    }
    
    /// MARK - Actions
    
    func itemSelected(_ sender: AnyObject) {
        guard
            let button = sender as? UIButton,
            let selectedIndex =  self.buttonRow.subviews.index(of: button)
        else {
            return
        }
        
        self.delegate?.didSelectIndex(selectedIndex)
        setSelectedIndex(selectedIndex, animated: true)
    }
}
