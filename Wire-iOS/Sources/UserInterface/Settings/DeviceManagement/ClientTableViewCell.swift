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


import UIKit
import Cartography
import CoreLocation
import AddressBook
import CocoaLumberjackSwift


class ClientTableViewCell: UITableViewCell {
    
    let nameLabel: UILabel
    let labelLabel: UILabel
    let activationLabel: UILabel
    let fingerprintLabel: UILabel
    let verifiedLabel: UILabel
    
    var showVerified: Bool = false {
        didSet {
            self.updateVerifiedLabel()
        }
    }
    
    var showLabel: Bool = false {
        didSet {
            self.updateLabel()
        }
    }
    
    var fingerprintLabelFont: UIFont? {
        didSet {
            self.updateFingerprint()
        }
    }
    var fingerprintLabelBoldFont: UIFont? {
        didSet {
            self.updateFingerprint()
        }
    }
    
    var userClient: UserClient? {
        didSet {
            if let userClient = self.userClient {
                if let userClientModel = userClient.model {
                        
                    nameLabel.text = userClientModel
                }
                
                self.updateLabel()
                
                if let activationDate = userClient.activationDate , userClient.activationLocationLatitude != 0 && userClient.activationLocationLongitude != 0 {

                    let localClient = self.userClient
                    CLGeocoder().reverseGeocodeLocation(userClient.activationLocation, completionHandler: { (placemarks: [CLPlacemark]?, error: NSError?) -> Void in

                        if let placemark = placemarks?.first,
                            let addressCountry = placemark.addressDictionary?[kABPersonAddressCountryCodeKey as String],
                            let addressCity = placemark.addressDictionary?[kABPersonAddressCityKey as String] ,
                            localClient == self.userClient &&
                            error == .None {
                                
                            self.activationLabel.text = "\(NSLocalizedString("registration.devices.activated_in", comment: "")) \(addressCity), \(addressCountry.uppercaseString) — \(activationDate.wr_formattedDate())"
                        }
                    } as! CLGeocodeCompletionHandler)
                    
                    self.activationLabel.text = (activationDate as NSDate).wr_formattedDate()
                }
                else if let activationDate = userClient.activationDate {
                    self.activationLabel.text = (activationDate as NSDate).wr_formattedDate()
                }
                else {
                    self.activationLabel.text = ""
                }
                
                self.updateFingerprint()
                self.updateVerifiedLabel()
            }
        }
    }
    
    var wr_editable: Bool
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.nameLabel = UILabel(frame: CGRect.zero)
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.labelLabel = UILabel(frame: CGRect.zero)
        self.labelLabel.translatesAutoresizingMaskIntoConstraints = false
        self.activationLabel = UILabel(frame: CGRect.zero)
        self.activationLabel.translatesAutoresizingMaskIntoConstraints = false
        self.fingerprintLabel = UILabel(frame: CGRect.zero)
        self.fingerprintLabel.translatesAutoresizingMaskIntoConstraints = false
        self.verifiedLabel = UILabel(frame: CGRect.zero)
        self.verifiedLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.wr_editable = true
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.labelLabel)
        self.contentView.addSubview(self.activationLabel)
        self.contentView.addSubview(self.fingerprintLabel)
        self.contentView.addSubview(self.verifiedLabel)
        
        constrain(self.contentView, self.nameLabel, self.labelLabel) { contentView, nameLabel, labelLabel in
            nameLabel.top == contentView.top + 16
            nameLabel.left == contentView.left + 16
            nameLabel.right <= contentView.right - 16
            
            labelLabel.top == nameLabel.bottom + 2
            labelLabel.left == contentView.left + 16
            labelLabel.right <= contentView.right - 16
        }
        
        constrain(self.contentView, self.labelLabel, self.activationLabel, self.fingerprintLabel, self.verifiedLabel) { contentView, labelLabel, activationLabel, fingerprintLabel, verifiedLabel in
            
            fingerprintLabel.top == labelLabel.bottom + 4
            fingerprintLabel.left == contentView.left + 16
            fingerprintLabel.right <= contentView.right - 16
            fingerprintLabel.height == 16
            
            activationLabel.top == fingerprintLabel.bottom + 8
            activationLabel.left == contentView.left + 16
            activationLabel.right <= contentView.right - 16
            
            verifiedLabel.top == activationLabel.bottom + 4
            verifiedLabel.left == contentView.left + 16
            verifiedLabel.right <= contentView.right - 16
            verifiedLabel.bottom == contentView.bottom - 16
        }
        
        CASStyler.default().styleItem(self)
        self.backgroundColor = UIColor.clear
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        if self.wr_editable {
            super.setEditing(editing, animated: animated)
        }
    }
    
    func updateVerifiedLabel() {
        if let userClient = self.userClient
            , self.showVerified {
            if userClient.verified {
                self.verifiedLabel.text = NSLocalizedString("device.verified", comment: "");
            }
            else {
                self.verifiedLabel.text = NSLocalizedString("device.not_verified", comment: "");
            }
            self.verifiedLabel.textColor = UIColor(white: 1, alpha: 0.4)
        }
        else {
            self.verifiedLabel.text = ""
        }
    }
    
    func updateFingerprint() {
        if let fingerprintLabelBoldMonoFont = self.fingerprintLabelBoldFont?.monospacedFont(),
            let fingerprintLabelMonoFont = self.fingerprintLabelFont?.monospacedFont(),
            let userClient = self.userClient
            , userClient.remoteIdentifier != nil {
                
                self.fingerprintLabel.attributedText =  userClient.attributedRemoteIdentifier(
                    [NSFontAttributeName: fingerprintLabelMonoFont, NSForegroundColorAttributeName: UIColor.whiteColor],
                    boldAttributes: [NSFontAttributeName: fingerprintLabelBoldMonoFont, NSForegroundColorAttributeName: UIColor.whiteColor()],
                    uppercase: true
                )
        }
    }
    
    func updateLabel() {
        if let userClientLabel = self.userClient?.label
            , self.showLabel {
            self.labelLabel.text = userClientLabel
        }
        else {
            self.labelLabel.text = ""
        }
    }
}
