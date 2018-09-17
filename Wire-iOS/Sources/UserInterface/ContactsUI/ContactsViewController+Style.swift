//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension ContactsViewController {
    @objc func setupStyle() {
        titleLabel?.textAlignment = .center
        titleLabel?.font = .smallLightFont
        titleLabel?.textTransform = .upper

        bottomContainerView.backgroundColor = .background

        noContactsLabel.font = .normalLightFont
        noContactsLabel.textColor = UIColor(scheme: .textForeground, variant: .dark)
    }
}

extension ContactsViewController: SearchHeaderViewControllerDelegate {
    public func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String) {

    }

    public func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchHeaderViewController.tokenField.resignFirstResponder()
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
    }

    @objc func createSearchHeader() {
        searchHeaderViewController = SearchHeaderViewController(userSelection: .init(), variant: .dark)
        searchHeaderViewController.delegate = self
        searchHeaderViewController.allowsMultipleSelection = false
        searchHeaderViewController.view.backgroundColor = UIColor(scheme: .searchBarBackground, variant: .dark)
        addChildViewController(searchHeaderViewController)
        view.addSubview(searchHeaderViewController.view)
        searchHeaderViewController.didMove(toParentViewController: self)
    }
}

///TODO:
/*
- (void)tokenField:(TokenField *)tokenField changedTokensTo:(NSArray *)tokens
{
    NSArray *tokenFieldSelection = [tokens valueForKey:NSStringFromSelector(@selector(representedObject))];
    [self.dataSource setSelection:[NSOrderedSet orderedSetWithArray:tokenFieldSelection]];
    }

    - (void)tokenField:(TokenField *)tokenField changedFilterTextTo:(NSString *)text
{
    self.dataSource.searchQuery = text ? text : @"";
    [self updateEmptyResults];
    }

    - (void)tokenFieldDidConfirmSelection:(TokenField *)controller
{
    if (self.tokenField.tokens.count == 0) {
        [self updateEmptyResults];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(contactsViewControllerDidConfirmSelection:)]) {
        [self.delegate contactsViewControllerDidConfirmSelection:self];
    }
}
*/
