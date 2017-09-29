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


/// Class used to store objects of type `MessageDraft` on disk.
/// Creates a directory to store the serialized objects if not yet present.
final class MessageDraftStorage: NSObject {

    @objc(setupSharedStorageAtURL:error:)
    static func setupSharedStorage(at URL: URL) throws {
        guard nil == _sharedStorage else { return }
        _sharedStorage = try MessageDraftStorage(accountContainerURL: URL)
    }

    static var shared: MessageDraftStorage {
        precondition(nil != _sharedStorage, "Need to call \"setupSharedStorage\" first")
        return _sharedStorage!
    }

    private static var _sharedStorage: MessageDraftStorage?

    enum StorageError: Error {
        case noModel
    }

    private lazy var managedObjectContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.psc
        return moc
    }()

    lazy var resultsController: NSFetchedResultsController<MessageDraft> = {
        return NSFetchedResultsController(
            fetchRequest: MessageDraft.request,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()

    private let storeURL: URL
    private let psc: NSPersistentStoreCoordinator

    init(accountContainerURL: URL) throws {
        guard let model = NSManagedObjectModel.mergedModel(from: [Bundle(for: MessageDraftStorage.self)]) else { throw StorageError.noModel  }
        psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        let directoryURL = accountContainerURL.appendingPathComponent("drafts")
        try MessageDraftStorage.createDirectoryIfNeeded(at: directoryURL)
        storeURL = directoryURL.appendingPathComponent("Drafts")

        _ = try psc.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: MessageDraftStorage.storeOptions
        )

        super.init()
    }

    private static func createDirectoryIfNeeded(at url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        try url.wr_excludeFromBackup()
    }

    private static var storeOptions: [String: Any] {
        return [
            NSSQLitePragmasOption: ["journal_mode": "WAL", "synchronous" : "FULL"],
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
    }

    func numberOfStoredDrafts() -> Int {
        return (try? managedObjectContext.count(for: MessageDraft.request)) ?? 0
    }

    func enqueue(block: @escaping (NSManagedObjectContext) -> Void) {
        enqueue(block: block, completion: nil)
    }

    func enqueue(block: @escaping (NSManagedObjectContext) -> Void, completion: (() -> Void)?) {
        managedObjectContext.perform {
            block(self.managedObjectContext)
            try? self.managedObjectContext.save()
            completion?()
        }
    }

    func perform(block: @escaping (NSManagedObjectContext) -> Void) {
        managedObjectContext.performAndWait { 
            block(self.managedObjectContext)
            try? self.managedObjectContext.save()
        }
    }
    
}
