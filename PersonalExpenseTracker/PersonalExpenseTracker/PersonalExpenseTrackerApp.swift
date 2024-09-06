//
//  PersonalExpenseTrackerApp.swift
//  PersonalExpenseTracker
//
//  Created by shreya on 8/1/24.
//

import SwiftUI

@main
struct PersonalExpenseTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
