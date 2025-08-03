//
//  DetailView.swift
//  Habit
//
//  Created by Nazarii Zomko on 21.07.2023.
//

import SwiftUI


struct DetailView: View {
    @ObservedObject var habit: Habit
    @AppStorage("overviewPageIndex") private var overviewPageIndex = 0
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isPresentingEditHabitView = false
    @State private var isPresentingEditDurationView = false
    @State private var selectedDuration: HabitDuration? = nil
    @State private var exportData: Data?
    @State private var isShowingShareSheet = false
    @State private var showingPastHabitEditor = false
    @State private var selectedPastDate = Date()
    
    private var habitInstance: Habit {
        habit
    }
    
    private var completedDates: Binding<[Date]> {
        Binding(
            get: { habit.completedDates },
            set: { newDates in
                habit.completedDates = newDates
                try? viewContext.save()
            }
        )
    }
    
    @EnvironmentObject var dataController: DataController
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                regularityAndReminder
                overview
                
                ChartView(
                    dates: habit.completedDates,
                    color: habit.color,
                    counterValues: habit.dailyCounters
                )
                .frame(height: 200)
                .padding()

                
                // Past Habit Editor Section (for counter habits)
                if habit.type == .counter {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("PAST HABIT EDITOR")
                                .font(.caption.bold())
                            Spacer()
                            Button(action: {
                                selectedPastDate = Date()
                                showingPastHabitEditor = true
                            }) {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(Color(habit.color))
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("Edit counter values for past dates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Duration History Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("DURATION HISTORY")
                            .font(.caption.bold())
                        Spacer()
                        Button(action: {
                            selectedDuration = nil
                            isPresentingEditDurationView = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(habit.color))
                        }
                    }
                    .padding(.horizontal)
                    
                    ForEach(habit.durationHistory.sorted(by: { $0.effectiveDate > $1.effectiveDate }), id: \.effectiveDate) { duration in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(duration.minutes) minutes")
                                    .font(.headline)
                                Text("From: \(duration.effectiveDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let expirationDate = duration.expirationDate {
                                    Text("To: \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Current")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedDuration = duration
                                isPresentingEditDurationView = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(Color(habit.color))
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .sheet(isPresented: $isPresentingEditDurationView, onDismiss: {
                    selectedDuration = nil
                }) {
                    EditDurationView(habit: habit, existingDuration: selectedDuration)
                }
                
                CalendarView(
                    dateInterval: DateInterval(start: .distantPast, end: Date()),
                    completedDates: $habit.completedDates,
                    color: habit.color,
                    habit: habit
                )
            }
            .navigationTitle("\(habit.title)")
            .toolbarBackground(Color(habit.color), for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    NavigationLink("Edit") {
                        EditHabitView(habit: habit)
                    }
                    .foregroundColor(.black)
                    .accessibilityIdentifier("editHabit")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        exportHabitData()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                setupAppearance()
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
            .sheet(isPresented: $showingPastHabitEditor) {
                PastHabitEditorView(habit: habit, selectedDate: selectedPastDate)
            }
        }
    }
    
    var regularityAndReminder: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("REGULARITY")
                    .font(.caption.bold())
                Text("every day")
            }
            .padding(.leading)
            .padding(.trailing, 70)
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading) {
                Text("REMIND ME")
                    .font(.caption.bold())
                Text("--:--")
            }
            .accessibilityElement(children: .combine)

