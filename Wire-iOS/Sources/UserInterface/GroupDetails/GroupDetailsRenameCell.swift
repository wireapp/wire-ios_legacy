//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class GroupDetailsRenameCell : UICollectionViewCell {
 
    let accessoryIconView = UIImageView()
    let titleTextField = SimpleTextField()
    var contentStackView: UIStackView!
    
    var variant : ColorSchemeVariant = ColorScheme.default().variant {
        didSet {
            guard oldValue != variant else { return }
            configureColors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    fileprivate func setup() {
        
        accessoryIconView.image = UIImage(for: .pencil, iconSize: .like, color: .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: variant))
        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .scaleAspectFit
        accessoryIconView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        accessoryIconView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.font = FontSpec.init(.normal, .light).font!
        titleTextField.returnKeyType = .done
        titleTextField.backgroundColor = .clear

        contentStackView = UIStackView(arrangedSubviews: [titleTextField, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        
        configureColors()
    }
    
    private func configureColors() {
        backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: variant)
        accessoryIconView.image = UIImage(for: .pencil, iconSize: .tiny, color: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: variant))
        titleTextField.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: variant)
    }
    
}
