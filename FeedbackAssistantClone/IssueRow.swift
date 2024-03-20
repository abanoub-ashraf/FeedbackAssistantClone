//
//  IssueRow.swift
//  FeedbackAssistantClone
//
//  Created by Abanoub Ashraf on 24/02/2024.
//

import SwiftUI

struct IssueRow: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue
    
    var body: some View {
        NavigationLink(value: issue) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .imageScale(.large)
                    .opacity(issue.priority == 2 ? 1 : 0)
                
                VStack(alignment: .leading) {
                    Text(issue.issueTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(issue.issueTagsList)
                        .foregroundStyle(.secondary)
                        ///
                		/// this means it will take height of 2 lines even if the text is only one line
                		///
                        .lineLimit(2...2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(issue.issueCreationDate.formatted(date: .numeric, time: .omitted))
                        .accessibilityLabel(
                            issue.issueCreationDate.formatted(date: .abbreviated, time: .omitted)
                        )
                        .font(.subheadline)
                    
                    if issue.completed {
                        Text("CLOSED")
                            .font(.body.smallCaps())
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityHint(issue.priority == 2 ? "High priority" : "")
    }
}

#Preview {
    IssueRow(issue: .example)
}
