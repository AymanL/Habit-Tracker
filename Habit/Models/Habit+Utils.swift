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
        let dates = weekendMode_ ? processDatesForWeekendModeStreakCalculation(completedDates) : processDatesForStreakCalculation(completedDates)
        
        // Check if there are any completed dates
        guard let firstDate = dates.first else { return 0 }
        
        if isWeekly {
            // For weekly habits, we need to group dates by week
            var currentStreak = 0
            var currentWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDate))!
            
            for date in dates {
                let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
                
                if weekStart == currentWeekStart {
                    // Same week, continue streak
                    continue
                } else if Calendar.current.dateComponents([.day], from: currentWeekStart, to: weekStart).day == 7 {
                    // Next week, increment streak
                    currentStreak += 1
                    currentWeekStart = weekStart
                } else {
                    // Streak broken
                    break
                }
            }
            
            // Add 1 for the current week if it's completed
            if Calendar.current.isDateInToday(firstDate) || Calendar.current.isDateInYesterday(firstDate) {
                currentStreak += 1
            }
            
            return currentStreak
        } else {
            // Regular daily streak calculation
            var previousDate = firstDate
            var currentStreak = 1
            
            for date in dates.dropFirst() {
                let daysBetweenDates = previousDate.days(from: date)
                if daysBetweenDates <= 1 {
                    currentStreak += 1
                } else if weekendMode_ && daysBetweenDates >= 2 {
                    // Check if the missing days are weekend days
                    var allWeekendDays = true
                    var gapDays: [String] = []
                    
                    for dayOffset in 1..<daysBetweenDates {
                        if let missingDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: previousDate) {
                            let weekday = Calendar.current.component(.weekday, from: missingDate)
                            gapDays.append(Calendar.current.weekdaySymbols[weekday - 1])
                            
                            // If it's not a weekend day (Saturday = 7, Sunday = 1), break the streak
                            if weekday != 1 && weekday != 7 {
                                allWeekendDays = false
                                break
                            }
                        }
                    }
                    
                    if allWeekendDays {
                        currentStreak += 1
                    } else {
                        break
                    }
                } else {
                    break
                }
                previousDate = date
            }
            
            return currentStreak
        }
    }
    
    var longestStreak: Int {
        let dates = weekendMode_ ? processDatesForWeekendModeStreakCalculation(completedDates) : processDatesForStreakCalculation(completedDates)
        // Check if there are any completed dates
        guard let firstDate = dates.first else { return 0 }
        
        if isWeekly {
            // For weekly habits, we need to group dates by week
            var currentStreak = 0
            var longestStreak = 0
            var currentWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDate))!
            
            for date in dates {
                let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
                
                if weekStart == currentWeekStart {
                    // Same week, continue streak
                    continue
                } else if Calendar.current.dateComponents([.day], from: currentWeekStart, to: weekStart).day == 7 {
                    // Next week, increment streak
                    currentStreak += 1
                    currentWeekStart = weekStart
                } else {
                    // Streak broken, update longest streak
                    longestStreak = max(currentStreak, longestStreak)
                    currentStreak = 0
                    currentWeekStart = weekStart
                }
            }
            
            // Add 1 for the current week if it's completed
            if Calendar.current.isDateInToday(firstDate) || Calendar.current.isDateInYesterday(firstDate) {
                currentStreak += 1
            }
            
            return max(currentStreak, longestStreak)
        } else {
            // Regular daily streak calculation
            var previousDate = firstDate
            var currentStreak = 1
            var longestStreak = 0
            
            for date in dates.dropFirst() {
                let daysBetweenDates = previousDate.days(from: date)
                if daysBetweenDates <= 1 {
                    currentStreak += 1
                } else {
                    longestStreak = max(currentStreak, longestStreak)
                    currentStreak = 1
                }
                previousDate = date
            }
            
            return max(currentStreak, longestStreak)
        }
    }
    
    func processDatesForStreakCalculation(_ dates: [Date]) -> [Date] {
        // Normalize all dates to start of day
        let normalizedDates = dates.map { Calendar.current.startOfDay(for: $0) }
        
        // Filter dates without days after today
        let datesWithoutDaysAfterToday = normalizedDates.filter { $0 <= Date.now }        
        
        // Remove duplicates
        let uniqueDatesWithinPeriod = datesWithoutDaysAfterToday.removingDuplicates()        
        
        // Sort from newest to oldest
        let sortedDates = uniqueDatesWithinPeriod.sorted { $0 > $1 }

        return sortedDates
    }
    
    func processDatesForWeekendModeStreakCalculation(_ dates: [Date]) -> [Date] {
        // Normalize all dates to start of day
        let normalizedDates = dates.map { Calendar.current.startOfDay(for: $0) }
        
        // Filter dates without days after today
        let datesWithoutDaysAfterToday = normalizedDates.filter { $0 <= Date.now }        
        // Remove duplicates
        let uniqueDatesWithinPeriod = datesWithoutDaysAfterToday.removingDuplicates()        
        // Sort from newest to oldest
        let sortedDates = uniqueDatesWithinPeriod.sorted { $0 > $1 }
        
        // For weekend mode, we need to fill in missing weekdays between completed dates
        var processedDates: [Date] = []
        let calendar = Calendar.current
        
        for index in 0..<sortedDates.count {
            let currentDate = sortedDates[index]
            processedDates.append(currentDate)
            
            // If there's a next date, check if we need to fill in weekdays
            if index + 1 < sortedDates.count {
                let nextDate = sortedDates[index + 1]
                let daysBetween = calendar.dateComponents([.day], from: nextDate, to: currentDate).day ?? 0
                
                // If there are gaps, fill in the weekdays (Monday-Friday)
                if daysBetween > 1 {
                    for dayOffset in 1..<daysBetween {
                        if let intermediateDate = calendar.date(byAdding: .day, value: -dayOffset, to: currentDate) {
                            let weekday = calendar.component(.weekday, from: intermediateDate)
                            
                            // Only fill in weekdays (Monday = 2, Tuesday = 3, ..., Friday = 6)
                            if weekday >= 2 && weekday <= 6 {
                                processedDates.append(intermediateDate)
                            }
                        }
                    }
                }
            }
        }
        
        // Sort again to maintain chronological order
        return processedDates.sorted { $0 > $1 }
    }

    func isCompleted(for date: Date) -> Bool {
        if type == .boolean {
            return completedDates.contains { date.isInSameCustomDay(as: $0) }
        } else {
            return counterValue(for: date) > 0
        }
    }
    
    func isCompleted(daysAgo: Int) -> Bool {
        isCompleted(for: Date.customDayMinusDaysAgo(daysAgo: daysAgo))
    }
    
    /// Adds a date to the list of completed dates for the habit.
    ///
    /// - Parameter date: The date to add.
    func addCompletedDate(_ date: Date) {
        let normalizedDate = CustomDayResetCalendar.shared.startOfCustomDay(for: date)
        
        if !self.isCompleted(for: normalizedDate) {
            self.completedDates.append(normalizedDate)
            
            // For counter habits, initialize with a value of 1
            if type == .counter {
                setCounterValue(1, for: normalizedDate)
            }
            
        } else {
            print("DEBUG: Date already exists in completed dates")
        }
    }
    
    /// Adds a date to the list of completed dates for the habit using regular calendar days (for calendar interactions).
    ///
    /// - Parameter date: The date to add (already normalized to start of day).
    func addCompletedDateForCalendar(_ date: Date) {
        // Check if date already exists using regular calendar comparison
        let alreadyExists = completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
        
        if !alreadyExists {
            self.completedDates.append(date)
            
            // For counter habits, initialize with a value of 1
            if type == .counter {
                setCounterValueForPastDate(1, for: date)
            }
            
        } else {
            print("DEBUG: Date already exists in completed dates (calendar)")
        }
    }
    
    /// Removes a date from the list of completed dates for the habit.
    ///
    /// - Parameter date: The date to remove.
    func removeCompletedDate(_ date: Date) {
        let normalizedDate = CustomDayResetCalendar.shared.startOfCustomDay(for: date)
        
        self.completedDates.removeAll(where: { $0.isInSameCustomDay(as: normalizedDate) })
        
        // Also clear the counter value for this date
        if type == .counter {
            setCounterValue(0, for: normalizedDate)
        }
        
    }
    
    /// Removes a date from the list of completed dates for the habit using regular calendar days (for calendar interactions).
    ///
    /// - Parameter date: The date to remove (already normalized to start of day).
    func removeCompletedDateForCalendar(_ date: Date) {
        self.completedDates.removeAll(where: { Calendar.current.isDate($0, inSameDayAs: date) })
        
        // Also clear the counter value for this date using regular calendar days
        if type == .counter {
            setCounterValueForPastDate(0, for: date)
        }
    }
    
    /// Removes a date from the list of completed dates for the habit using regular calendar days (for past editing).
    ///
    /// - Parameter date: The date to remove.
    func removeCompletedDateForPastDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        self.completedDates.removeAll(where: { Calendar.current.isDate($0, inSameDayAs: normalizedDate) })
        
        // Also clear the counter value for this date using regular calendar days
        if type == .counter {
            setCounterValueForPastDate(0, for: normalizedDate)
        }
        
    }
    
    func toggleCompletion(daysAgo: Int) {
        let todayMinusDaysAgo = Date.customDayMinusDaysAgo(daysAgo: daysAgo)
        self.isCompleted(daysAgo: daysAgo) ? self.removeCompletedDate(todayMinusDaysAgo) : self.addCompletedDate(todayMinusDaysAgo)
    }
    
    
    // TODO: Calculate percentage from 0 to 1 instead of 0 to 100
    /// The strength percentage of the habit.
    ///
    /// Represents the strength percentage of the habit based on the number of completed dates. The calculation is performed using a logarithmic formula.
    /// - Returns: An integer representing the strength percentage of the habit, ranging from 0 to 100.
    func calculateStrengthPercentage(completedDates: [Date]) -> Int {
        // Get completed dates within the specified number of days counting back from today.
        let completedDatesWithinPeriod = completedDates.filter { $0.isWithinLastCustomDays(daysAgo: strengthCalculationPeriod) }
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
        let completedDatesWithoutLast30Days = completedDates.filter { $0.isWithinLastCustomDays(daysAgo: daysAgo) == false }
        let habitStrengthWithoutLast30Days = calculateStrengthPercentage(completedDates: completedDatesWithoutLast30Days)
        let strengthGainedInMonth = habitStrength - habitStrengthWithoutLast30Days
        return strengthGainedInMonth
    }
    
    func completionsWithinLastDays(daysAgo: Int) -> Int {
        completedDates.filter { $0.isWithinLastCustomDays(daysAgo: daysAgo) }.count
    }
}
