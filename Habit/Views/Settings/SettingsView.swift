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
                            exportAllHabits { success in
                                if success {
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
                    
                    CustomDayResetSection()
                    
                    HolidaySettingsSection()
                    
                    #if DEBUG
                    SkillTreeDebugSection()
                    #endif
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
        let startTime = Date()
        isExporting = true
        
        // Show initial message
        exportProgress = "Preparing export..."
        
        // Use async to not block the UI
        DispatchQueue.global(qos: .userInitiated).async {
            // Add a small delay to ensure the first message is visible
            Thread.sleep(forTimeInterval: 0.5)
            
            let habits = dataController.getAllHabits()
            
            DispatchQueue.main.async {
                exportProgress = "Processing \(habits.count) habits..."
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
                    "duration": habit.currentDuration,
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
                "version": "1.4.2",
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
                }
                
                // Add a small delay to ensure the third message is visible
                Thread.sleep(forTimeInterval: 0.5)
                
                try jsonData.write(to: tempFile)
                
                // Calculate remaining time to meet minimum display duration
                let elapsedTime = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, minimumLoadingTime - elapsedTime)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    self.exportURL = tempFile
                    self.isExporting = false
                    completion?(true)
                    
                    // Present share sheet using UIKit
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        let activityVC = UIActivityViewController(activityItems: [tempFile], applicationActivities: nil)
                        
                        // Present on iPad
                        if let popoverController = activityVC.popoverPresentationController {
                            popoverController.sourceView = rootViewController.view
                            popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                            popoverController.permittedArrowDirections = []
                        }
                        
                        rootViewController.present(activityVC, animated: true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    completion?(false)
                }
            }
        }
    }
}

struct CustomDayResetSection: View {
    @AppStorage("dayResetHour") private var dayResetHour: Int = 0
    
    var body: some View {
        Section {
            Picker("Day Reset Hour", selection: $dayResetHour) {
                Text("Midnight (12 AM)").tag(0)
                Text("1 AM").tag(1)
                Text("2 AM").tag(2)
                Text("3 AM").tag(3)
                Text("4 AM").tag(4)
                Text("5 AM").tag(5)
                Text("6 AM").tag(6)
                Text("7 AM").tag(7)
                Text("8 AM").tag(8)
                Text("9 AM").tag(9)
                Text("10 AM").tag(10)
                Text("11 AM").tag(11)
                Text("Noon (12 PM)").tag(12)
                Text("1 PM").tag(13)
                Text("2 PM").tag(14)
                Text("3 PM").tag(15)
                Text("4 PM").tag(16)
                Text("5 PM").tag(17)
                Text("6 PM").tag(18)
                Text("7 PM").tag(19)
                Text("8 PM").tag(20)
                Text("9 PM").tag(21)
                Text("10 PM").tag(22)
                Text("11 PM").tag(23)
            }
        } header: {
            Text("Day Reset")
        } footer: {
            Text("Choose when your day resets for habit tracking. For example, if set to 4 AM, habits completed at 3 AM on Saturday will count towards Friday.")
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
    @State private var showingPermissionStatus = false
    @State private var permissionStatus = ""
    
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
                    .onChange(of: reminderTime) { newValue in
                        // Save the reminder time to UserDefaults
                        UserDefaults.standard.set(newValue, forKey: "reminderTime")
                        
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
        .alert("Notification Permissions", isPresented: $showingPermissionStatus) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(permissionStatus)
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
            if error != nil {
                // Handle notification scheduling error if needed
            }
        }
    }
    
    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status: String
                switch settings.authorizationStatus {
                case .notDetermined:
                    status = "Notifications: Not Determined\n\nYou haven't been asked for permission yet. Enable notifications to receive daily reminders."
                case .denied:
                    status = "Notifications: Denied\n\nNotifications are disabled. Go to Settings > Habit > Notifications to enable them."
                case .authorized:
                    status = "Notifications: Authorized\n\n✅ Notifications are enabled and working properly."
                case .provisional:
                    status = "Notifications: Provisional\n\n⚠️ Notifications are provisionally authorized. They may be limited."
                case .ephemeral:
                    status = "Notifications: Ephemeral\n\n⚠️ Notifications are temporarily authorized."
                @unknown default:
                    status = "Notifications: Unknown Status\n\nUnable to determine notification permission status."
                }
                
                self.permissionStatus = status
                self.showingPermissionStatus = true
            }
        }
    }
}

struct HolidaySettingsSection: View {
    @AppStorage("holidayRanges") private var holidayRangesData: Data = Data()
    @State private var showingDatePicker = false
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    @State private var holidayName = ""
    @State private var holidayRanges: [HolidayRange] = []
    
    private func loadHolidayRanges() {
        guard let ranges = try? JSONDecoder().decode([HolidayRange].self, from: holidayRangesData) else {
            holidayRanges = []
            return
        }
        holidayRanges = ranges.sorted { $0.startDate > $1.startDate }
    }
    
    private func saveHolidayRanges() {
        if let data = try? JSONEncoder().encode(holidayRanges) {
            holidayRangesData = data
        }
    }
    
    var body: some View {
        Section {
            HStack {
                Text("Holiday Periods")
                Spacer()
                Button(action: {
                    showingDatePicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if holidayRanges.isEmpty {
                Text("No holidays set")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(holidayRanges) { range in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading) {
                                if !range.name.isEmpty {
                                    Text(range.name)
                                        .font(.headline)
                                }
                                Text("\(range.startDate.formatted(date: .abbreviated, time: .omitted)) - \(range.endDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Button(action: {
                                removeHoliday(range)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Holidays")
        } footer: {
            Text("Holiday periods allow habits with holiday mode enabled to continue their streak even if not completed during these periods.")
        }
        .onAppear {
            loadHolidayRanges()
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                VStack(spacing: 20) {
                    TextField("Holiday Name (Optional)", text: $holidayName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Start Date")
                            .font(.headline)
                        DatePicker(
                            "Start Date",
                            selection: $selectedStartDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("End Date")
                            .font(.headline)
                        DatePicker(
                            "End Date",
                            selection: $selectedEndDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Add Holiday Period")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addHolidayRange()
                            showingDatePicker = false
                        }
                        .disabled(selectedEndDate < selectedStartDate)
                    }
                }
            }
            .onAppear {
                // Reset state when sheet appears
                selectedStartDate = Date()
                selectedEndDate = Date()
                holidayName = ""
            }
        }
    }
    
    private func addHolidayRange() {
        let newRange = HolidayRange(startDate: selectedStartDate, endDate: selectedEndDate, name: holidayName)
        holidayRanges.append(newRange)
        saveHolidayRanges()
    }
    
    private func removeHoliday(_ range: HolidayRange) {
        holidayRanges.removeAll { $0.id == range.id }
        saveHolidayRanges()
    }
}

#if DEBUG
struct SkillTreeDebugSection: View {
    var body: some View {
        Section {
            NavigationLink(destination: SkillTreeDebugView()) {
                Label("Skill Tree Debug", systemImage: "ladybug")
            }
        } header: {
            Text("Development")
        } footer: {
            Text("Debug tools for skill tree development")
        }
    }
}
#endif
