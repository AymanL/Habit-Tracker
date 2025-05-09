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
    @State private var isShowingMailView = false
    @AppStorage("autoExportEnabled") private var autoExportEnabled = false
    @AppStorage("autoExportEmail") private var autoExportEmail = ""
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Export")) {
                    Button(action: {
                        HabitApp.exportHabitsNow()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Email Export Now")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
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
            .onAppear {
                if autoExportEnabled {
                    requestNotificationPermission()
                }
            }
        }
    }

    private func sendExportEmail() {
        guard let url = exportURL else { return }
        
        // Create a temporary file URL for the attachment
        let tempDir = FileManager.default.temporaryDirectory
        let attachmentURL = tempDir.appendingPathComponent("habits-export.json")
        
        do {
            // Copy the export file to the attachment location
            try FileManager.default.copyItem(at: url, to: attachmentURL)
            isShowingMailView = true
        } catch {
            print("Error preparing email: \(error.localizedDescription)")
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