import SwiftUI
import CoreData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportURL: URL?
    @State private var isShowingShareSheet = false
    @State private var isShowingImportPicker = false
    @State private var showingImportError = false
    @State private var showingImportSuccess = false
    @State private var importErrorMessage = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportProgress = ""
    @State private var importProgress = ""
    @EnvironmentObject var dataController: DataController
    @State private var minimumLoadingTime: TimeInterval = 1.5 // Minimum time to show loader
    
    var body: some View {
            ZStack {
                List {
                    Section {
                        Button {
                            print("DEBUG: Export Habits button tapped")
                            exportAllHabits { success in
                                print("DEBUG: Export completion handler called with success: \(success)")
                                if success {
                                    print("DEBUG: Setting isShowingShareSheet to true")
                                    isShowingShareSheet = true
                                }
                            }
                        } label: {
                            Label("Export Habits", systemImage: "square.and.arrow.up")
                        }
                        .disabled(isExporting || isImporting)
                        
                        Button {
                            isShowingImportPicker = true
                        } label: {
                            Label("Import Habits", systemImage: "square.and.arrow.down")
                        }
                        .disabled(isExporting || isImporting)
                    } header: {
                        Text("Data Management")
                    }                     footer: {
                        Text("Export your habits to back them up or transfer them to another device. Import previously exported habits to restore your data.")
                    }
                    
                    HiddenHabitsSection()
                    
                    NotificationSettingsSection()
                }
                
                if isExporting || isImporting {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text(isExporting ? exportProgress : importProgress)
                            .foregroundColor(.white)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $isShowingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                        .ignoresSafeArea()
                        .onDisappear {
                            isShowingShareSheet = false
                        }
                }
            }

        }

    private func exportAllHabits(completion: ((Bool) -> Void)? = nil) {
        print("DEBUG: Starting exportAllHabits")
        let startTime = Date()
        isExporting = true
        
        // Show initial message
        exportProgress = "Preparing export..."
        print("DEBUG: \(exportProgress)")
        
        // Use async to not block the UI
        DispatchQueue.global(qos: .userInitiated).async {
            // Add a small delay to ensure the first message is visible
            Thread.sleep(forTimeInterval: 0.5)
            
            let habits = dataController.getAllHabits()
            print("DEBUG: Found \(habits.count) habits to export")
            
            DispatchQueue.main.async {
                exportProgress = "Processing \(habits.count) habits..."
                print("DEBUG: \(exportProgress)")
            }
            
            // Add a small delay to ensure the second message is visible
            Thread.sleep(forTimeInterval: 0.5)
            
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
                
                let tempDir = FileManager.default.temporaryDirectory
                let tempFile = tempDir.appendingPathComponent(fileName)
                
                DispatchQueue.main.async {
                    exportProgress = "Writing file..."
                    print("DEBUG: \(exportProgress)")
                }
                
                // Add a small delay to ensure the third message is visible
                Thread.sleep(forTimeInterval: 0.5)
                
                try jsonData.write(to: tempFile)
                print("DEBUG: Successfully wrote export file to: \(tempFile.path)")
                
                // Calculate remaining time to meet minimum display duration
                let elapsedTime = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, minimumLoadingTime - elapsedTime)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    print("DEBUG: Setting exportURL to: \(tempFile.path)")
                    self.exportURL = tempFile
                    self.isExporting = false
                    print("DEBUG: Calling completion handler with success")
                    completion?(true)
                    
                    // Present share sheet using UIKit
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        print("DEBUG: Found root view controller, presenting share sheet")
                        let activityVC = UIActivityViewController(activityItems: [tempFile], applicationActivities: nil)
                        activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
                            print("DEBUG: Share sheet completed - Activity: \(String(describing: activityType)), Completed: \(completed), Error: \(String(describing: error))")
                        }
                        
                        // Present on iPad
                        if let popoverController = activityVC.popoverPresentationController {
                            popoverController.sourceView = rootViewController.view
                            popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                            popoverController.permittedArrowDirections = []
                        }
                        
                        rootViewController.present(activityVC, animated: true) {
                            print("DEBUG: Share sheet presentation completed")
                        }
                    } else {
                        print("DEBUG: Could not find root view controller")
                    }
                }
            } catch {
                print("DEBUG: Error in export: \(error)")
                DispatchQueue.main.async {
                    self.isExporting = false
                    completion?(false)
                }
            }
        }
    }
}

struct HiddenHabitsSection: View {
    @EnvironmentObject var dataController: DataController
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "order_", ascending: true)],
        predicate: NSPredicate(format: "isHidden_ == %@", NSNumber(value: true))
    ) var hiddenHabits: FetchedResults<Habit>
    
    var body: some View {
        Section {
            ForEach(hiddenHabits) { habit in
                HStack {
                    Circle()
                        .fill(Color(habit.color))
                        .frame(width: 12, height: 12)
                    Text(habit.title)
                    Spacer()
                    Button("Unhide") {
                        habit.setValue(false, forKey: "isHidden_")
                        try? dataController.container.viewContext.save()
                    }
                    .buttonStyle(.bordered)
                }
            }
        } header: {
            Text("Hidden Habits")
        } footer: {
            Text("Hidden habits are not shown in the main list but can be restored here.")
        }
    }
}

struct NotificationSettingsSection: View {
    @State private var reminderTime: Date
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @State private var showingPermissionAlert = false
    
    init() {
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date ?? defaultTime
        _reminderTime = State(initialValue: savedTime)
    }
    
    var body: some View {
        Section {
            Toggle("Daily Reminder", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { newValue in
                    if newValue {
                        requestNotificationPermission()
                    } else {
                        cancelDailyReminder()
                    }
                }
            
            if reminderEnabled {
                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { _ in
                        if reminderEnabled {
                            scheduleDailyReminder()
                        }
                    }
                
                Button("Check Permissions") {
                    checkNotificationPermission()
                }
                .buttonStyle(.bordered)
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Set a daily reminder to help you stay on track with your habits.")
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings", role: .none) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive daily reminders.")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    scheduleDailyReminder()
                } else {
                    reminderEnabled = false
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Time to check in on your habits!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status = settings.authorizationStatus
                print("Notification permission status: \(status.rawValue)")
            }
        }
    }
}

 
