import SwiftUI
import CoreData
import UserNotifications
import BackgroundTasks
import MessageUI

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
    @State private var minimumLoadingTime: TimeInterval = 1.5 // Minimum time to show loader
    
    var body: some View {
        NavigationView {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingShareSheet) {
                if let url = exportURL {
                    print("DEBUG: Presenting ShareSheet with URL: \(url.path)")
                    ShareSheet(items: [url])
                        .ignoresSafeArea()
                        .onAppear {
                            print("DEBUG: ShareSheet appeared")
                        }
                        .onDisappear {
                            print("DEBUG: ShareSheet disappeared")
                            isShowingShareSheet = false
                        }
                } else {
                    print("DEBUG: ShareSheet triggered but exportURL is nil")
                }
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
}

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    let recipientEmail: String
    let attachmentURL: URL
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
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
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isShowing: $isShowing)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        
        init(isShowing: Binding<Bool>) {
            _isShowing = isShowing
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            isShowing = false
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("DEBUG: Creating UIActivityViewController with items: \(items)")
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            print("DEBUG: Share sheet completed - Activity: \(String(describing: activityType)), Completed: \(completed), Error: \(String(describing: error))")
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        print("DEBUG: Updating UIActivityViewController")
    }
} 