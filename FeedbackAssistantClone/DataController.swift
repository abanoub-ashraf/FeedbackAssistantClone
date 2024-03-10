//
//  DataController.swift
//  FeedbackAssistantClone
//
//  Created by Abanoub Ashraf on 10/02/2024.
//

import CoreData

///
/// how to sort the data
///
enum SortType: String {
    case dateCreated = "creationDate"
    case dateModified = "modificationDate"
}

enum Status {
    case all, open, closed
}

class DataController: ObservableObject {
    let container: NSPersistentContainer
    
    @Published var selectedFilter: Filter? = Filter.all
    @Published var selectedIssue: Issue?
    @Published var filterText = ""
    @Published var filterTokens = [Tag]()
    @Published var filterEnabled = false
    @Published var filterPriority = -1
    @Published var filterStatus = Status.all
    @Published var sortType = SortType.dateCreated
    @Published var sortNewestFirst = true
    
    ///
    /// get all the tags that their name start with what the user typing in filterText
    ///
    var suggestedFilterTokens: [Tag] {
        guard filterText.starts(with: "#") else {
            return []
        }
        
        let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)
        let request = Tag.fetchRequest()
        
        if trimmedFilterText.isEmpty == false {
            request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
        }
        
        return (try? container.viewContext.fetch(request).sorted()) ?? []
    }
    
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
    
    ///
    /// if we have a selected filter from SidebarView then get the issues from its tag
    /// otherwise then fetch the issues that was added recently
    ///
    func issuesForSelectedFilter() -> [Issue] {
        let filter = selectedFilter ?? .all
        var predicates = [NSPredicate]()
        
        if let tag = filter.tag {
            ///
            /// get the issues of this tag if a tag is selected from the sidebar
            ///
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            let datePredicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
            predicates.append(datePredicate)
        }
        
        ///
        /// - searching predicates
        ///
        /// - CONTAINS[c] this means case insensitive search
        ///
        let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)
        
        if trimmedFilterText.isEmpty == false {
            let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
            let contentPredicate = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
            ///
            /// this compound predicate has one of its sub predicates is true not both
            ///
            let combinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
            predicates.append(combinedPredicate)
        }
        
        ///
        /// once this storage filterTokens is filled automatically from what the user choose from the ui from the suggestedFilterTokens
        /// loop through them and include the predicate that include the name of each tag
        ///
        if filterTokens.isEmpty == false {
            for filterToken in filterTokens {
                let tokenPredicate = NSPredicate(format: "tags CONTAINS %@", filterToken)
                predicates.append(tokenPredicate)
            }
        }
        
        if filterEnabled {
            if filterPriority >= 0 {
                let priorityFilter = NSPredicate(format: "priority = %d", filterPriority)
                predicates.append(priorityFilter)
            }
            
            if filterStatus != .all {
                let lookForClosed = filterStatus == .closed
                let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
                predicates.append(statusFilter)
            }
        }
        
        let request = Issue.fetchRequest()
        ///
        /// use all predicates in one predicate, all of them must be true
        ///
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.sortDescriptors = [
            NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)
        ]
        
        let allIssues = (try? container.viewContext.fetch(request)) ?? []
        return allIssues.sorted()
    }
    
    func newIssue() {
        let issue = Issue(context: container.viewContext)
        issue.title = "New Issue"
        issue.creationDate = .now
        issue.priority = 1
        
        ///
        /// if currently there's a filter selected then add its tag to the tags of the new issue
        ///
        if let tag = selectedFilter?.tag {
            issue.addToTags(tag)
        }
        
        save()
        
        ///
        /// assign the new issue to be the selected one so it trigger a ui update
        /// that makes that issue display to the user immediately
        ///
        selectedIssue = issue
    }
    
    func newTag() {
        let tag = Tag(context: container.viewContext)
        tag.id = UUID()
        tag.name = "New Tag"
        
        save()
    }
}
