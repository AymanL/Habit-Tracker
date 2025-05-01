//
//  Habit+Utils.swift
//  Habit
//
//  Created by Nazarii Zomko on 28.07.2023.
//

import Foundation

extension Habit {
    // The number of days to look back when calculating the habit's strength percentage, aiming for 100%.
    // This value defines the time period within which completed dates are considered for strength calculation.
    var strengthCalculationPeriod: Int { 60 }
    
    var strengthPercentage: Int {
        calculateStrengthPercentage(completedDates: completedDates)
    }
    
    var streak: Int {
        let dates = processDatesForStreakCalculation(completedDates)
        print("DEBUG: Calculating streak for dates: \(dates)")
        
        // Check if there are any completed dates
        guard let firstDate = dates.first else {
            print("DEBUG: No dates found, returning 0")
            return 0
        }
        
        // If the most recent completion date is not today, there's no current streak
        guard firstDate.isInSameDay(as: Date()) else {
            print("DEBUG: Most recent date \(firstDate) is not today, returning 0")
            return 0
        }
        
        var previousDate = firstDate
        var streak = 1
        print("DEBUG: Starting streak calculation with first date: \(firstDate)")

        for date in dates.dropFirst() {
            let daysBetweenDates = previousDate.days(from: date)
            print("DEBUG: Days between \(previousDate) and \(date): \(daysBetweenDates)")
            
            if daysBetweenDates <= 1 {
                streak += 1
                print("DEBUG: Incrementing streak to \(streak)")
            } else {
                print("DEBUG: Streak broken at \(streak)")
                return streak
            }
            previousDate = date
        }
        
        print("DEBUG: Final streak: \(streak)")
        return streak
    }
    
    var longestStreak: Int {
        let dates = processDatesForStreakCalculation(completedDates)
        // Check if there are any completed dates
        guard let firstDate = dates.first else { return 0 }
        
        var previousDate = firstDate

        var currentStreak = 1
        var longestStreak = 0
         
        for date in dates.dropFirst() {
            let daysBetweenDates = previousDate.days(from: date)
            if daysBetweenDates <= 1 {
                currentStreak += 1
            } else {
                // Check if the current streak is longer than the longest streak so far
                longestStreak = max(currentStreak, longestStreak)
                currentStreak = 1
            }
            previousDate = date
        }
        // Check if the last streak is the longest streak
        return max(currentStreak, longestStreak)
    }
    
    func processDatesForStreakCalculation(_ dates: [Date]) -> [Date] {
        print("DEBUG: Processing dates for streak calculation. Original dates: \(dates)")
        
        // Normalize all dates to start of day
        let normalizedDates = dates.map { Calendar.current.startOfDay(for: $0) }
        print("DEBUG: Normalized dates: \(normalizedDates)")
        
        // Filter dates without days after today
        let datesWithoutDaysAfterToday = normalizedDates.filter { $0 <= Date.now }
        print("DEBUG: Dates without future dates: \(datesWithoutDaysAfterToday)")
        
        // Remove duplicates
        let uniqueDatesWithinPeriod = datesWithoutDaysAfterToday.removingDuplicates()
        print("DEBUG: Unique dates: \(uniqueDatesWithinPeriod)")
        
        // Sort from newest to oldest
        let sortedDates = uniqueDatesWithinPeriod.sorted { $0 > $1 }
        print("DEBUG: Sorted dates: \(sortedDates)")
        
        return sortedDates
    }

    func isCompleted(for date: Date) -> Bool {
        if type == .boolean {
            return completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
        } else {
            return counterValue(for: date) > 0
        }
    }
    
    func isCompleted(daysAgo: Int) -> Bool {
        isCompleted(for: Date.todayMinusDaysAgo(daysAgo: daysAgo))
    }
    
    /// Adds a date to the list of completed dates for the habit.
    ///
    /// - Parameter date: The date to add.
    func addCompletedDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        print("DEBUG: Adding completed date: \(normalizedDate)")
        print("DEBUG: Current completed dates: \(completedDates)")
        
        if !self.isCompleted(for: normalizedDate) {
            self.completedDates.append(normalizedDate)
            print("DEBUG: Date added. New completed dates: \(completedDates)")
        } else {
            print("DEBUG: Date already exists in completed dates")
        }
    }
    
    /// Removes a date from the list of completed dates for the habit.
    ///
    /// - Parameter date: The date to remove.
    func removeCompletedDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        print("DEBUG: Removing completed date: \(normalizedDate)")
        print("DEBUG: Current completed dates: \(completedDates)")
        
        self.completedDates.removeAll(where: { Calendar.current.isDate($0, inSameDayAs: normalizedDate) })
        
        // Also clear the counter value for this date
        if type == .counter {
            setCounterValue(0, for: normalizedDate)
        }
        
        print("DEBUG: Date removed. New completed dates: \(completedDates)")
    }
    
    func toggleCompletion(daysAgo: Int) {
        let todayMinusDaysAgo = Date.todayMinusDaysAgo(daysAgo: daysAgo)
        self.isCompleted(daysAgo: daysAgo) ? self.removeCompletedDate(todayMinusDaysAgo) : self.addCompletedDate(todayMinusDaysAgo)
    }
    
    
    // TODO: Calculate percentage from 0 to 1 instead of 0 to 100
    /// The strength percentage of the habit.
    ///
    /// Represents the strength percentage of the habit based on the number of completed dates. The calculation is performed using a logarithmic formula.
    /// - Returns: An integer representing the strength percentage of the habit, ranging from 0 to 100.
    func calculateStrengthPercentage(completedDates: [Date]) -> Int {
        // Get completed dates within the specified number of days counting back from today.
        let completedDatesWithinPeriod = completedDates.filter { $0.isWithinLastDays(daysAgo: strengthCalculationPeriod) }
        let uniqueCompletedDatesWithinPeriod = completedDatesWithinPeriod.removingDuplicates()
        
        // Calculate the strength percentage using a logarithmic formula
        let logNumber = Double(uniqueCompletedDatesWithinPeriod.count + 1)
        let logBase = calculateLogarithmBase(value: Double(strengthCalculationPeriod), result: 100) // With this log base, 100% strength will be reached in 'strengthCalculationPeriod' days.
        
        let calculatedPercentage = Int(log(logNumber)/log(logBase))
        // Ensure the calculated percentage is within the range of 0 to 100
        return min(calculatedPercentage, 100)
    }
    
    func calculateLogarithmBase(value: Double, result: Double) -> Double {
        return pow(value, 1/result)
    }
    
    func strengthGainedWithinLastDays(daysAgo: Int) -> Int {
        let habitStrength = calculateStrengthPercentage(completedDates: completedDates)
        let completedDatesWithoutLast30Days = completedDates.filter { $0.isWithinLastDays(daysAgo: daysAgo) == false }
        let habitStrengthWithoutLast30Days = calculateStrengthPercentage(completedDates: completedDatesWithoutLast30Days)
        let strengthGainedInMonth = habitStrength - habitStrengthWithoutLast30Days
        return strengthGainedInMonth
    }
    
    func completionsWithinLastDays(daysAgo: Int) -> Int {
        completedDates.filter { $0.isWithinLastDays(daysAgo: daysAgo) }.count
    }
}
