//
//  commute_proApp.swift
//  commute_pro
//
//  Created by Tony Pennoyer on 4/15/25.
//

import SwiftUI

@main
struct commute_proApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
