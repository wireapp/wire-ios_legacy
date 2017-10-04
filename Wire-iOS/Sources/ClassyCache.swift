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


import Classy
import Foundation
import CocoaLumberjackSwift

extension Dictionary
{
    func wr_keyValues() -> [[String: AnyObject]] {
        return self.keys.map({ ["key": $0 as AnyObject,
                                "value": self[$0]! as AnyObject] as [String: AnyObject] })
    }
    
    func wr_sortedKeyValues() -> [[String: AnyObject]] {
        let sortByKey = NSSortDescriptor(key: "key", ascending:true)
        return (self.wr_keyValues() as NSArray).sortedArray(using: [sortByKey]) as! [[String: AnyObject]]
    }
}

@objc class ClassyCache: NSObject, CASCacheProtocol {
    
    override init() {
        super.init()
        let currentAppBuild = type(of: self).currentAppBuild
        let lastAppBuild = type(of: self).lastAppBuild
        
        if currentAppBuild != lastAppBuild {
            do {
                try FileManager.default.removeItem(atPath: type(of: self).casDirectory as String)
            }
            catch let error as NSError {
                DDLogError("Cannot clear CAS cache: \(error)")
            }
            type(of: self).lastAppBuild = currentAppBuild
        }
        
        if !FileManager.default.fileExists(atPath: type(of: self).casDirectory as String) {
            do {
                try FileManager.default.createDirectory(atPath: type(of: self).casDirectory as String, withIntermediateDirectories: true, attributes: .none)
            }
            catch let error as NSError {
                DDLogError("Cannot create CAS cache: \(error)")
            }
        }
    }
    
    static let currentAppBuild: String = {
        guard let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "999998"
        }
        
        return version
    }()
    
    static var lastAppBuild: String {
        get {
            guard let lastBuild = UserDefaults.standard.object(forKey: self.lastAppBuildKey) as? String else {
                return ""
            }
        
            return lastBuild
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: self.lastAppBuildKey)
        }
    }
    
    static let lastAppBuildKey = "ZMLastUsedBuild"
    
    static let casDirectory: NSString = {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        return cachePath.appendingPathComponent("cas") as NSString
    }()
    
    func bcasPath(_ casPath: String, variables: [AnyHashable: Any]!) -> String? {
        let data = variables.wr_sortedKeyValues()
        guard let fileData = NSMutableData(contentsOfFile: casPath),
            let variablesJSON = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            else {
                return .none
        }
        
        fileData.append(variablesJSON)
        let casHash = fileData.wr_MD5Hash()
        
        let casName = ((casPath as NSString).lastPathComponent as NSString).deletingPathExtension
        let bcasPath = type(of: self).casDirectory.appendingPathComponent("\(casName)-\(casHash).bcas")
        
        return bcasPath
    }
    
    // MARK: - CASCacheProtocol
    
    func cacheStyleNodes(_ styleNodes: [AnyObject]!, fromPath path: String!, variables: [AnyHashable: Any]!) {
        guard let bcasPath = self.bcasPath(path, variables: variables),
            let styleNodes = styleNodes else {
            return
        }
        
        delay(5) {
            let data = NSKeyedArchiver.archivedData(withRootObject: styleNodes)
            let bcasFolderPath = (bcasPath as NSString).deletingLastPathComponent
            
            guard ((try? FileManager.default.createDirectory(atPath: bcasFolderPath, withIntermediateDirectories: true, attributes: .none)) != nil) else {
                DDLogError("Cannot create directory for bcas: " + bcasPath)
                return
            }
            
            guard ((try? data.write(to: URL(fileURLWithPath: bcasPath), options: .atomicWrite)) != nil) else {
                DDLogError("bcas cannot be saved to: " + bcasPath)
                return
            }
            
            DDLogInfo("Saved bcas to: \(bcasPath) (\(data.count))")
        }
    }
    
    func cachedStyleNodes(fromCASPath path: String!, withVariables variables: [AnyHashable: Any]!) -> [AnyObject]! {
        guard let bcasPath = self.bcasPath(path, variables: variables) else {
            return .none
        }
        
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: bcasPath),
            let fileSize = attributes[FileAttributeKey.size] as? Int
            , fileSize != 0 else {
                DDLogInfo("bcas file not found")
                return .none
        }
        
        DDLogInfo("Loading bcas file")
        
        
        if let array = NSKeyedUnarchiver.unarchiveObject(withFile: bcasPath) as? [AnyObject] {
            return array
        }
        else {
            DDLogError("bcas cannot be decoded")
            // We need to cleanup the archive since we cannot decode it
            _ = try? FileManager.default.removeItem(atPath: bcasPath)
            return .none
        }
        
    }}
