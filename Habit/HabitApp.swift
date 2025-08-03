//
//  HabitApp.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct HabitApp: App {
    let dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Clear all notifications when app becomes active
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                    
                    // Clear the app badge
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
        }
    }
}
