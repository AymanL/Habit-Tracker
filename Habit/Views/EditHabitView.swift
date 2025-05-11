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
    @State private var duration: Int
    @State private var durationEffectiveDate: Date
    @State private var selectedCategory: Category?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order_, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    private let habit: Habit?
    
    init(habit: Habit? = nil) {
        self.habit = habit
        _title = State(initialValue: habit?.title ?? "")
        _motivation = State(initialValue: habit?.motivation ?? "")
        _selectedColor = State(initialValue: habit?.color ?? .blue)
        _selectedType = State(initialValue: habit?.type ?? .counter)
        _startDate = State(initialValue: habit?.creationDate ?? Date())
        _isWeekly = State(initialValue: habit?.isWeekly ?? false)
        _duration = State(initialValue: habit?.currentDuration ?? 0)
        _durationEffectiveDate = State(initialValue: Date())
        _selectedCategory = State(initialValue: habit?.category)
    }
    
    var body: some View {
        Form {
            BasicInfoSection(
                title: $title,
                motivation: $motivation,
                selectedCategory: $selectedCategory,
                selectedColor: $selectedColor,
                categories: categories
            )
            
            SettingsSection(
                selectedType: $selectedType,
                isWeekly: $isWeekly,
                startDate: $startDate
            )
            
            DurationSection(
                duration: $duration,
                durationEffectiveDate: $durationEffectiveDate
            )
        }
        .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private func save() {
        if let habit = habit {
            // Update existing habit
            habit.title = title
            habit.motivation = motivation
            habit.color = selectedColor
            habit.type = selectedType
            habit.isWeekly = isWeekly
            habit.creationDate = startDate
            habit.category = selectedCategory
            
            // Update duration if changed
            if duration != habit.currentDuration {
                var history = habit.durationHistory
                history.append(HabitDuration(minutes: duration, effectiveDate: durationEffectiveDate))
                habit.durationHistory = history
            }
            
            // Add all dates between startDate and today to completedDates
            let calendar = Calendar.current
            var currentDate = startDate
            let today = Date()
            
            while currentDate <= today {
                if !habit.isCompleted(for: currentDate) {
                    habit.addCompletedDate(currentDate)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? today
            }
        } else {
            // Create new habit
            let newHabit = Habit(context: viewContext, title: title, motivation: motivation, color: selectedColor, type: selectedType, isWeekly: isWeekly, category: selectedCategory)
            newHabit.creationDate = startDate
            
            // Set initial duration
            if duration > 0 {
                newHabit.durationHistory = [HabitDuration(minutes: duration, effectiveDate: durationEffectiveDate)]
            }
            
            // Add all dates between startDate and today to completedDates
            let calendar = Calendar.current
            var currentDate = startDate
            let today = Date()
            
            while currentDate <= today {
                newHabit.addCompletedDate(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? today
            }
        }
        
        try? viewContext.save()
    }
}

private struct BasicInfoSection: View {
    @Binding var title: String
    @Binding var motivation: String
    @Binding var selectedCategory: Category?
    @Binding var selectedColor: HabitColor
    let categories: FetchedResults<Category>
    
    var body: some View {
        Section(header: Text("Basic Info")) {
            TextField("Habit Title", text: $title)
            TextField("Motivation", text: $motivation)
            
            Picker("Category", selection: $selectedCategory) {
                Text("None").tag(nil as Category?)
                ForEach(Array(categories)) { category in
                    Text(category.name_ ?? "").tag(category as Category?)
                }
            }
            
            ColorsPickerView(selectedColor: $selectedColor)
        }
    }
}

private struct SettingsSection: View {
    @Binding var selectedType: Habit.HabitType
    @Binding var isWeekly: Bool
    @Binding var startDate: Date
    
    var body: some View {
        Section(header: Text("Settings")) {
            Picker("Type", selection: $selectedType) {
                Text("Boolean").tag(Habit.HabitType.boolean)
                Text("Counter").tag(Habit.HabitType.counter)
            }
            .pickerStyle(.segmented)
            
            Toggle("Weekly Habit", isOn: $isWeekly)
            
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
        }
    }
}

private struct DurationSection: View {
    @Binding var duration: Int
    @Binding var durationEffectiveDate: Date
    
    var body: some View {
        Section(header: Text("Duration")) {
            Stepper("Duration: \(duration) minutes", value: $duration, in: 0...1440, step: 5)
            DatePicker("Effective Date", selection: $durationEffectiveDate, displayedComponents: .date)
        }
    }
}

struct HabitView_Previews: PreviewProvider {
    static var previews: some View {
        EditHabitView(habit: Habit.example)
            .previewLayout(.sizeThatFits)
    }
}

