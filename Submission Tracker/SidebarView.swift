//
//  Untitled.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI


struct SidebarView: View {
    @Binding var selection: NavigationItem?
    
    var body: some View {
        List(selection: $selection) {
            ForEach([NavigationItem.today, NavigationItem.history, NavigationItem.statistics, NavigationItem.reminders]) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
//            Divider()
            NavigationLink(value: NavigationItem.fullHistory) {
                Label(NavigationItem.fullHistory.rawValue, systemImage: NavigationItem.fullHistory.icon)
            }
        }
        .navigationTitle("Tracker")
    }
}
