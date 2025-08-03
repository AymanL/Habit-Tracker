import SwiftUI

struct PastHabitEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var habit: Habit
    @State var selectedDate: Date
    @State private var showingDatePicker = false
    
    init(habit: Habit, selectedDate: Date) {
        self.habit = habit
        self._selectedDate = State(initialValue: selectedDate)
    }
    
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