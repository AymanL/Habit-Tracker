//
//  HabitApp.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import SwiftUI
import CoreData
import BackgroundTasks
import UserNotifications

@main
struct HabitApp: App {
    let dataController = DataController.shared
    private let backgroundTaskIdentifier = "com.ayman.habit.weeklyexport"
    
    init() {
        registerBackgroundTasks()
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            handleWeeklyExport(task: task as! BGProcessingTask)
        }
    }
    
    private func handleWeeklyExport(task: BGProcessingTask) {
        // Schedule the next export
        scheduleNextWeeklyExport()
        
        // Create a task expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the export
        let habits = dataController.getAllHabits()
        
        // Create export data
        let habitsData = habits.map { habit -> [String: Any] in
            [
                "id": habit.id.uuidString,
                "title": habit.title,
                "motivation": habit.motivation,
                "color": habit.color.rawValue,
                "type": habit.type.rawValue,
                "isWeekly": habit.isWeekly,
                "creationDate": habit.creationDate.timeIntervalSince1970,
                "completedDates": habit.completedDates.map { $0.timeIntervalSince1970 },
                "dailyCounters": Dictionary(uniqueKeysWithValues: habit.dailyCounters.map { 
                    (String($0.key.timeIntervalSince1970), $0.value)
                }),
                "durationHistory": habit.durationHistory.map { duration in
                    [
                        "minutes": duration.minutes,
                        "effectiveDate": duration.effectiveDate.timeIntervalSince1970,
                        "expirationDate": duration.expirationDate?.timeIntervalSince1970
                    ]
                }
            ]
        }
        
        let exportData: [String: Any] = [
            "version": "1.0",
            "exportDate": Date().timeIntervalSince1970,
            "habits": habitsData
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "habits-\(dateString).json"
            
            // Create a temporary file with the .json extension
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent(fileName)
            try jsonData.write(to: tempFile)
            
            // Send notification
            let content = UNMutableNotificationContent()
            content.title = "Weekly Habit Export"
            content.body = "Your habits have been automatically exported."
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            
            task.setTaskCompleted(success: true)
        } catch {
            print("Error in background export: \(error)")
            task.setTaskCompleted(success: false)
        }
    }
    
    private func scheduleNextWeeklyExport() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule weekly export: \(error)")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    static func exportHabitsNow() {
        let dataController = DataController.shared
        let habits = dataController.getAllHabits()
        
        // Create export data
        let habitsData = habits.map { habit -> [String: Any] in
            [
                "id": habit.id.uuidString,
                "title": habit.title,
                "motivation": habit.motivation,
                "color": habit.color.rawValue,
                "type": habit.type.rawValue,
                "isWeekly": habit.isWeekly,
                "creationDate": habit.creationDate.timeIntervalSince1970,
                "completedDates": habit.completedDates.map { $0.timeIntervalSince1970 },
                "dailyCounters": Dictionary(uniqueKeysWithValues: habit.dailyCounters.map { 
                    (String($0.key.timeIntervalSince1970), $0.value)
                }),
                "durationHistory": habit.durationHistory.map { duration in
                    [
                        "minutes": duration.minutes,
                        "effectiveDate": duration.effectiveDate.timeIntervalSince1970,
                        "expirationDate": duration.expirationDate?.timeIntervalSince1970
                    ]
                }
            ]
        }
        
        let exportData: [String: Any] = [
            "version": "1.0",
            "exportDate": Date().timeIntervalSince1970,
            "habits": habitsData
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "habits-\(dateString).json"
            
            // Create a temporary file with the .json extension
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent(fileName)
            try jsonData.write(to: tempFile)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [tempFile],
                applicationActivities: nil
            )
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error in export: \(error)")
        }
    }
}