            Spacer()
        }
        .foregroundColor(.black)
        .padding(.top, 40)
        .padding(.bottom, 15)
        .background(alignment: .bottom, content: {
            Color(habit.color)
                .frame(height: 500)
        })
    }
    
    var overview: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $overviewPageIndex) {
                // Note: There is no point in calculating strength gained in last year because with current formula strengthGainedInYear will always be equal to strengthPercentage.
                let strength = habitInstance.strengthPercentage
                let monthStrength = habitInstance.strengthGainedWithinLastDays(daysAgo: 30)
                let yearStrength = habitInstance.strengthGainedWithinLastDays(daysAgo: 365)
                
                OverviewView(
                    title: "Habit Strength",
                    mainText: "\(strength)%",
                    secondaryText1: "Month: +\(monthStrength)%",
                    secondaryText2: "Year: +\(yearStrength)%"
                )
                .tag(0)
                .accessibilityElement(children: .combine)
                
                let completedCount = habitInstance.isWeekly ? 
                    habitInstance.completedDates.count / 7 : 
                    habitInstance.completedDates.count
                let monthCompletions = habitInstance.isWeekly ? 
                    habitInstance.completionsWithinLastDays(daysAgo: 30) / 7 : 
                    habitInstance.completionsWithinLastDays(daysAgo: 30)
                let yearCompletions = habitInstance.isWeekly ? 
                    habitInstance.completionsWithinLastDays(daysAgo: 365) / 7 : 
                    habitInstance.completionsWithinLastDays(daysAgo: 365)
                
                OverviewView(
                    title: "Completions",
                    mainText: "\(completedCount)",
                    secondaryText1: "Month: +\(monthCompletions)",
                    secondaryText2: "Year: +\(yearCompletions)"
                )
                .tag(1)
                .accessibilityElement(children: .combine)

                let streak = habitInstance.streak
                let longestStreak = habitInstance.longestStreak
                
                OverviewView(
                    title: "Streak",
                    mainText: "\(streak) \(habitInstance.isWeekly ? "weeks" : "days")",
                    secondaryText1: "Longest Streak: \(longestStreak) \(habitInstance.isWeekly ? "weeks" : "days")",
                    secondaryText2: ""
                )
                .tag(2)
                .accessibilityElement(children: .combine)
                
                let totalTime = habitInstance.getTotalTimeSpent()
                let monthTime = habitInstance.getTotalTimeSpentInLastMonth()
                let yearTime = habitInstance.getTotalTimeSpentInLastYear()
                
                OverviewView(
                    title: "Time Spent",
                    mainText: formatTime(totalTime),
                    secondaryText1: "Month: \(formatTime(monthTime))",
                    secondaryText2: "Year: \(formatTime(yearTime))"
                )
                .tag(3)
                .accessibilityElement(children: .combine)
            }
            .tabViewStyle(.page)
            .frame(height: 190)
            
            Text("OVERVIEW")
                .font(.caption.bold())
                .padding()
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    func setupAppearance() {
        // Fixes SwiftUI bug where paging dots are white in Light Mode.
        let color = UIColor.label
        UIPageControl.appearance().currentPageIndicatorTintColor = color
        UIPageControl.appearance().pageIndicatorTintColor = color.withAlphaComponent(0.4)
    }
    
    struct OverviewView: View {
        var title: String
        var mainText: String
        var secondaryText1: String
        var secondaryText2: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.title3.bold())
                HStack() {
                    VStack(alignment: .leading) {
                        VStack() {
                            Text(mainText)
                                .font(.system(size: 50).bold())
                        }
                        HStack {
                            Text(secondaryText1)
                                .padding(.trailing, 60)
                            Text(secondaryText2)
                        }
                    }
                    .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    private func exportHabitData() {
        // Create a dictionary with all habit data
        let habitData: [String: Any] = [
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
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: habitData, options: .prettyPrinted)
            exportData = jsonData
            isShowingShareSheet = true
        } catch {
            print("Error exporting habit data: \(error)")
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailView(habit: Habit.example)
                .previewDisplayName("Boolean Habit")
            
            DetailView(habit: Habit.counterExample)
                .previewDisplayName("Counter Habit")
        }
        .previewLayout(.sizeThatFits)
    }
}

struct EditDurationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var habit: Habit
    let existingDuration: HabitDuration?
    
    @State private var minutes: Int
    @State private var effectiveDate: Date
    @State private var expirationDate: Date
    @State private var hasExpirationDate: Bool
    @State private var showingDateError = false
    
    init(habit: Habit, existingDuration: HabitDuration? = nil) {
        self.habit = habit
        self.existingDuration = existingDuration
        
        _minutes = State(initialValue: existingDuration?.minutes ?? 0)
        _effectiveDate = State(initialValue: existingDuration?.effectiveDate ?? Date())
        _expirationDate = State(initialValue: existingDuration?.expirationDate ?? Date().addingTimeInterval(86400)) // Default to tomorrow
        _hasExpirationDate = State(initialValue: existingDuration?.expirationDate != nil)
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

struct PastHabitEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var habit: Habit
    @State var selectedDate: Date
    @State private var showingDatePicker = false
    
    private var currentValue: Int {
        habit.counterValueForPastDate(for: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Date Display and Picker
                VStack(spacing: 10) {
                    Text("Selected Date")
                        .font(.headline)
                    
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Text(selectedDate.formatted(date: .complete, time: .omitted))
                                .font(.title2)
                                .foregroundColor(.primary)
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // Current Value Display
                VStack(spacing: 10) {
                    Text("Current Value")
                        .font(.headline)
                    
                    Text("\(currentValue)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(habit.color))
                }
                
                // Counter Controls
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        Button(action: {
                            if currentValue > 0 {
                                habit.setCounterValueForPastDate(currentValue - 1, for: selectedDate)
                                if currentValue - 1 == 0 {
                                    habit.removeCompletedDateForPastDate(selectedDate)
                                }
                                try? viewContext.save()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.red)
                        }
                        .disabled(currentValue <= 0)
                        
                        Button(action: {
                            habit.setCounterValueForPastDate(currentValue + 1, for: selectedDate)
                            try? viewContext.save()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Quick increment buttons
                    HStack(spacing: 10) {
                        ForEach([5, 10, 15], id: \.self) { increment in
                            Button(action: {
                                habit.setCounterValueForPastDate(currentValue + increment, for: selectedDate)
                                try? viewContext.save()
                            }) {
                                Text("+\(increment)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(habit.color))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Past Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $selectedDate)
            }
        }
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}