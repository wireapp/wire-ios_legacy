//
//  NotificationViewController.swift
//  ImageNotificationExtension
//
//  Created by Mihail Gerasimenko on 3/3/17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import WireExtensionComponents


class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView = UIImageView()
        self.view.addSubview(self.imageView)
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        
    }
    
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        
        
    }
}
