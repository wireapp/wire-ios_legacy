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


/* Secure level can change only the following way:
 
 NotSecure -> Secure
     ^          ^
      \         |
       \        v
        \---- PartialSecureWithIgnored
 
 Initially conversation is not secured. If user goes and trust all current participants' clients
 it goes to secure state. If new client is added it goes to partial secure state.
 When user trust this new client conversation goes back to secure state.
 If the user chooses to send the messages anyway, conversation goes to not secure state
 */
typedef NS_CLOSED_ENUM(int16_t, ZMConversationSecurityLevel) {
    /// Conversation is not secured
    ZMConversationSecurityLevelNotSecure = 0,
    
    /// All of participants' clients are trusted or ignored
    /// (messages will not be sent until the conversation becomes secure or not secure)
    ZMConversationSecurityLevelSecureWithIgnored,
    
    /// All of participants' clients are trusted
    ZMConversationSecurityLevelSecure
};
