//
//  Date+Ext.swift
//  Habit
//
//  Created by Nazarii Zomko on 28.06.2023.
//

import Foundation

// MARK: - Custom Day Reset Calendar
struct CustomDayResetCalendar {
    static let shared = CustomDayResetCalendar()
    
    private var dayResetHour: Int {
        UserDefaults.standard.integer(forKey: "dayResetHour")
    }
    
    private init() {}
    
    /// Returns the start of the custom day for a given date
    /// If dayResetHour is 4, then 3am on Saturday counts as Friday
    func startOfCustomDay(for date: Date) -> Date {
        let calendar = Calendar.current
        let dayResetHour = self.dayResetHour
        
        // Get the date components for the given date
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // If the current hour is before the reset hour, we're still in the previous day
        let currentHour = calendar.component(.hour, from: date)
        if currentHour < dayResetHour {
            // We're in the previous day, so subtract one day
            components.day = (components.day ?? 1) - 1
        }
        
        // Set the time to the reset hour
        components.hour = dayResetHour
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        
        return calendar.date(from: components) ?? date
    }
    
    /// Checks if two dates are in the same custom day
    func isDate(_ date1: Date, inSameCustomDayAs date2: Date) -> Bool {
        let start1 = startOfCustomDay(for: date1)
        let start2 = startOfCustomDay(for: date2)
        return Calendar.current.isDate(start1, inSameDayAs: start2)
    }
    
    /// Returns the current custom day (adjusted for reset hour)
    func currentCustomDay() -> Date {
        return startOfCustomDay(for: Date())
    }
    
    /// Returns a date that is N days ago from the current custom day
    func customDayMinusDaysAgo(daysAgo: Int) -> Date {
        let currentCustomDay = self.currentCustomDay()
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: currentCustomDay) ?? Date()
    }
}

extension Date {
    func isInSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isInSameCustomDay(as date: Date) -> Bool {
        CustomDayResetCalendar.shared.isDate(self, inSameCustomDayAs: date)
    }
    
    static func todayMinusDaysAgo(daysAgo: Int) -> Date {
        let today = Date.now
        let todayMinusDaysAgo = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
        return todayMinusDaysAgo
    }
    
    static func customDayMinusDaysAgo(daysAgo: Int) -> Date {
        return CustomDayResetCalendar.shared.customDayMinusDaysAgo(daysAgo: daysAgo)
    }
    
    func isWithinLastDays(daysAgo: Int) -> Bool {
        let daysAgoDate = Date.todayMinusDaysAgo(daysAgo: daysAgo)
        if self.isInSameDay(as: daysAgoDate) { return true }
        return self >= daysAgoDate && self <= Date.now
    }
    
    func isWithinLastCustomDays(daysAgo: Int) -> Bool {
        let daysAgoDate = Date.customDayMinusDaysAgo(daysAgo: daysAgo)
        if self.isInSameCustomDay(as: daysAgoDate) { return true }
        return self >= daysAgoDate && self <= Date.now
    }
    
    // For previewing purposes only.
    static func getRandomDates(maxDaysBack: Int, chanceFrom0To100: Int = 60) -> [Date] {
        var dates: [Date] = []
        let today = Date.now
        
        for daysBack in 0..<maxDaysBack {
            let shouldAddDate = Int.random(in: 1...100) <= chanceFrom0To100 // returns true with a chance of ..%
            
            if shouldAddDate {
                let todayMinusDaysBack = Calendar.current.date(byAdding: .day, value: -daysBack, to: today)!
                dates.append(todayMinusDaysBack)
            }
        }
        return dates
    }
}

// Source: https://stackoverflow.com/a/33397770
extension Date {
    func next(_ weekday: Weekday, considerToday: Bool = false) -> Date {
        return get(.next,
                   weekday,
                   considerToday: considerToday)
    }
    
    func previous(_ weekday: Weekday, considerToday: Bool = false) -> Date {
        return get(.previous,
                   weekday,
                   considerToday: considerToday)
    }
    
    func get(_ direction: SearchDirection,
             _ weekDay: Weekday,
             considerToday consider: Bool = false) -> Date {
        
        let dayName = weekDay.rawValue
        
        let weekdaysName = getWeekDaysInEnglish().map { $0.lowercased() }
        
        assert(weekdaysName.contains(dayName), "weekday symbol should be in form \(weekdaysName)")
        
        let searchWeekdayIndex = weekdaysName.firstIndex(of: dayName)! + 1
        
        let calendar = Calendar(identifier: .gregorian)
        
        if consider && calendar.component(.weekday, from: self) == searchWeekdayIndex {
            return self
        }
        
        var nextDateComponent = calendar.dateComponents([.hour, .minute, .second], from: self)
        nextDateComponent.weekday = searchWeekdayIndex
        
        let date = calendar.nextDate(after: self,
                                     matching: nextDateComponent,
                                     matchingPolicy: .nextTime,
                                     direction: direction.calendarSearchDirection)
        
        return date!
    }
    
}

// MARK: Helper methods
extension Date {
    func getWeekDaysInEnglish() -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar.weekdaySymbols
    }
    
    enum Weekday: String {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    }
    
    enum SearchDirection {
        case next
        case previous
        
        var calendarSearchDirection: Calendar.SearchDirection {
            switch self {
            case .next:
                return .forward
            case .previous:
                return .backward
            }
        }
    }
}

extension Date {
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
}


extension [Date] {
    func removingDuplicates() -> [Date] {
        var uniqueDates: [Date] = []
        var uniqueDateSet: Set<String> = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for date in self {
            let dateString = dateFormatter.string(from: date)
            if !uniqueDateSet.contains(dateString) {
                uniqueDateSet.insert(dateString)
                uniqueDates.append(date)
            }
        }

        return uniqueDates
    }
    
    var asDateComponents: [DateComponents] {
        self.map { date in
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            dateComponents.timeZone = TimeZone.current
            dateComponents.calendar = Calendar(identifier: .gregorian)
            return dateComponents
        }
    }
}

extension [DateComponents] {
    var asDates: [Date] {
        self.compactMap { dateComponents in
            dateComponents.date
        }
    }
}

extension DateComponents {
    var date: Date {
        Calendar.current.date(from: self)!
    }
    
    func isInSameDay(as dateComponents: DateComponents) -> Bool {
        Calendar.current.isDate(self.date, inSameDayAs: dateComponents.date)
    }
}


