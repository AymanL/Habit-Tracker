//
//  CalendarView.swift
//  Habit
//
//  Created by Nazarii Zomko on 21.07.2023.
//

import SwiftUI

struct CalendarView: UIViewRepresentable {
    let dateInterval: DateInterval
    @Binding var completedDates: [Date]
    var color: HabitColor
    var habit: Habit
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.tintColor = UIColor(color)
        calendarView.calendar = Calendar(identifier: .gregorian)
        calendarView.availableDateRange = dateInterval
        
        // Convert Date objects to DateComponents
        let dateComponents = completedDates.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) }
        
        let dateSelection = UICalendarSelectionMultiDate(delegate: context.coordinator)
        dateSelection.setSelectedDates(dateComponents, animated: true)
        calendarView.selectionBehavior = dateSelection
        return calendarView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, completedDates: $completedDates, color: color, habit: habit)
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Convert Date objects to DateComponents
        let dateComponents = completedDates.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) }
        
        let dateSelection = UICalendarSelectionMultiDate(delegate: context.coordinator)
        dateSelection.setSelectedDates(dateComponents, animated: true)
        uiView.selectionBehavior = dateSelection
        
        uiView.tintColor = UIColor(color)
    }
    
    class Coordinator: NSObject, UICalendarSelectionMultiDateDelegate {
        var parent: CalendarView
        @Binding var completedDates: [Date]
        var color: HabitColor
        var habit: Habit
        
        init(parent: CalendarView, completedDates: Binding<[Date]>, color: HabitColor, habit: Habit) {
            self.parent = parent
            self._completedDates = completedDates
            self.color = color
            self.habit = habit
        }
        
        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
            // Convert DateComponents to Date
            if let date = Calendar.current.date(from: dateComponents) {
                habit.addCompletedDate(date)
            }
        }
        
        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
            // Convert DateComponents to Date
            if let date = Calendar.current.date(from: dateComponents) {
                habit.removeCompletedDate(date)
            }
        }
        
        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, canSelectDate dateComponents: DateComponents) -> Bool {
            return true
        }
    }
}


