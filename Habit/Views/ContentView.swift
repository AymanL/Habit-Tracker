//
//  ContentView.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

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
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section {
                        Button {
                            exportAllHabits()
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
                    } footer: {
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
                        Text(isExporting ? exportProgress : importProgress)
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $isShowingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    guard let selectedFile = files.first else { return }
                    
                    isImporting = true
                    importProgress = "Reading import file..."
                    
                    // Use async to not block the UI
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            // Start accessing the security-scoped resource
                            guard selectedFile.startAccessingSecurityScopedResource() else {
                                DispatchQueue.main.async {
                                    importErrorMessage = "Permission denied to access the file"
                                    showingImportError = true
                                    isImporting = false
                                }
                                return
                            }
                            
                            defer {
                                // Make sure we release the security-scoped resource when finished
                                selectedFile.stopAccessingSecurityScopedResource()
                            }
                            
                            let data = try Data(contentsOf: selectedFile)
                            
                            DispatchQueue.main.async {
                                importProgress = "Processing imported data..."
                            }
                            
                            try importData(from: data)
                            
                            DispatchQueue.main.async {
                                isImporting = false
                                showingImportSuccess = true
                            }
                        } catch {
                            DispatchQueue.main.async {
                                importErrorMessage = "Error reading file: \(error.localizedDescription)"
                                showingImportError = true
                                isImporting = false
                            }
                        }
                    }
                    
                case .failure(let error):
                    importErrorMessage = "Error selecting file: \(error.localizedDescription)"
                    showingImportError = true
                }
            }
            .alert("Import Error", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importErrorMessage)
            }
            .alert("Import Successful", isPresented: $showingImportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your habits have been successfully imported.")
            }

        }
    }
    

    

    
    private func exportAllHabits(completion: ((Bool) -> Void)? = nil) {
        print("Starting exportAllHabits")
        isExporting = true
        exportProgress = "Preparing export..."
        
        // Use async to not block the UI
        DispatchQueue.global(qos: .userInitiated).async {
            let habits = dataController.getAllHabits()
            print("Found \(habits.count) habits to export")
            
            DispatchQueue.main.async {
                exportProgress = "Processing \(habits.count) habits..."
            }
            
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
                            "expirationDate": duration.expirationDate?.timeIntervalSince1970 as Any
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
                try jsonData.write(to: tempFile)
                print("Successfully wrote export file to: \(tempFile.path)")
                
                DispatchQueue.main.async {
                    self.exportURL = tempFile
                    self.isExporting = false
                    self.isShowingShareSheet = true
                    print("Export completed, calling completion handler")
                    completion?(true)
                }
            } catch {
                print("Error in export: \(error)")
                DispatchQueue.main.async {
                    self.isExporting = false
                    completion?(false)
                }
            }
        }
    }
    
    private func importData(from data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let habitsData = json["habits"] as? [[String: Any]] else {
            throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid file format"])
        }
        
        // Delete existing habits
        dataController.deleteAll()
        
        // Import new habits
        for habitData in habitsData {
            guard let id = habitData["id"] as? String,
                  let title = habitData["title"] as? String,
                  let motivation = habitData["motivation"] as? String,
                  let colorRaw = habitData["color"] as? String,
                  let typeRaw = habitData["type"] as? String,
                  let isWeekly = habitData["isWeekly"] as? Bool,
                  let creationDateTimestamp = habitData["creationDate"] as? TimeInterval,
                  let completedDatesTimestamps = habitData["completedDates"] as? [TimeInterval],
                  let dailyCountersData = habitData["dailyCounters"] as? [String: Int],
                  let durationHistoryData = habitData["durationHistory"] as? [[String: Any]] else {
                continue
            }
            
            let habit = Habit(context: dataController.container.viewContext)
            habit.id = UUID(uuidString: id) ?? UUID()
            habit.title = title
            habit.motivation = motivation
            habit.color = HabitColor(rawValue: colorRaw) ?? .blue
            habit.type = Habit.HabitType(rawValue: typeRaw) ?? .counter
            habit.isWeekly = isWeekly
            habit.creationDate = Date(timeIntervalSince1970: creationDateTimestamp)
            
            // Convert timestamps back to dates
            habit.completedDates = completedDatesTimestamps.map { Date(timeIntervalSince1970: $0) }
            
            // Convert daily counters
            var dailyCounters: [Date: Int] = [:]
            for (timestampStr, value) in dailyCountersData {
                if let timestamp = Double(timestampStr) {
                    dailyCounters[Date(timeIntervalSince1970: timestamp)] = value
                }
            }
            habit.dailyCounters = dailyCounters
            
            // Convert duration history
            var durationHistory: [HabitDuration] = []
            for durationData in durationHistoryData {
                guard let minutes = durationData["minutes"] as? Int,
                      let effectiveDateTimestamp = durationData["effectiveDate"] as? TimeInterval else {
                    continue
                }
                
                let effectiveDate = Date(timeIntervalSince1970: effectiveDateTimestamp)
                let expirationDate = (durationData["expirationDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
                
                durationHistory.append(HabitDuration(
                    minutes: minutes,
                    effectiveDate: effectiveDate,
                    expirationDate: expirationDate
                ))
            }
            habit.durationHistory = durationHistory
        }
        
        try dataController.container.viewContext.save()
    }
}

struct NotificationSettingsSection: View {
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("dayResetHour") private var dayResetHour: Int = 0 // 0 = midnight (default)
    @State private var dailyReminderTime: Date
    @State private var showingPermissionAlert = false
    
    init() {
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        let savedTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date ?? defaultTime
        _dailyReminderTime = State(initialValue: savedTime)
    }
    
    var body: some View {
        Section {
            Toggle("Daily Reminder", isOn: $dailyReminderEnabled)
                .onChange(of: dailyReminderEnabled) { newValue in
                    if newValue {
                        requestNotificationPermission()
                    } else {
                        cancelDailyReminder()
                    }
                }
            
            if dailyReminderEnabled {
                DatePicker("Reminder Time", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: dailyReminderTime) { newTime in
                        UserDefaults.standard.set(newTime, forKey: "dailyReminderTime")
                        if dailyReminderEnabled {
                            self.scheduleDailyReminder(at: newTime)
                        }
                    }
            }
            
            HStack {
                Text("Day Reset Time")
                Spacer()
                Picker("Day Reset Time", selection: $dayResetHour) {
                    Text("Midnight (12 AM)").tag(0)
                    Text("1 AM").tag(1)
                    Text("2 AM").tag(2)
                    Text("3 AM").tag(3)
                    Text("4 AM").tag(4)
                    Text("5 AM").tag(5)
                    Text("6 AM").tag(6)
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("Notifications")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Receive a daily reminder to check and complete your habits.")
                Text("Choose when your day resets - for example, if you set it to 4 AM, then habits completed at 3 AM on Saturday will count towards Friday.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dailyReminderEnabled = false
            }
        } message: {
            Text("Please enable notifications in Settings to receive daily reminders.")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                                            self.scheduleDailyReminder(at: dailyReminderTime)
                } else {
                    print("❌ Notification permission denied")
                    showingPermissionAlert = true
                }
            }
        }
    }
    

    

    
    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleDailyReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time for Habits!"
        content.body = "Don't forget to check and complete your daily habits."
        content.sound = .default
        
        // Create date components for the specified time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "dailyHabitReminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        center.add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error)")
            }
        }
    }
    

}

