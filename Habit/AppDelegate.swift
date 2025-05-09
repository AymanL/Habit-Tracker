import UIKit
import BackgroundTasks
import UserNotifications

public class AppDelegate: NSObject, UIApplicationDelegate {
    private let backgroundTaskIdentifier = "com.ayman.habit.weeklyexport"
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        registerBackgroundTasks()
        requestNotificationPermission()
        return true
    }
    
    public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    public func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Handle discarded scenes if needed
    }
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleWeeklyExport(task: task as! BGProcessingTask)
        }
    }
    
    func handleWeeklyExport(task: BGProcessingTask) {
        // Schedule the next export
        scheduleNextWeeklyExport()
        
        // Create a task expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the export
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
    
    func scheduleNextWeeklyExport() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule weekly export: \(error)")
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
} 