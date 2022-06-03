//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UniformTypeIdentifiers
import CoreServices
#if os(iOS)
    import MobileCoreServices
#endif

#if targetEnvironment(simulator)

@available(iOSApplicationExtension 14.0, *)
extension UTType {
    var fileExtension: String? {
        switch self {
        case .text:
            return "txt"
        case .mpeg4Movie:
            return "mp4"
        default:
            return nil
        }
    }
    
    /// HACK: subsitution of .preferredMIMEType(returns nil when arch is x86_64) on arm64 simulator
    var mimeType: String? {
        switch self {
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        case .gif:
            return "image/gif"
        case .svg:
            return "image/svg+xml"
        case .json:
            return "application/json"
        case .text:
            return "text/plain"
        case .mpeg4Movie:
            return "video/mp4"
        case .quickTimeMovie:
            return "video/quicktime"
        case .mpeg4Audio:
            return "audio/mp4"
        default:
            return nil
        }
        
    }
}

#endif

@objc
public final class UTIHelper: NSObject {
        
    @available(iOSApplicationExtension 14.0, *)
    private class func conformsTo(uti: String, type: UTType) -> Bool {
        guard let utType = UTType(uti) else {
            return false
        }
        
        return utType.conforms(to: type)
    }
        
    //MARK: - UTI conformation
    
