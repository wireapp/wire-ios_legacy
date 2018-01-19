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


import MapKit
import Cartography
import AddressBook
import Classy

/// Displays the location message
public final class LocationMessageCell: ConversationCell {
    
    private let mapView = MKMapView()
    private let containerView = UIView()
    private let obfuscationView = ObfuscationView(icon: .locationPin)
    private let addressContainerView = UIView()
    private let addressLabel = UILabel()
    private var recognizer: UITapGestureRecognizer?
    private weak var locationAnnotation: MKPointAnnotation? = nil
    var labelFont: UIFont?
    var labelTextColor, containerColor: UIColor?
    var containerHeightConstraint: NSLayoutConstraint!
    
    public override required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 4
        containerView.clipsToBounds = true
        containerView.cas_styleClass = "container-view"
        CASStyler.default().styleItem(self)
        configureViews()
        createConstraints()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.mapType = .standard
        mapView.showsPointsOfInterest = true
        mapView.showsBuildings = true
        mapView.isUserInteractionEnabled = false
        
        recognizer = UITapGestureRecognizer(target: self, action: #selector(openInMaps))
        containerView.addGestureRecognizer(recognizer!)
        messageContentView.addSubview(containerView)
        [mapView, addressContainerView, obfuscationView].forEach(containerView.addSubview)
        addressContainerView.addSubview(addressLabel)
        obfuscationView.isHidden = true

        guard let font = labelFont, let color = labelTextColor, let containerColor = containerColor else { return }
        addressLabel.font = font
        addressLabel.textColor = color
        addressContainerView.backgroundColor = containerColor
    }
    
    private func createConstraints() {
        constrain(messageContentView, containerView, authorLabel, mapView, obfuscationView) { contentView, container, authorLabel, mapView, obfuscationView in
            container.left == contentView.leftMargin
            container.right == contentView.rightMargin
            container.top == contentView.top
            container.bottom == contentView.bottom
            self.containerHeightConstraint = container.height == 160
            mapView.edges == container.edges
            obfuscationView.edges == container.edges
        }
        
        constrain(containerView, addressContainerView, addressLabel) { container, addressContainer, addressLabel in
            addressContainer.left == container.left
            addressContainer.bottom == container.bottom
            addressContainer.right == container.right
            addressLabel.edges == inset(addressContainer.edges, 12, 0)
            addressContainer.height == 42
        }

        constrain(containerView, countdownContainerView) { container, countDownContainer in
            countDownContainer.top == container.top
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        obfuscationView.isHidden = true
    }

    public override func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        recognizer?.isEnabled = !message.isObfuscated
        if message.isObfuscated {
            obfuscationView.isHidden = false
            return
        }

        guard let locationData = message.locationMessageData else { return }
        
        if let address = locationData.name {
            addressContainerView.isHidden = false
            addressLabel.text = address
        } else {
            addressContainerView.isHidden = true
        }
        
        updateMapLocation(withLocationData: locationData)

        if let annotation = locationAnnotation {
            mapView.removeAnnotation(annotation)
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = locationData.coordinate
        mapView.addAnnotation(annotation)
        locationAnnotation = annotation
    }

    public override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        super.update(forMessage: changeInfo)
        guard changeInfo.isObfuscatedChanged else { return false }
        configure(for: message, layoutProperties: layoutProperties)
        return true
    }
    
    func updateMapLocation(withLocationData locationData: ZMLocationMessageData) {
        if locationData.zoomLevel != 0 {
            mapView.setCenterCoordinate(locationData.coordinate, zoomLevel: Int(locationData.zoomLevel))
        } else {
            // As the zoom level is optional we use a viewport of 250m x 250m if none is specified
            let region = MKCoordinateRegionMakeWithDistance(locationData.coordinate, 250, 250)
            mapView.setRegion(region, animated: false)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let locationData = message.locationMessageData else { return }
        // The zoomLevel calculation depends on the frame of the mapView, so we need to call this here again
        updateMapLocation(withLocationData: locationData)
    }
    
    func openInMaps() {
        message?.locationMessageData?.openInMaps(with: mapView.region.span)
        guard let conversation = message.conversation else { return }
        let sentBySelf = message.sender?.isSelfUser ?? false
        Analytics.shared().tagMediaOpened(.location, inConversation: conversation, sentBySelf: sentBySelf)
    }
    
    open override func messageType() -> MessageType {
        return .location
    }
    
    // MARK: - Selection
    
    open override var selectionRect: CGRect {
        return containerView.bounds
    }
    
    open override var selectionView: UIView! {
        return containerView
    }
    
    // MARK: - Selection, Copy & Delete
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(cut), #selector(paste(_:)), #selector(select(_:)), #selector(selectAll(_:)):
            return false
        case #selector(copy(_:)), #selector(forward(_:)):
            return !self.message.isEphemeral
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    open override func copy(_ sender: Any?) {
        guard let locationMessageData = message.locationMessageData else { return }
        let coordinates = "\(locationMessageData.latitude), \(locationMessageData.longitude)"
        UIPasteboard.general.string = message.locationMessageData?.name ?? coordinates
    }
    
    open override func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = setSelectedByMenu
        properties.additionalItems = [.forward(with: #selector(forward))]
        return properties
    }
    
    private func setSelectedByMenu(_ selected: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? ConversationCellSelectionAnimationDuration: 0) {
            self.containerView.alpha = selected ? ConversationCellSelectedOpacity : 1
        }
    }
    
    public override func prepareLayoutForPreview(message: ZMMessage?) -> CGFloat {
        let height = super.prepareLayoutForPreview(message: message)
        self.containerHeightConstraint.constant = 160
        return height
    }
}
