//
//  ContentView.swift
//  Expense-tracker
//
//  Created by Ankit bansal on 08/01/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    let container = PersistenceController.makeModelContainer(inMemory: true)
    return ContentView()
        .environment(AppState())
        .modelContainer(container)
}
