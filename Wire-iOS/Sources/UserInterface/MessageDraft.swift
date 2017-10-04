//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


import CoreData


/// Class describing unsent message drafts for later sending or further editing.
@objc public class MessageDraft: NSManagedObject {

    private static let entityName = "MessageDraft"

    /// The subject of the message
    @NSManaged public var subject: String?
    /// The message content
    @NSManaged public var message: String?
    /// A date indicating when the draft was last modified
    @NSManaged public var lastModifiedDate: NSDate?

    @nonobjc public class var request: NSFetchRequest<MessageDraft> {
        let request = NSFetchRequest<MessageDraft>(entityName: entityName)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(MessageDraft.lastModifiedDate), ascending: false)]
        return request
    }

    static func insertNewObject(in moc: NSManagedObjectContext) -> MessageDraft {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: moc) as! MessageDraft
    }

    fileprivate func shareableText() -> String? {
        guard canBeSent else { return nil }
        var text = ""

        if let subject = subject, !subject.isEmpty {
            text += "# " + subject
            if nil != message {
                text += "\n"
            }
        }

        if let message = message, !message.isEmpty {
            text += message
        }

        return text
    }

    var canBeSent: Bool {
        return subject?.isEmpty == false || message?.isEmpty == false
    }
    
}


func ==(lhs: MessageDraft, rhs: MessageDraft) -> Bool {
    return lhs.subject == rhs.subject && lhs.message == rhs.message && lhs.lastModifiedDate == rhs.lastModifiedDate
}


extension MessageDraft: Shareable {
    
    public typealias I = ZMConversation

    public func share<ZMConversation>(to: [ZMConversation]) {
        ZMUserSession.shared()?.performChanges {
            send(draft: self, to: to as [AnyObject])
        }
    }

    /*
        The MessageDraft object doesn't show a preview right now.
        To implement a preview view, just return a UIView here.
        Don't forget to return the height of the view in `height(forPreviewView:)`.
     */
    public func previewView() -> UIView? {
        return nil
    }
    
    public func height(for previewView: UIView?) -> CGFloat {
        return 0.0
    }
    
}


fileprivate func send(draft: MessageDraft, to: [AnyObject]) {
    let conversations = to as! [ZMConversation]
    conversations.forEachNonEphemeral {
        _ = $0.appendMessage(withText: draft.shareableText())
    }
}
