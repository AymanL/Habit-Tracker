//
//  HabitRowView.swift
//  Habit
//
//  Created by Nazarii Zomko on 15.05.2023.
//

import SwiftUI

struct HabitRowView: View {
    @ObservedObject var habit: Habit
    @State private var isPresentingEditHabitView = false
    @EnvironmentObject var dataController: DataController
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background with tap gesture
            Color.habitBackgroundColor
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresentingEditHabitView = true
                }
            
            // Content
            VStack(spacing: -8) {
                HStack() {
                    percentageView
                    Spacer()
                    if habit.type == .counter {
                        counterControls
                            .padding(.trailing, 10)
                    } else {
                        checkmarksView
                            .padding(.trailing, 10)
                    }
                }
                .padding(.leading, 22)
                .padding(.top, 12)
                VStack {
                    HStack {
                        habitTitle
                            .padding(.horizontal, 22)
                            .allowsHitTesting(false)
                        Spacer()
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(height: 95)
        .clipShape(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .sheet(isPresented: $isPresentingEditHabitView) {
            DetailView(habit: habit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(habit.title), \(habit.strengthPercentage)% strength, \(habit.isCompleted(for: Date()) ? "completed" : "not completed") for today.")
        .accessibilityAction(named: "Toggle completion for today") {
            toggleCompletion(for: Date())
            UIAccessibility.post(notification: .announcement, argument: "\(habit.isCompleted(for: Date()) ? "completed" : "not completed")")
        }
    }
    
    var percentageView: some View {
        Text("\(habit.strengthPercentage)%")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.black)
            .background(
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: CGFloat(habit.strengthPercentage) * 6.4)) // workaround because setting size with frame does not work
                    // FIXME: find a way to calculate 100% that should expand the circle all the way
                    .background(Circle().fill(Color(habit.color))) // workaround to stroke and fill at the same time
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(habit.color))
                    .offset(x: -0.5)
                )
    }
    
    var counterControls: some View {
        HStack(spacing: 8) {
            Button(action: {
                print("DEBUG: Minus button tapped")
                let currentValue = habit.counterValue(for: Date())
                if currentValue > 0 {
                    habit.setCounterValue(currentValue - 1, for: Date())
                    if currentValue - 1 == 0 {
                        // If we're going to 0, remove the date from completedDates
                        habit.removeCompletedDate(Date())
                    }
                    try? viewContext.save()
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color(habit.color))
            }
            .accessibilityLabel("Decrement counter")
            .buttonStyle(.plain)
            
            Text("\(habit.counterValue(for: Date()))")
                .font(.title2.bold())
                .foregroundColor(Color(habit.color))
                .frame(minWidth: 30)
                .accessibilityLabel("Current counter value")
            
            Button(action: {
                print("DEBUG: Plus button tapped")
                habit.incrementCounter(for: Date())
                try? viewContext.save()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color(habit.color))
            }
            .accessibilityLabel("Increment counter")
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture { _ in
            // This empty tap gesture will prevent the background tap from being triggered
        }
    }
    
    var checkmarksView: some View {
        HStack(spacing: 0) {
            ForEach(0..<7) { index in
                let date = getDateForWeekday(index)
                Button {
                    toggleCompletion(for: date)
                } label: {
                    let isCompleted = habit.isWeekly ? 
                        isWeekCompleted(date: date) : 
                        habit.isCompleted(for: date)
                    Image(isCompleted ? "checkmark" : "circle")
                        .resizable()
                        .foregroundColor(.primary)
                        .padding(isCompleted ? 9 : 10)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.dayOfTheWeekFrameSize, height: Constants.dayOfTheWeekFrameSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    var habitTitle: some View {
        Text(habit.title)
            .font(.custom("", size: 19, relativeTo: .title3))
            .lineLimit(2)
            .if(colorScheme == .dark) { $0.shadow(radius: 3) }
    }
    
    private func isWeekCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        
        // Check if any day in the week is completed
        for dayOffset in 0..<7 {
            if let weekDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                if habit.isCompleted(for: weekDay) {
                    return true
                }
            }
        }
        return false
    }
    
    private func getDateForWeekday(_ index: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the weekday of today (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let weekday = calendar.component(.weekday, from: today)
        
        // Calculate the offset to get to Monday (2)
        let daysToMonday = (weekday + 5) % 7
        
        // Get the date of Monday
        let monday = calendar.date(byAdding: .day, value: -daysToMonday, to: today)!
        
        // Add the index to get the desired day
        return calendar.date(byAdding: .day, value: index, to: monday)!
    }
    
    private func toggleCompletion(for date: Date) {
        if habit.isWeekly {
            // For weekly habits, complete the entire week
            let calendar = Calendar.current
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            
            if isWeekCompleted(date: date) {
                // If the week is completed, remove all days of the week
                for dayOffset in 0..<7 {
                    if let weekDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        habit.removeCompletedDate(weekDay)
                    }
                }
            } else {
                // If the week is not completed, add all days of the week
                for dayOffset in 0..<7 {
                    if let weekDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        if !habit.completedDates.contains(where: { calendar.isDate($0, inSameDayAs: weekDay) }) {
                            habit.completedDates.append(weekDay)
                        }
                    }
                }
            }
        } else {
            // Regular daily habit completion
            if habit.isCompleted(for: date) {
                habit.removeCompletedDate(date)
            } else {
                habit.addCompletedDate(date)
            }
        }
        
        try? viewContext.save()
    }
}

struct HabitRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Boolean habit preview
            HabitRowView(habit: {
                let habit = Habit.example
                habit.type = .boolean
                return habit
            }())
            
            // Counter habit preview
            HabitRowView(habit: {
                let habit = Habit.example
                habit.type = .counter
                habit.setCounterValue(5, for: Date())
                return habit
            }())
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .environmentObject(DataController.preview)
    }
}
