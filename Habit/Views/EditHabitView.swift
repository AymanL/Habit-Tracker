//
//  EditHabitView.swift
//  Habit
//
//  Created by Nazarii Zomko on 15.05.2023.
//

import SwiftUI
import CoreData

struct EditHabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var motivation: String
    @State private var selectedColor: HabitColor
    @State private var selectedType: Habit.HabitType
    @State private var startDate: Date
    @State private var isWeekly: Bool
    
    private let habit: Habit?
    
    init(habit: Habit? = nil) {
        self.habit = habit
        _title = State(initialValue: habit?.title ?? "")
        _motivation = State(initialValue: habit?.motivation ?? "")
        _selectedColor = State(initialValue: habit?.color ?? .blue)
        _selectedType = State(initialValue: habit?.type ?? .boolean)
        _startDate = State(initialValue: habit?.creationDate ?? Date())
        _isWeekly = State(initialValue: habit?.isWeekly ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $title)
                    TextField("Motivation", text: $motivation)
                }
                
                Section {
                    Toggle("Weekly Habit", isOn: $isWeekly)
                        .tint(Color(selectedColor))
                } header: {
                    Text("Frequency")
                } footer: {
                    Text("Weekly habits count as completed when any day in the week is completed. Streaks are counted by weeks instead of days.")
                }
                
                Section {
                    ColorsPickerView(selectedColor: $selectedColor)
                } header: {
                    Text("Color")
                }
                
                if habit == nil {
                    Section {
                        Picker("Type", selection: $selectedType) {
                            Text("Yes/No").tag(Habit.HabitType.boolean)
                            Text("Counter").tag(Habit.HabitType.counter)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Type")
                    }
                }
                
                Section(header: Text("Start Date")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationTitle(habit == nil ? "Add New Habit" : "Edit a Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        if let habit = habit {
            habit.title = title
            habit.motivation = motivation
            habit.color = selectedColor
            habit.type = selectedType
            habit.isWeekly = isWeekly
            
            // If the start date changed, initialize dates
            if habit.creationDate != startDate {
                if selectedType == .counter {
                    initializeCounters(for: habit)
                    habit.cleanupDailyCounters()
                } else {
                    initializeBooleanDates(for: habit)
                }
            }
            
            habit.creationDate = startDate
        } else {
            // Create new habit
            let newHabit = Habit(context: viewContext)
            newHabit.id = UUID()
            newHabit.title = title
            newHabit.motivation = motivation
            newHabit.color = selectedColor
            newHabit.type = selectedType
            newHabit.creationDate = startDate
            newHabit.completedDates = []
            newHabit.dailyCounters = [:]  // Initialize empty dictionary
            newHabit.isWeekly = isWeekly
            
            // Initialize dates based on habit type
            if selectedType == .counter {
                initializeCounters(for: newHabit)
                newHabit.cleanupDailyCounters()
            } else {
                initializeBooleanDates(for: newHabit)
            }
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving habit: \(error)")
        }
    }
    
    private func initializeCounters(for habit: Habit) {
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= Date() {
            habit.setCounterValue(1, for: currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
    }
    
    private func initializeBooleanDates(for habit: Habit) {
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= Date() {
            habit.addCompletedDate(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
    }
}

struct HabitView_Previews: PreviewProvider {
    static var previews: some View {
        EditHabitView(habit: Habit.example)
            .previewLayout(.sizeThatFits) // Apparently, without this, preview crashes -_-
    }
}

