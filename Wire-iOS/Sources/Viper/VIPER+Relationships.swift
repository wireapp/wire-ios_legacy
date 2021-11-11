//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

/// Naming convention:
///
/// The names of all relationship protocols follow the format:
///
///  <module name><implementer><caller>Interface
/// 
/// For example, the name FooInteractorPresenterInterface is the relationship
/// implemented by the interactor, called by the presenter, and located in the
/// "Foo" module.
///
/// This format is designed to make it easy to search for a particular relationship protocol.
/// If you are searching for a particular protocol, type first the module name, then the
/// component that implements the methods, then the component that calls the methods.

/// Interface of the interactor from the perspective of the presenter.
///
/// Typically contains methods fetch data and perform business logic.

protocol InteractorPresenterInterface: AnyObject { }

/// Interface of the presenter from the perspective of the interactor.
///
/// Typically contains methods to report the results of data fetches
/// and business logic.

protocol PresenterInteractorInterface: AnyObject { }

/// Interface of the presenter from the perspective of the view.
///
/// Typically contains methods to react to view life cycle and
/// use interaction events.

protocol PresenterViewInterface: AnyObject { }

/// Interface of the view from the perspective of the presenter.
///
/// Typically contains methods to set and update view data.

protocol ViewPresenterInterface: AnyObject { }

/// Interface of the router from the perspective of the presenter.
///
/// Typically contains methods to react to navigation requests.

protocol RouterPresenterInterface: AnyObject { }
