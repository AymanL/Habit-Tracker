//
//  HabitApp.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import SwiftUI
import CoreData

@main
struct HabitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
}
