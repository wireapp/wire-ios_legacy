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

/// Interface of the interactor from the perspective of the presenter.
///
/// Typically contains methods fetch data and perform business logic.

protocol InteractorPresenterInterface: class { }

/// Interface of the presenter from the perspective of the interactor.
///
/// Typically contains methods to report the results of data fetches
/// and business logic.

protocol PresenterInteractorInterface: class { }

/// Interface of the presenter from the perspective of the view.
///
/// Typically contains methods to react to view life cycle and
/// use interaction events.

protocol PresenterViewInterface: class { }

/// Interface of the view from the perspective of the presenter.
///
/// Typically contains methods to set and update view data.

protocol ViewPresenterInterface: class { }

/// Interface of the router from the perspective of the presenter.
///
/// Typically contains methods to react to navigation requests.

protocol RouterPresenterInterface: class { }

/// Interface of the presenter from the perspective of the router.

protocol PresenterRouterInterface: class { }
