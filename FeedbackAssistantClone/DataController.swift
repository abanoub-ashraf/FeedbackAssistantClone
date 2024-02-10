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
    
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()
    
    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: "Main")
        
        if inMemory {
            ///
            /// if in meomry then this is either for testing or for swiftui preview
            ///
            self.container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        ///
        /// this is the data base, the long term storage
        ///
        self.container.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
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
        /// this method save the chagnes happened to the objects in ram on the presistance store
        ///
        try? viewContext.save()
    }
    
    func save() {
        ///
        /// only save when there's uncommited changes
        ///
        if self.container.viewContext.hasChanges {
            try? self.container.viewContext.save()
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
}
