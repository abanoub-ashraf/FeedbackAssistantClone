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
        .toolbar {
            Menu {
                Button(dataController.filterEnabled ? "Turn Filter Off" : "Turn Filter On") {
                    dataController.filterEnabled.toggle()
                }
                
                Divider()
                
                Menu("Sort By") {
                    Picker("Sort By", selection: $dataController.sortType) {
                        Text("Date Created").tag(SortType.dateCreated)
                        Text("Date Modified").tag(SortType.dateModified)
                    }
                    
                    Divider()
                    
                    Picker("Sort Order", selection: $dataController.sortNewestFirst) {
                        Text("Newest to Oldest").tag(true)
                        Text("Oldest to Newest").tag(false)
                    }
                }
                
                Picker("Status", selection: $dataController.filterStatus) {
                    Text("All").tag(Status.all)
                    Text("Open").tag(Status.open)
                    Text("Closed").tag(Status.closed)
                }
                .disabled(dataController.filterEnabled == false)
                
                Picker("Priority", selection: $dataController.filterPriority) {
                    Text("All").tag(-1)
                    Text("Low").tag(0)
                    Text("Medium").tag(1)
                    Text("High").tag(2)
                }
                .disabled(dataController.filterEnabled == false)
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    .symbolVariant(dataController.filterEnabled ? .fill : .none)
            }
        }
    }
}
