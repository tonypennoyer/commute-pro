//
//  commute_proApp.swift
//  commute_pro
//
//  Created by Tony Pennoyer on 4/15/25.
//

import SwiftUI
import CoreData

@main
struct CommuteProApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CommuteListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
