//
//  Issue-CoreDataHelpers.swift
//  FeedbackAssistantClone
//
//  Created by Abanoub Ashraf on 18/02/2024.
//

import Foundation

extension Issue {
    var issueTitle: String {
        get { title ?? "" }
        set { title = newValue }
    }
    
    var issueContent: String {
        get { content ?? "" }
        set { content = newValue }
    }
    
    var issueCreationDate: Date {
        creationDate ?? .now
    }
    
    var issueModificationDate: Date {
        modificationDate ?? .now
    }
    
    var issueTags: [Tag] {
        let results = tags?.allObjects as? [Tag] ?? []
        return results.sorted()
    }
    
    static var example: Issue {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let issue = Issue(context: viewContext)
        issue.title = "Example Issue"
        issue.content = "This is an example issue"
        issue.priority = 2
        issue.creationDate = .now
        return issue
    }
}

extension Issue: Comparable {
    public static func <(lhs: Issue, rhs: Issue) -> Bool {
        let left = lhs.issueTitle.localizedLowercase
        let right = rhs.issueTitle.localizedLowercase
        
        if left == right {
            return lhs.issueCreationDate < rhs.issueCreationDate
        } else {
            return left < right
        }
    }
}