struct HiddenHabitsSection: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.order_, ascending: true)],
        predicate: NSPredicate(format: "isHidden_ == YES"),
        animation: .default)
    private var hiddenHabits: FetchedResults<Habit>
    
    var body: some View {
        Section {
            if hiddenHabits.isEmpty {
                HStack {
                    Image(systemName: "eye.slash")
                        .foregroundColor(.secondary)
                    Text("No Hidden Habits")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ForEach(hiddenHabits) { habit in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(habit.title)
                                .font(.headline)
                            Text(habit.motivation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            habit.setValue(false, forKey: "isHidden_")
                            try? viewContext.save()
                        }) {
                            Image(systemName: "eye")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } header: {
            Text("Hidden Habits")
        } footer: {
            Text("Hidden habits are not shown in the main list but retain all their data and progress.")
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddHabit = false
    @State private var showingCategories = false
    @State private var isPresentingSettingsView = false
    @Environment(\.scenePhase) var scenePhase

    @State private var exportURL: URL?
    @AppStorage("sortingOption") private var sortingOption: SortingOption = .byOrder
    @AppStorage("isSortingOrderAscending") private var isSortingOrderAscending = false
    @State private var currentDate = Date()
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Divider()
                HeaderView()
                HabitListView(sortingOption: sortingOption, isSortingOrderAscending: isSortingOrderAscending)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { sortingOption = .byDate }) {
                            Label("Sort by Date", systemImage: "calendar")
                        }
                        Button(action: { sortingOption = .byName }) {
                            Label("Sort by Name", systemImage: "textformat")
                        }
                        Button(action: { sortingOption = .byOrder }) {
                            Label("Sort by Order", systemImage: "arrow.up.arrow.down")
                        }
                        
                        Divider()
                        
                        Button(action: { isSortingOrderAscending.toggle() }) {
                            Label(isSortingOrderAscending ? "Sort Descending" : "Sort Ascending",
                                  systemImage: isSortingOrderAscending ? "arrow.down" : "arrow.up")
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingCategories = true }) {
                            Label("Categories", systemImage: "folder")
                        }
                        
                        Button(action: { showingAddHabit = true }) {
                            Label("Add Habit", systemImage: "plus")
                        }
                        
                        Button(action: { isPresentingSettingsView = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                NavigationView {
                    EditHabitView()
                }
            }
            .sheet(isPresented: $showingCategories) {
                NavigationView {
                    CategoryListView()
                }
            }
            .sheet(isPresented: $isPresentingSettingsView) {
                SettingsView()
            }
            .onAppear {
                startDateRefreshTimer()
                checkNotificationSettings()
            }
            .onDisappear {
                stopDateRefreshTimer()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    // Refresh the current date when app becomes active
                    currentDate = Date()
                }
            }
        }
    }
    
    private func startDateRefreshTimer() {
        // Stop any existing timer
        stopDateRefreshTimer()
        
        // Create a timer that fires every minute to check for day changes
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let newDate = Date()
            let calendar = Calendar.current
            
            // Check if the day has changed
            if !calendar.isDate(currentDate, inSameDayAs: newDate) {
                currentDate = newDate
                // Force UI refresh by updating the environment
                dataController.objectWillChange.send()
            }
        }
    }
    
    private func stopDateRefreshTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkNotificationSettings() {
        // Note: Notification scheduling is now handled within NotificationSettingsSection
        // This function is kept for potential future use
    }
    

    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iPhone 14 Pro Max")
            .environment(\.locale, .init(identifier: "uk"))
        
        ContentView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
