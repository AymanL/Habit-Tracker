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
import MessageUI

class MailComposerDelegate: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailComposerDelegate()
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail composer
        controller.dismiss(animated: true)
        
        // Log the result
        switch result {
        case .sent:
            print("Email sent successfully")
        case .saved:
            print("Email saved as draft")
        case .failed:
            print("Email sending failed: \(error?.localizedDescription ?? "Unknown error")")
        case .cancelled:
            print("Email sending cancelled")
        @unknown default:
            print("Unknown email result")
        }
    }
}

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    let recipientEmail: String
    let attachmentURL: URL
    @State private var showMailError = false
    
    func makeUIViewController(context: Context) -> UIViewController {
        if MFMailComposeViewController.canSendMail() {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = context.coordinator
            vc.setToRecipients([recipientEmail])
            vc.setSubject("Weekly Habit Export")
            vc.setMessageBody("Please find attached your weekly habit export.", isHTML: false)
            
            do {
                let attachmentData = try Data(contentsOf: attachmentURL)
                vc.addAttachmentData(attachmentData, mimeType: "application/json", fileName: "habits-export.json")
            } catch {
                print("Error attaching file: \(error.localizedDescription)")
            }
            
            return vc
        } else {
            // If mail is not available, show an alert
            DispatchQueue.main.async {
                showMailError = true
            }
            return UIViewController()
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isShowing: $isShowing, showMailError: $showMailError)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var showMailError: Bool
        
        init(isShowing: Binding<Bool>, showMailError: Binding<Bool>) {
            _isShowing = isShowing
            _showMailError = showMailError
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            // Always dismiss the mail composer
            DispatchQueue.main.async {
                self.isShowing = false
            }
            
            // Log the result
            switch result {
            case .sent:
                print("Email sent successfully")
            case .saved:
                print("Email saved as draft")
            case .failed:
                print("Email sending failed: \(error?.localizedDescription ?? "Unknown error")")
            case .cancelled:
                print("Email sending cancelled")
            @unknown default:
                print("Unknown email result")
            }
        }
    }
}

class MailComposerViewController: UIViewController, MFMailComposeViewControllerDelegate {
    var recipientEmail: String?
    var attachmentURL: URL?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentMailComposer()
    }
    
    private func presentMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            print("Mail services are not available")
            dismiss(animated: true)
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        if let email = recipientEmail {
            mailComposer.setToRecipients([email])
        }
        
        mailComposer.setSubject("Weekly Habit Export")
        mailComposer.setMessageBody("Please find attached your weekly habit export.", isHTML: false)
        
        if let url = attachmentURL {
            do {
                let attachmentData = try Data(contentsOf: url)
                mailComposer.addAttachmentData(attachmentData, mimeType: "application/json", fileName: "habits-export.json")
            } catch {
                print("Error attaching file: \(error.localizedDescription)")
            }
        }
        
        present(mailComposer, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // First dismiss the mail composer
        controller.dismiss(animated: true) {
            // Then dismiss this view controller
            self.dismiss(animated: true)
        }
        
        // Log the result
        switch result {
        case .sent:
            print("Email sent successfully")
        case .saved:
            print("Email saved as draft")
        case .failed:
            print("Email sending failed: \(error?.localizedDescription ?? "Unknown error")")
        case .cancelled:
            print("Email sending cancelled")
        @unknown default:
            print("Unknown email result")
        }
    }
}

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
    @State private var isShowingMailView = false
    @State private var showMailError = false
    @State private var mailComposerVC: UIViewController?
    
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
                            
                            Button {
                                print("Email Export Now button tapped")
                                exportAllHabits { success in
                                    print("Export completed with success: \(success)")
                                    if success {
                                        isShowingMailView = true
                                    }
                                }
                            } label: {
                                Label("Email Export Now", systemImage: "envelope")
                            }
                            .disabled(isExporting || isImporting)
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
            .sheet(isPresented: $isShowingMailView) {
                if let url = exportURL {
                    MailView(isShowing: $isShowingMailView, recipientEmail: autoExportEmail, attachmentURL: url)
                }
            }
            .alert("Cannot Send Email", isPresented: $showMailError) {
                Button("OK", role: .cancel) {
                    isShowingMailView = false
                }
            } message: {
                Text("Please set up a mail account in the Mail app to send emails.")
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
        
        // Schedule the next export
        let bgRequest = BGProcessingTaskRequest(identifier: "com.ayman.habit.weeklyexport")
        bgRequest.requiresNetworkConnectivity = true
        bgRequest.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(bgRequest)
        } catch {
            print("Could not schedule weekly export: \(error)")
        }
    }
    
    private func handleWeeklyExport(task: BGProcessingTask) {
        // Schedule the next export
        scheduleWeeklyExport()
        
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
        print("Starting sendExportEmail")
        guard let url = exportURL else {
            print("No export URL available")
            return
        }
        print("Export URL: \(url.path)")
        
        // Create a temporary file URL for the attachment
        let tempDir = FileManager.default.temporaryDirectory
        let attachmentURL = tempDir.appendingPathComponent("habits-export.json")
        print("Attachment URL: \(attachmentURL.path)")
        
        do {
            // Copy the export file to the attachment location
            if FileManager.default.fileExists(atPath: attachmentURL.path) {
                try FileManager.default.removeItem(at: attachmentURL)
            }
            try FileManager.default.copyItem(at: url, to: attachmentURL)
            print("Successfully copied file for attachment")
            
            // Create and configure the mail composer view controller
            let mailVC = MailComposerViewController()
            mailVC.recipientEmail = autoExportEmail
            mailVC.attachmentURL = attachmentURL
            
            // Present the mail composer
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(mailVC, animated: true)
            }
        } catch {
            print("Error preparing email: \(error.localizedDescription)")
            // Reset the button state
            DispatchQueue.main.async {
                self.isExporting = false
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
                try jsonData.write(to: tempFile)
                print("Successfully wrote export file to: \(tempFile.path)")
                
                DispatchQueue.main.async {
                    self.exportURL = tempFile
                    self.isExporting = false
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

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddHabit = false
    @State private var showingCategories = false
    @State private var isPresentingSettingsView = false
    @State private var isShowingMailView = false
    @State private var exportURL: URL?
    @AppStorage("sortingOption") private var sortingOption: SortingOption = .byOrder
    @AppStorage("isSortingOrderDescending") private var isSortingOrderAscending = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Divider()
                HeaderView()
                HabitListView(sortingOption: sortingOption, isSortingOrderAscending: isSortingOrderAscending)
            }
            .navigationTitle("Habits")
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
            .sheet(isPresented: $isShowingMailView) {
                if let url = exportURL {
                    MailView(isShowing: $isShowingMailView, recipientEmail: "", attachmentURL: url)
                }
            }
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
