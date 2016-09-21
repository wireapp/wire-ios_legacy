//
//  String+WireLocales.swift
//  Wire-iOS
//
//  Created by Kevin Taniguchi on 9/18/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation


extension NSString {
    
    var uppercaseStringWithCurrentLocale: String? {
        return uppercaseStringWithLocale(NSLocale.currentLocale())
    }
    
    var lowercaseStringWithCurrentLocale: String? {
        return lowercaseStringWithLocale(NSLocale.currentLocale())
    }
    
    private var slashCommandMatcher: NSRegularExpression? {
        struct Singleton {
            static let sharedInstance = try? NSRegularExpression(pattern: "^\\/", options: [])
        }
        return Singleton.sharedInstance
    }
    
    var matchesSlashCommand: Bool {
        let range = NSMakeRange(0, length)
        return slashCommandMatcher?.matchesInString(self as String, options: [], range: range).count > 0
    }
    
    var args: [String]? {
        guard self.matchesSlashCommand else {
            return []
        }
        
        let slashlessString = stringByReplacingCharactersInRange(NSMakeRange(0, 1), withString: "")
        return slashlessString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}

//static NSRegularExpression *slashCommandMatcher;
//
//
//@implementation NSString (Wire)
//
//
//- (NSString *)uppercaseStringWithCurrentLocale;
//{
//    return [self uppercaseStringWithLocale:[NSLocale currentLocale]];
//    }
//    
//    - (NSString *)lowercaseStringWithCurrentLocale;
//{
//    return [self lowercaseStringWithLocale:[NSLocale currentLocale]];
//    }
//    
//    - (BOOL)matchesSlashCommand
//        {
//            static dispatch_once_t onceToken;
//            dispatch_once(&onceToken, ^{
//            slashCommandMatcher = [NSRegularExpression regularExpressionWithPattern:@"^\\/" options:0 error:nil];
//            });
//            
//            BOOL match = NO;
//            
//            if ([slashCommandMatcher matchesInString:self options:0 range:NSMakeRange(0, self.length)].count) {
//                match = YES;
//            }
//            
//            return match;
//        }
//        
//        
//        - (NSArray *)args
//            {
//                if (self.matchesSlashCommand) {
//                    NSString *slashlessString = [self stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
//                    return [slashlessString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//                }
//                else {
//                    return [NSArray array];
//                }
//}
//
//@end
