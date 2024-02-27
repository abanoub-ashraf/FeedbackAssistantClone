//
//  ContentView.swift
//  FeedbackAssistantClone
//
//  Created by Abanoub Ashraf on 10/02/2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    
    func delete(_ offsets: IndexSet) {
        let issues = dataController.issuesForSelectedFilter()
        
        for offset in offsets {
            let item = issues[offset]
            dataController.delete(item)
        }
    }
    
    var body: some View {
        List(selection: $dataController.selectedIssue) {
            ForEach(dataController.issuesForSelectedFilter()) { issue in
                IssueRow(issue: issue)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Issues")
        .searchable(
            ///
            /// the search keyword the user is typing that will get in dataController
            /// and fill the suggestedFilterTokens
            ///
            text: $dataController.filterText,
            ///
            /// this is a storage to store the tags the user selected from suggestedFilterTokens
            /// and they will be displayed on the search bar
            ///
            tokens: $dataController.filterTokens,
            ///
            /// this is the list of tags that will be displayed in the ui after the user typing # then the name of the tags they want to filter with or searching for
            ///
            suggestedTokens: .constant(dataController.suggestedFilterTokens),
            ///
            /// the placeholder for the search bar
            ///
            prompt: "Filter issues, or type # to add tags"
        ) { tag in
            ///
            /// this is the suggestedFilterTokens
            ///
            Text(tag.tagName)
        }
    }
}
