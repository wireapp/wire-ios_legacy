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

typealias CallParticipantsList = [CallParticipantsCellConfiguration]

protocol CallParticipantsCellConfigurationConfigurable: Reusable {
    func configure(with configuration: CallParticipantsCellConfiguration, variant: ColorSchemeVariant)
}

enum CallParticipantsCellConfiguration: Hashable {
    case callParticipant(user: ZMUser, sendsVideo: Bool)
    case showAll(totalCount: Int)
    
    var cellType: CallParticipantsCellConfigurationConfigurable.Type {
        switch self {
        case .callParticipant: return UserCell.self
        case .showAll: return ShowAllParticipantsCell.self
        }
    }
    
    // MARK: - Convenience
    
    static var allCellTypes: [UICollectionViewCell.Type] {
        return [
            UserCell.self,
            ShowAllParticipantsCell.self,
        ]
    }
    
    static func prepare(_ collectionView: UICollectionView) {
        allCellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.reuseIdentifier)
        }
    }
    
    var hashValue: Int {
        switch self {
        case let .callParticipant(user: user, sendsVideo: sendsVideo): return user.hashValue ^ sendsVideo.hashValue
        case let .showAll(totalCount: count): return count.hashValue
        }
    }

}

extension CallParticipantsCellConfiguration: Equatable {
    
    static func ==(lhs: CallParticipantsCellConfiguration, rhs: CallParticipantsCellConfiguration) -> Bool {
        switch (lhs, rhs) {
        case (.showAll(let lhsCount), .showAll(let rhsCount)):
            return lhsCount == rhsCount
        case (.callParticipant(let lhsUser), .callParticipant(let rhsUser)):
            return lhsUser == rhsUser
        default:
            return false
        }
    }
    
}

class CallParticipantsView: UICollectionView, Themeable {
    
    var rows = CallParticipantsList() {
        didSet {
            reloadData()
        }
    }
    
    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.any {
            !$0.isHidden && $0.point(inside: convert(point, to: $0), with: event) && $0 is ShowAllParticipantsCell
        }
    }
    
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        reloadData()
    }
    
    override init(frame: CGRect, collectionViewLayout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: collectionViewLayout)
        self.dataSource = self
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CallParticipantsView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellConfiguration = rows[indexPath.row]
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: cellConfiguration.cellType.reuseIdentifier, for: indexPath)

        if let configurableCell = cell as? CallParticipantsCellConfigurationConfigurable {
            configurableCell.configure(with: cellConfiguration, variant: colorSchemeVariant)
        }
        
        return cell
    }
    
}

extension UserCell: CallParticipantsCellConfigurationConfigurable {
    
    func configure(with configuration: CallParticipantsCellConfiguration, variant: ColorSchemeVariant) {
        guard case let .callParticipant(user, sendsVideo) = configuration else { preconditionFailure() }
        colorSchemeVariant = variant
        contentBackgroundColor = .clear
        hidesSubtitle = true
        configure(with: user)
        accessoryIconView.isHidden = true
        videoIconView.isHidden = !sendsVideo
    }
    
}
