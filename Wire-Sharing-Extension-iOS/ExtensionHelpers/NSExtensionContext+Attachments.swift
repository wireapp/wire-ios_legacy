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
import MobileCoreServices



extension NSExtensionContext {
    
    var extensionItems: [NSExtensionItem] {
        return self.inputItems as! [NSExtensionItem]
    }
    
    func plainTextItemProvider() -> NSItemProvider? {
        return self.providersWithType(kUTTypePlainText).first
    }
    
    func urlItemProvider() -> NSItemProvider? {
        return self.providersWithType(kUTTypeURL).first
    }
    
    func imageItemProviders() -> [NSItemProvider] {
        return self.providersWithType(kUTTypeImage)
    }
    
    func providersWithType(_ type: CFString) -> [NSItemProvider] {
        var providers: [NSItemProvider] = []
        for extensionItem in self.extensionItems {
            providers.insert(extensionItem.providersWithType(type), at: providers.count)
        }
        return providers
    }
}
