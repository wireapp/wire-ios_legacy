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

/// Displays the location message
@objc public class LocationMessageCell: ConversationCell {
    
    private let mapView = MKMapView()
    private let containerView = UIView()
    private let addressContainerView = UIView()
    private let addressLabel = UILabel()
    private weak var locationAnnotation: MKPointAnnotation? = nil
    var labelFont: UIFont?
    var labelTextColor, containerColor: UIColor?
    
    public override required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 4
        containerView.clipsToBounds = true
        containerView.cas_styleClass = "container-view"
        CASStyler.defaultStyler().styleItem(self)
        configureViews()
        createConstraints()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        mapView.scrollEnabled = false
        mapView.zoomEnabled = false
        mapView.rotateEnabled = false
        mapView.pitchEnabled = false
        mapView.mapType = .Standard
        mapView.showsPointsOfInterest = true
        mapView.showsBuildings = true
        mapView.userInteractionEnabled = false
        messageContentView.addSubview(containerView)
        [mapView, addressContainerView].forEach(containerView.addSubview)
        addressContainerView.addSubview(addressLabel)
        
        guard let font = labelFont, color = labelTextColor, containerColor = containerColor else { return }
        addressLabel.font = font
        addressLabel.textColor = color
        addressContainerView.backgroundColor = containerColor
    }
    
    private func createConstraints() {
        constrain(messageContentView, containerView, authorLabel, mapView) { contentView, container, authorLabel, mapView in
            container.left == authorLabel.left
            container.right == contentView.rightMargin
            container.top == contentView.top
            container.bottom == contentView.bottom
            container.height == 160
            mapView.edges == container.edges
        }
        
        constrain(containerView, addressContainerView, addressLabel) { container, addressContainer, addressLabel in
            addressContainer.left == container.left
            addressContainer.bottom == container.bottom
            addressContainer.right == container.right
            addressLabel.edges == inset(addressContainer.edges, 12, 0)
            addressContainer.height == 42
        }
        
        self.toolboxTopOffsetConstraint.constant = 8
    }
    
    public override func configureForMessage(message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configureForMessage(message, layoutProperties: layoutProperties)
        guard let locationData = message.locationMessageData else { return }
        
        if let address = locationData.name {
            addressContainerView.hidden = false
            addressLabel.text = address
        } else {
            addressContainerView.hidden = true
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
    
    func updateMapLocation(withLocationData locationData: ZMLocationMessageData) {
        if locationData.zoomLevel != 0 {
            mapView.setCenterCoordinate(locationData.coordinate, zoomLevel: Int(locationData.zoomLevel))
        } else {
            // As the zoom level is optional we use a viewport of 250m x 250m if none is specified
            let region = MKCoordinateRegionMakeWithDistance(locationData.coordinate, 250, 250)
            mapView.setRegion(region, animated: false)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let locationData = message.locationMessageData else { return }
        // The zoomLevel calculation depends on the frame of the mapView, so we need to call this here again
        updateMapLocation(withLocationData: locationData)
    }
    
    func openInMaps() {
        message?.locationMessageData?.openInMaps(withSpan: mapView.region.span)
        guard let conversation = message.conversation else { return }
        let sentBySelf = message.sender?.isSelfUser ?? false
        Analytics.shared()?.tagMediaOpened(.Location, inConversation: conversation, sentBySelf: sentBySelf)
    }
    
    public override func messageType() -> MessageType {
        return .Location
    }
    
    // MARK: - Selection
    
    public override var selectionRect: CGRect {
        return containerView.bounds
    }
    
    public override var selectionView: UIView! {
        return containerView
    }
    
    // MARK: - Selection, Copy & Delete
    
    public override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        switch action {
        case #selector(cut), #selector(paste), #selector(select), #selector(selectAll):
            return false
        case #selector(copy(_:)):
            return true
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    public override func copy(sender: AnyObject?) {
        guard let locationMessageData = message.locationMessageData else { return }
        let coordinates = "\(locationMessageData.latitude), \(locationMessageData.longitude)"
        UIPasteboard.generalPasteboard().string = message.locationMessageData?.name ?? coordinates
    }
    
    public override func menuConfigurationProperties() -> MenuConfigurationProperties! {
        let properties = MenuConfigurationProperties()
        properties.targetRect = selectionRect
        properties.targetView = selectionView
        properties.selectedMenuBlock = setSelectedByMenu
        return properties
    }
    
    private func setSelectedByMenu(selected: Bool, animated: Bool) {
        UIView.animateWithDuration(animated ? ConversationCellSelectionAnimationDuration: 0) {
            self.containerView.alpha = selected ? ConversationCellSelectedOpacity : 1
        }
    }
}

private extension ZMLocationMessageData {
    
    private func openInMaps(withSpan span: MKCoordinateSpan) {
        let launchOptions = [
            MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: span)
        ]
        mapItem?.openInMapsWithLaunchOptions(launchOptions)
    }
    
    private var mapItem: MKMapItem? {
        var addressDictionary: [String : AnyObject]? = nil
        if let name = name {
            addressDictionary = [String(kABPersonAddressStreetKey): name]
        }
        
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }
}
