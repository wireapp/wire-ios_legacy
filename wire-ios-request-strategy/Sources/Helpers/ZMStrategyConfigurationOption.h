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

/// OptionSet which controls when under which conditions request strategies are allowed to make requests.
typedef NS_OPTIONS(NSUInteger, ZMStrategyConfigurationOption) {
    
    /** Strategy is not allowed to make requests.
     */
    ZMStrategyConfigurationOptionDoesNotAllowRequests = 0,
    
    /** Strategy is allowed to make requests before the user has authenticated and received a cookie.
     */
    ZMStrategyConfigurationOptionAllowsRequestsWhileUnauthenticated = 1 << 0,
    
    /** Strategy is allowed to make requests while the application is operating in the background.
     */
    ZMStrategyConfigurationOptionAllowsRequestsWhileInBackground = 1 << 1,
    
    /** Strategy is allowed to make requests while the application is waiting for the websocket to be established.
     */
    ZMStrategyConfigurationOptionAllowsRequestsWhileWaitingForWebsocket = 1 << 2,
    
    /** Strategy is allowed to make requests when the application is online and is receiving events via the web socket.
     */
    ZMStrategyConfigurationOptionAllowsRequestsWhileOnline = 1 << 3,
    
    /** Strategy is allowed to make requests during slow sync phase.
        
        During the slow sync phase the application is downloading metadata about users, conversations, etc..
    */
    ZMStrategyConfigurationOptionAllowsRequestsDuringSlowSync = 1 << 4,
    
    /** Strategy is allowed to make requests during quick sync phase.
     
        During the quick sync phase the application is catching up on changes since it was last active, during this phase we are downloading and decrypting messages.
     
        WARNING: it's important that we don't send any encrypted message during this phase since it can lead to encryption errors.
     */
    ZMStrategyConfigurationOptionAllowsRequestsDuringQuickSync = 1 << 5
};
