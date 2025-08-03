import SwiftUI

struct EditDurationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var habit: Habit
    let existingDuration: HabitDuration?
    
    @State private var minutes: Int = 0
    @State private var effectiveDate: Date = Date()
    @State private var expirationDate: Date = Date().addingTimeInterval(86400)
    @State private var hasExpirationDate: Bool = false
    @State private var showingDateError = false
    
    init(habit: Habit, existingDuration: HabitDuration? = nil) {
        self.habit = habit
        self.existingDuration = existingDuration
        
        if let existingDuration = existingDuration {
            self._minutes = State(initialValue: existingDuration.minutes)
            self._effectiveDate = State(initialValue: existingDuration.effectiveDate)
            self._expirationDate = State(initialValue: existingDuration.expirationDate ?? Date().addingTimeInterval(86400))
            self._hasExpirationDate = State(initialValue: existingDuration.expirationDate != nil)
        }
    }
    
    private var isDateValid: Bool {
        !hasExpirationDate || expirationDate > effectiveDate
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper("Duration: \(minutes) minutes", value: $minutes, in: 0...1440, step: 5)
                    DatePicker("Effective Date", selection: $effectiveDate, displayedComponents: .date)
                    Toggle("Has End Date", isOn: $hasExpirationDate)
                    if hasExpirationDate {
                        DatePicker("End Date", selection: $expirationDate, displayedComponents: .date)
                            .onChange(of: expirationDate) { _ in
                                if !isDateValid {
                                    showingDateError = true
                                }
                            }
                    }
                }
                
                if existingDuration != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteDuration()
                        } label: {
                            Text("Delete Duration")
                        }
                    }
                }
            }
            .navigationTitle(existingDuration == nil ? "Add Duration" : "Edit Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isDateValid {
                            save()
                        } else {
                            showingDateError = true
                        }
                    }
                }
            }
            .alert("Invalid Date", isPresented: $showingDateError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The end date must be after the effective date.")
            }
        }
    }
    
    private func save() {
        var history = habit.durationHistory
        
        if let existingDuration = existingDuration {
            // Find and update the existing duration
            if let index = history.firstIndex(where: { $0.effectiveDate == existingDuration.effectiveDate }) {
                let updatedDuration = HabitDuration(
                    minutes: minutes,
                    effectiveDate: effectiveDate,
                    expirationDate: hasExpirationDate ? expirationDate : nil
                )
                history[index] = updatedDuration
            }
        } else {
            // Add new duration
            let newDuration = HabitDuration(
                minutes: minutes,
                effectiveDate: effectiveDate,
                expirationDate: hasExpirationDate ? expirationDate : nil
            )
            history.append(newDuration)
        }
        
        // Sort by effective date
        history.sort { $0.effectiveDate < $1.effectiveDate }
        
        // Update the habit
        habit.durationHistory = history
        
        do {
            try viewContext.save()
            // Force a UI update by triggering objectWillChange
            habit.objectWillChange.send()
        } catch {
            print("Error saving duration history: \(error)")
        }
        
        dismiss()
    }
    
    private func deleteDuration() {
        guard let existingDuration = existingDuration else { return }
        
        var history = habit.durationHistory
        history.removeAll { $0.effectiveDate == existingDuration.effectiveDate }
        habit.durationHistory = history
        
        do {
            try viewContext.save()
            // Force a UI update by triggering objectWillChange
            habit.objectWillChange.send()
        } catch {
            print("Error deleting duration: \(error)")
        }
        
        dismiss()
    }
} 