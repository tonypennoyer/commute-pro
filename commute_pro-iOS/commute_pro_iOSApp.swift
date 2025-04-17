//
//  commute_pro_iOSApp.swift
//  commute_pro-iOS
//
//  Created by Tony Pennoyer on 4/16/25.
//

import SwiftUI

struct CommutePro_iOSApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct CommutePro_iOSAppMain {
    static func main() {
        CommutePro_iOSApp.main()
    }
}
