import SwiftUI
import CoreData

@main
struct commute_proApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CommuteListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
} 