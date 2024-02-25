//
//  DataController.swift
//  FeedbackAssistantClone
//
//  Created by Abanoub Ashraf on 10/02/2024.
//

import CoreData

class DataController: ObservableObject {
    let container: NSPersistentContainer
    
    @Published var selectedFilter: Filter? = Filter.all
    @Published var selectedIssue: Issue?
    
    private var saveTask: Task<Void, Error>?
    
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()
    
    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: "Main")
        
        ///
        /// if in memory then this is either for testing or for swiftui preview
        ///
        if inMemory {
            self.container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        ///
        /// - these two tells CoreData how to handle syncing data across multiple devices
        ///
        /// - tells CoreData what to do if a change happens to the data while it's running
        ///   we're telling it to stay in sync automatically
        ///
        container.viewContext.automaticallyMergesChangesFromParent = true
        ///
        /// tells CoreData how the merge between local and remote changes should happen
        /// by specifying that the in memory changes are more important than the remote ones
        ///
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        ///
        /// we wanna be notified whenever any writes or changes to our resistance store happens, tells us so we can update the ui
        ///
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        ///
        /// after we are notified, call the remoteStoreChanged which will emmet to the ui so we can update the ui
        ///
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main,
            using: remoteStoreChanged
        )
        
        ///
        /// this is the database, the longterm storage
        ///
        self.container.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }
    
    func remoteStoreChanged(_ notification: Notification) {
        objectWillChange.send()
    }
    
    func createSampleData() {
        ///
        /// this holds all the active objects in memory right now as we work on them
        /// and only write back to the desk/container only when we call the save() method down there
        ///
        let viewContext = self.container.viewContext
        
        for i in 1...5 {
            let tag = Tag(context: viewContext)
            tag.id = UUID()
            tag.name = "Tag \(i)"
            
            for j in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(i)-\(j)"
                issue.content = "Description goes here"
                issue.creationDate = .now
                issue.completed = .random()
                issue.priority = .random(in: 0...2)
                
                tag.addToIssues(issue)
            }
        }
        
        ///
        /// this method save the changes happened to the objects in ram on the persistence store
        ///
        try? viewContext.save()
    }
    
    func save() {
        ///
        /// only save when there's uncommitted changes
        ///
        if self.container.viewContext.hasChanges {
            try? self.container.viewContext.save()
        }
    }
    
    ///
    /// add delay 3 seconds before saving any change in core data instead of saving on each letter changing
    /// to avoid burning the cpu of the device
    ///
    func queueSave() {
        saveTask?.cancel()
        
        saveTask = Task { @MainActor in
            try await Task.sleep(for: .seconds(3))
            save()
        }
    }
    
    func delete(_ object: NSManagedObject) {
        ///
        /// send a notification that an object is about to change
        ///
        self.objectWillChange.send()
        self.container.viewContext.delete(object)
        self.save()
    }
    
    ///
    /// gets the fetch request from the whole data base and move them to the view context
    ///
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        ///
        /// a delete request to delete objects in the SQLite persistent store without loading them into memory
        ///
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        ///
        /// give me the ids of the objects you deleted
        ///
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        ///
        /// execute the batch delete request and get back the results
        ///
        if let delete = try? self.container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            ///
            /// this dictionary contains all the objects we deleted
            ///
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            ///
            /// merge the dictionary above into the viewContext
            ///
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }
    
    func deleteAll() {
        let request1: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        self.delete(request1)
        
        let request2: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
        self.delete(request2)
        
        self.save()
    }
    
    func missingTags(from issue: Issue) -> [Tag] {
        let request = Tag.fetchRequest()
        let allTags = (try? container.viewContext.fetch(request)) ?? []
        
        let allTagsSet = Set(allTags)
        let difference = allTagsSet.symmetricDifference(issue.issueTags)
        
        return difference.sorted()
    }
}
