//
//  DevOptionsController.swift
//  Wire-iOS
//
//  Created by Marco Conti on 19/10/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import UIKit

class DevOptionsController2 : UIViewController {
    
    var extraSwitch : UISwitch!
    var extrasLabel : UILabel!
    //let switchesForLogTags : Array
}

extension DevOptionsController2 {
    
    override func loadView() {
        self.title = "Options";
        self.view = UIView()
        self.edgesForExtendedLayout = UIRectEdge()
        self.view.backgroundColor = .clear
        
        self.createExtraSwitch()
        self.createExtrasLabel()
        
//        self.extrasSwitch = [[UISwitch alloc] init];
//        self.extrasSwitch.translatesAutoresizingMaskIntoConstraints = NO;
//        self.extrasSwitch.enabled = YES;
//        [self.extrasSwitch addTarget:self action:@selector(enableExtrasSwitchChanged:) forControlEvents:UIControlEventValueChanged];
//        [self.view addSubview:self.extrasSwitch];
//        
//        self.extrasLabel = [[UILabel alloc] initForAutoLayout];
//        self.extrasLabel.text = @"Enable subtitles (will quit)";
//        self.extrasLabel.textColor = [UIColor whiteColor];
//        [self.view addSubview:self.extrasLabel];
//        
//        NSMutableArray *switchesForLogTags = [NSMutableArray array];
//        for(NSString *tag in ZMLogGetAllTags()) {
//            DevOptionsLabelWithSwitch *labelSwitch = [[DevOptionsLabelWithSwitch alloc] init];
//            labelSwitch.tag = tag;
//            labelSwitch.label = [[UILabel alloc] initForAutoLayout];
//            labelSwitch.label.textColor = [UIColor whiteColor];
//            labelSwitch.label.text = [NSString stringWithFormat:@"Log %@", tag];
//            [self.view addSubview:labelSwitch.label];
//            
//            labelSwitch.uiSwitch = [[UISwitch alloc] initForAutoLayout];
//            labelSwitch.uiSwitch.enabled = YES;
//            
//            labelSwitch.uiSwitch.on = (ZMLogGetLevelForTag([tag UTF8String]) == ZMLogLevelDebug);
//            [labelSwitch.uiSwitch addTarget:self action:@selector(logTagSwitchChanged:) forControlEvents:UIControlEventValueChanged];
//            [self.view addSubview:labelSwitch.uiSwitch];
//            
//            [switchesForLogTags addObject:labelSwitch];
//        }
//        self.switchesForLogTags = switchesForLogTags;
//        
//        [self setupConstraints];
    }
    
    func enableExtrasSwitchChanged(_ sender: Any) {
        
    }

    private func createExtraSwitch() {
        self.extraSwitch = UISwitch()
        self.extraSwitch.translatesAutoresizingMaskIntoConstraints = false
        self.extraSwitch.addTarget(self, action: #selector(DevOptionsController2.enableExtrasSwitchChanged(_:)), for: .valueChanged)
        self.view.addSubview(self.extraSwitch)
    }
    
    private func createExtrasLabel() {
        self.extrasLabel = UILabel()
        self.extraLabel
    }
}
