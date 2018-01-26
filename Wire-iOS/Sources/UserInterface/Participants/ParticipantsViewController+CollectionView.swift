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

extension ParticipantsViewController: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let userType = UserType(rawValue:section),
            let array = groupedParticipants[userType] as? [ZMUser]
            else { return 0 }

        return array.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ParticipantCellReuseIdentifier, for: indexPath) as? ParticipantsListCell else { fatal("unable to dequeue cell with ParticipantCellReuseIdentifier") }

        configureCell(cell, at: indexPath)
        return cell
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return hasServiceUserInParticipants() ? 2 : 1
    }

    // MARK: - section header

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let userType = UserType(rawValue: section), userType == .serviceUser else {
            return .zero
        }

        var height: CGFloat = 24
        if let headerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).first as? ParticipantsCollectionHeaderView {
            headerView.layoutIfNeeded()
            height = headerView.systemLayoutSizeFitting(UILayoutFittingExpandedSize).height
        }

        return CGSize(width: collectionView.bounds.size.width, height: height)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let userType = UserType(rawValue:indexPath.section), userType == .serviceUser else { return UICollectionReusableView() }

        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                               withReuseIdentifier: ParticipantCollectionViewSectionHeaderReuseIdentifier,
                                                                               for: indexPath) as? ParticipantsCollectionHeaderView
            else { fatal("cannot dequeue header") }

        headerView.title = "peoplepicker.header.services".localized
        return headerView
    }
}

extension ParticipantsViewController {

    enum DeviceScreenSize {
        case iPhone3_5Inch
        case iPhone4Inch
        case iPhone4_7Inch
        case iPhone5_5Inch
        case iPhone5_8Inch
        case iPhoneBiggerThan5_8Inch
        case iPad
        case unknown

        static var screenSizeOfThisDevice: DeviceScreenSize {
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                return .iPad
            case .phone:
                let screenHeight = UIScreen.main.nativeBounds.size.height

                switch screenHeight {
                case 960:
                    return .iPhone3_5Inch
                case 1136:
                    return .iPhone4Inch
                case 1334:
                    return .iPhone4_7Inch
                case 1920:
                    return .iPhone5_5Inch
                case 2436:
                    return .iPhone5_8Inch
                default:
                    return .iPhoneBiggerThan5_8Inch
                }
            default:
                return .unknown
            }
        }
    }

    // MARK: - collectionview layout configuration
    func configCollectionViewLayout() {

        /// 96x132 for iPhone 6 or bigger, others are 80x116
        switch DeviceScreenSize.screenSizeOfThisDevice {
        case .iPhone4_7Inch, .iPhone5_5Inch, .iPhone5_8Inch, .iPhoneBiggerThan5_8Inch:
            self.collectionViewLayout.itemSize = CGSize(width: 96, height: 132)
        default:
            self.collectionViewLayout.itemSize = CGSize(width: 80, height: 116)
        }

        self.collectionViewLayout.sectionInset = UIEdgeInsets(top: self.insetMargin, left: self.insetMargin, bottom: self.insetMargin, right: self.insetMargin)
        self.collectionViewLayout.minimumLineSpacing = 0.0
    }

    // MARK: - Cell configuration

    func user(at indexPath: IndexPath) -> ZMUser? {
        guard let userType = UserType(rawValue:indexPath.section),
            let array = groupedParticipants[userType] as? [ZMUser],
            indexPath.row < array.count else { return nil }

        let user = array[indexPath.row]

        return user
    }

    func configureCell(_ cell: ParticipantsListCell, at indexPath: IndexPath) {
        cell.update(for: user(at: indexPath), in: conversation)
    }

    // MARK: - Service user identification

    func hasServiceUserInParticipants() -> Bool {
        guard let array = groupedParticipants[UserType.serviceUser] as? [ZMUser]
            else { return false }

        return array.count >= 1
    }

    // MARK: - refresh collection view data source

    func updateParticipants() {
        self.groupedParticipants = self.conversation.sortedOtherActiveParticipantsGroupByUserType

        self.collectionView?.reloadData()
    }
}

