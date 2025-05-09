//
//  ContentView.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import SwiftUI
import CoreData
import UserNotifications
import BackgroundTasks

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
    @AppStorage("autoExportEnabled") private var autoExportEnabled = false
    @AppStorage("autoExportEmail") private var autoExportEmail = ""
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
                    
                    Section {
                        Toggle("Automatic Weekly Export", isOn: $autoExportEnabled)
                            .onChange(of: autoExportEnabled) { newValue in
                                if newValue {
                                    requestNotificationPermission()
                                    scheduleWeeklyExport()
                                }
                            }
                        
                        if autoExportEnabled {
                            TextField("Email for Export", text: $autoExportEmail)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    } header: {
                        Text("Automatic Export")
                    } footer: {
                        if autoExportEnabled {
                            Text("Your habits will be automatically exported every Monday and sent to your email.")
                        }
                    }
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
            .onAppear {
                if autoExportEnabled {
                    requestNotificationPermission()
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleWeeklyExport() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Habit Export"
        content.body = "Your habits have been automatically exported and sent to your email."
        content.sound = .default
        
        // Create a date components for Monday at 9:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyExport", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
        
        // Schedule the background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.weeklyexport", using: nil) { task in
            self.handleWeeklyExport(task: task as! BGProcessingTask)
        }
        
        scheduleNextWeeklyExport()
    }
    
    private func scheduleNextWeeklyExport() {
        let request = BGProcessingTaskRequest(identifier: "com.yourapp.weeklyexport")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule weekly export: \(error)")
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
        exportAllHabits { success in
            if success {
                // Send email if configured
                if !autoExportEmail.isEmpty {
                    sendExportEmail()
                }
                
                // Schedule notification
                let content = UNMutableNotificationContent()
                content.title = "Weekly Habit Export"
                content.body = "Your habits have been automatically exported and sent to your email."
                content.sound = .default
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
            }
            
            task.setTaskCompleted(success: success)
        }
    }
    
    private func sendExportEmail() {
        guard let url = exportURL else { return }
        
        let mailtoUrl = URL(string: "mailto:\(autoExportEmail)?subject=Weekly%20Habit%20Export&body=Your%20weekly%20habit%20export%20is%20attached.")!
        
        if UIApplication.shared.canOpenURL(mailtoUrl) {
            UIApplication.shared.open(mailtoUrl)
        }
    }
    
    private func exportAllHabits(completion: ((Bool) -> Void)? = nil) {
        isExporting = true
        exportProgress = "Preparing export..."
        
        // Use async to not block the UI
        DispatchQueue.global(qos: .userInitiated).async {
            let habits = dataController.getAllHabits()
            
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
                            "expirationDate": duration.expirationDate?.timeIntervalSince1970
                        ]
                    }
                ]
            }
            
            DispatchQueue.main.async {
                exportProgress = "Creating export file..."
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
                
                DispatchQueue.main.async {
                    self.exportURL = tempFile
                    self.isExporting = false
                    if completion == nil {
                        self.isShowingShareSheet = true
                    }
                    completion?(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.importErrorMessage = "Error exporting habits: \(error.localizedDescription)"
                    self.showingImportError = true
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

struct ContentView: View {
    @State private var isPresentingEditHabitView = false
    @State private var isPresentingSettingsView = false
    @AppStorage("sortingOption") private var sortingOption: SortingOption = .byOrder
    @AppStorage("isSortingOrderDescending") private var isSortingOrderAscending = false
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Divider()
                HeaderView()
                HabitListView(sortingOption: sortingOption, isSortingOrderAscending: isSortingOrderAscending)
            }
            .toolbar {
                addHabitToolbarItem
                sortMenuToolbarItem
                settingsToolbarItem
            }
            .sheet(isPresented: $isPresentingEditHabitView) {
                EditHabitView(habit: nil)
            }
            .sheet(isPresented: $isPresentingSettingsView) {
                SettingsView()
            }
        }
    }
    
    var addHabitToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isPresentingEditHabitView = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19).weight(.light))
                    .tint(.primary)
            }
            .accessibilityLabel("Add Habit")
            .accessibilityIdentifier("addHabit")
        }
    }
    
    var sortMenuToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            SortMenuView(selectedSortingOption: $sortingOption, isSortingOrderAscending: $isSortingOrderAscending)
                .tint(.primary)
        }
    }
    
    var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isPresentingSettingsView = true
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 19).weight(.light))
                    .tint(.primary)
            }
            .accessibilityLabel("Settings")
        }
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
