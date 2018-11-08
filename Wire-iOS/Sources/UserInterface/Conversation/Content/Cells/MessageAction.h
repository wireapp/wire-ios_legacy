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


@protocol ZMConversationMessage;

typedef NS_ENUM(NSUInteger, MessageAction) {
    MessageActionCancel,
    MessageActionResend,
    MessageActionDelete,
    MessageActionPresent,
    MessageActionSave,
    MessageActionCopy,
    MessageActionEdit,
    MessageActionSketchDraw,
    MessageActionSketchEmoji,
    MessageActionSketchText,
    MessageActionLike,
    MessageActionForward,
    MessageActionShowInConversation,
    MessageActionDownload,
    MessageActionReply,
    MessageActionOpenQuote
};

@protocol MessageActionResponder <NSObject>
@required
- (BOOL)canPerformAction:(MessageAction)action forMessage:(id<ZMConversationMessage>)message;
- (void)wantsToPerformAction:(MessageAction)action forMessage:(id<ZMConversationMessage>)message;
@end
