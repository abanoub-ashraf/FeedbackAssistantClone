//
//  NoIssueView.swift
//  FeedbackAssistantClone
//
//  Created by Abanoub Ashraf on 25/02/2024.
//

import SwiftUI

struct NoIssueView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        Text("No issue selected")
            .font(.title)
            .foregroundStyle(.secondary)
        
        Button("New Issue", action: dataController.newIssue)
    }
}

#Preview {
    NoIssueView()
}
