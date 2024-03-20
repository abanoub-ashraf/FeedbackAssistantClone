//
//  Filter.swift
//  FeedbackAssistantClone
//
//  Created by Abanoub Ashraf on 10/02/2024.
//

import Foundation

///
/// Hashable for the selection binding in swiftui
///
struct Filter: Identifiable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var minModificationDate = Date.distantPast
    var tag: Tag?
    
    var activeIssuesCount: Int {
        tag?.tagActiveIssues.count ?? 0
    }
    
    static var all = Filter(
        id: UUID(),
        name: "All Issues",
        icon: "tray"
    )
    
    static var recent = Filter(
        id: UUID(),
        name: "Recent Issues", 
        icon: "clock",
        ///
        /// go back 7 days
        ///
        minModificationDate: .now.addingTimeInterval(86400 * -7)
    )
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: Filter, rhs: Filter) -> Bool {
        lhs.id == rhs.id
    }
}
