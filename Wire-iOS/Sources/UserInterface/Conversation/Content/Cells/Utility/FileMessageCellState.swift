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


enum ProgressViewType {
    case Determ // stands for deterministic
    case Infinite
}

typealias FileMessageCellViewsState = (progressViewType: ProgressViewType?, playButtonIcon: ZetaIconType, playButtonBackgroundColor: UIColor?)

public enum FileMessageCellState {
    
    case Unavailable
    
    case Uploading /// only for sender
    
    case Uploaded
    
    case Downloading
    
    case Downloaded
    
    case FailedUpload /// only for sender
    
    case CancelledUpload /// only for sender
    
    case FailedDownload
    
    // Value mapping from message consolidated state (transfer state, previewData, fileURL) to FileMessageCellState
    static func fromConversationMessage(message: ZMConversationMessage) -> FileMessageCellState? {
        guard let fileMessageData = message.fileMessageData where Message.isFileTransferMessage(message) else {
            return .None
        }
        
        switch fileMessageData.transferState {
        case .Uploaded: return .Uploaded
        case .Downloaded: return .Downloaded
        case .Uploading:
            if fileMessageData.fileURL != nil {
                return .Uploading
            } else {
                return .Unavailable
            }
            
        case .Downloading: return .Downloading
        case .FailedUpload:
            if fileMessageData.fileURL != nil {
                return .FailedUpload
            } else {
                return .Unavailable
            }
        case .CancelledUpload:
            if fileMessageData.fileURL != nil {
                return .CancelledUpload
            } else {
                return .Unavailable
            }
        case .FailedDownload: return .FailedDownload
        }
    }
    
    static let clearColor   = UIColor.clearColor()
    static let normalColor  = UIColor.blackColor().colorWithAlphaComponent(0.4)
    static let failureColor = UIColor.redColor().colorWithAlphaComponent(0.24)
    
    typealias ViewsStateMapping = [FileMessageCellState: FileMessageCellViewsState]
    /// Mapping of cell state to it's views state for media message:
    ///  # Cell state ======>      #progressViewType
    ///               ======>      |            #playButtonIcon
    ///               ======>      |            |        #playButtonBackgroundColor
    static let viewsStateForCellStateForVideoMessage: ViewsStateMapping =
        [.Uploading:               (.Determ,   .Cancel, normalColor),
         .Uploaded:                (.None,     .Play,   normalColor),
         .Downloading:             (.Determ,   .Cancel, normalColor),
         .Downloaded:              (.None,     .Play,   normalColor),
         .FailedUpload:            (.None,     .Redo,   failureColor),
         .CancelledUpload:         (.None,     .Redo,   normalColor),
         .FailedDownload:          (.None,     .Redo,   failureColor),]
    
    /// Mapping of cell state to it's views state for media message:
    ///  # Cell state ======>      #progressViewType
    ///               ======>      |            #playButtonIcon
    ///               ======>      |            |        #playButtonBackgroundColor
    static let viewsStateForCellStateForAudioMessage: ViewsStateMapping =
        [.Uploading:               (.Determ,   .Cancel, normalColor),
         .Uploaded:                (.None,     .Play,   normalColor),
         .Downloading:             (.Determ,   .Cancel, normalColor),
         .Downloaded:              (.None,     .Play,   normalColor),
         .FailedUpload:            (.None,     .Redo,   failureColor),
         .CancelledUpload:         (.None,     .Redo,   normalColor),
         .FailedDownload:          (.None,     .Redo,   failureColor),]
    
    /// Mapping of cell state to it's views state for normal file message:
    ///  # Cell state ======>      #progressViewType
    ///               ======>      |            #actionButtonIcon
    ///               ======>      |            |        #actionButtonBackgroundColor
    static let viewsStateForCellStateForFileMessage: ViewsStateMapping =
        [.Uploading:               (.Determ,   .Cancel, normalColor),
         .Downloading:             (.Determ,   .Cancel, normalColor),
         .Downloaded:              (.None,     .None,   clearColor),
         .Uploaded:                (.None,     .None,   clearColor),
         .FailedUpload:            (.None,     .Redo,   failureColor),
         .CancelledUpload:         (.None,     .Redo,   normalColor),
         .FailedDownload:          (.None,     .Save,   failureColor),]
    
    func viewsStateForVideo() -> FileMessageCellViewsState? {
        return self.dynamicType.viewsStateForCellStateForVideoMessage[self]
    }
    
    func viewsStateForAudio() -> FileMessageCellViewsState? {
        return self.dynamicType.viewsStateForCellStateForAudioMessage[self]
    }
    
    func viewsStateForFile() -> FileMessageCellViewsState? {
        return self.dynamicType.viewsStateForCellStateForFileMessage[self]
    }

}