    public class func conformsToGifType(uti: String) -> Bool {
        if #available(iOS 14, *) {
            return conformsTo(uti: uti, type: .gif)
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeGIF)
        }
    }

    @objc
    public class func conformsToImageType(uti: String) -> Bool {
        if #available(iOS 14, *) {
            guard let utType = UTType(uti) else {
                return false
            }
            
            #if targetEnvironment(simulator)
            //HACK: arm64 simulator return false for utType.conforms(to: .image), but add additional subtype check works
            return utType.conforms(to: .image) ||
                utType.conforms(to: .png) ||
                utType.conforms(to: .jpeg) ||
                utType.conforms(to: .gif) ||
                utType.conforms(to: .svg)
            #else
            return utType.conforms(to: .image)
            #endif
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeImage)
        }
    }

    @objc
    public class func conformsToVectorType(uti: String) -> Bool {
        if #available(iOS 14, *) {
            return UTType(uti)?.conforms(to: .svg) ?? false
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeScalableVectorGraphics)
        }
    }
    
    @objc
    public class func conformsToJsonType(uti: String) -> Bool {
        if #available(iOS 14, *) {
            return UTType(uti)?.conforms(to: .json) ?? false
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeJSON)
        }
    }

    //MARK: - MIME conformation
    
    public class func conformsToGifType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else { return false }
        
        return conformsToGifType(uti: uti)
    }

    public class func conformsToAudioType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else {
            return false
        }
        if #available(iOS 14, *) {
            let audioTypes: [UTType] = [.audio, .mpeg4Audio]
            return audioTypes.contains {
                conformsTo(uti: uti, type: $0)
            }
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeAudio)
        }
    }
    
    public class func conformsToMovieType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else {
            return false
        }
        
        if #available(iOS 14, *) {
            let movieTypes: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie]
            
            return movieTypes.contains {
                conformsTo(uti: uti, type: $0)
            }
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeMovie)
        }
    }

    public class func conformsToVectorType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else { return false }
        
        return conformsToVectorType(uti: uti)
    }

    #if targetEnvironment(simulator)
    @available(iOSApplicationExtension 14.0, *)
    private static let utTypes: [UTType] = [.jpeg, .gif, .png, .json, .svg, .mpeg4Movie, .text, .quickTimeMovie, .mpeg4Audio]
    #endif
    
    //MARK: - converters

    public class func convertToFileExtension(mime: String) -> String? {
        if #available(iOS 14, *) {
            var utType: UTType? = UTType(mimeType: mime)

            // for uttype not conforming data, e.g pkpass, retry with conformingTo: nil
            if utType == nil || utType?.preferredFilenameExtension == nil {
                utType = UTType(tag: mime, tagClass: .mimeType, conformingTo: nil)
            }

            #if targetEnvironment(simulator)
            /// HACK: hard code MIME when preferredMIMEType is nil for M1 simulator, we should file a ticket to apple for this issue
            if utType == nil {
                utType = createUTType(mime: mime)
            }
            #endif

            var filenameExtension = utType?.preferredFilenameExtension
            
            #if targetEnvironment(simulator)
            if filenameExtension == nil {
                filenameExtension = utType?.fileExtension
            }
            #endif

            return filenameExtension
        } else {
            guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
                let extensionUTI = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else {
                    return nil
            }
            return String(extensionUTI.takeRetainedValue())
        }
    }
    
    #if targetEnvironment(simulator)
    @available(iOSApplicationExtension 14.0, *)
    private class func createUTType(mime: String) -> UTType? {
        for type in utTypes {
            if mime == type.mimeType {
                return type
            }
        }
        
        return nil
    }
    #endif
    
    @objc
    public class func convertToUti(mime: String) -> String? {
        if #available(iOS 14, *) {
            var utType: UTType? = UTType(mimeType: mime)
            
            #if targetEnvironment(simulator)
            /// HACK: hard code MIME when preferredMIMEType is nil for M1 simulator, we should file a ticket to apple for this issue
            if utType == nil {
                utType = createUTType(mime: mime)
            }
            #endif
            
            return utType?.identifier
        } else {
            return UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
                                                         mime as CFString,
                                                         nil)?.takeRetainedValue() as String?
        }
    }

    public class func convertToMime(fileExtension: String) -> String? {
        if #available(iOS 14, *) {
            var utType: UTType? = UTType(filenameExtension: fileExtension)
            
            // for uttype not conforming data, e.g com.apple.pkpass, retry with conformingTo: nil
            if utType == nil {                
                utType = UTType(tag: fileExtension, tagClass: .filenameExtension, conformingTo: nil)
            }

            #if targetEnvironment(simulator)
            /// HACK: hard code MIME when preferredMIMEType is nil for M1 simulator, we should file a ticket to apple for this issue
            if utType == nil {
                for type in utTypes {
                    if fileExtension == type.fileExtension {
                        utType = type
                        break
                    }
                }
            }
            #endif
            
            var mimeType: String?
            if let utType = utType {
                mimeType = mime(from: utType)
            }
            
            /// HACK: when resolving .pkpass file extension, the above method returns nil, fallback to iOS 13- method.
            if mimeType == nil {
                mimeType = iOS13ConvertToMime(fileExtension: fileExtension)
            }
            
            return mimeType
        } else {
            return iOS13ConvertToMime(fileExtension: fileExtension)
        }
    }
    
    private class func iOS13ConvertToMime(fileExtension: String) -> String? {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                              fileExtension as CFString,
                                                              nil)?.takeRetainedValue() as String? else { return nil }
        
        return convertToMime(uti: uti)
    }
    
    @available(iOSApplicationExtension 14.0, *)
    private class func mime(from utType: UTType) -> String? {
        let mimeType: String

        if let preferredMIMEType = utType.preferredMIMEType {
            mimeType = preferredMIMEType
        } else {
            #if targetEnvironment(simulator)
            /// HACK: hard code MIME when preferredMIMEType is nil for M1 simulator, we should file a ticket to apple for this issue
            guard let type = utType.mimeType else {
                return nil
            }
            
            mimeType = type
            #else
            return nil
            #endif
        }

        return mimeType
    }

    @objc
    public class func convertToMime(uti: String) -> String? {

        if #available(iOS 14, *) {
            guard let utType = UTType(uti) else {
                return nil
            }
            
            return mime(from: utType)
        } else {
            let unmanagedMime = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)
            
            guard let retainedValue = unmanagedMime?.takeRetainedValue() else {
                return nil
            }
            
            return retainedValue as String
        }
    }
    
}
