import Foundation
import CoreData

extension Habit {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
        return NSFetchRequest<Habit>(entityName: "Habit")
    }

    @NSManaged public var color_: String?
    @NSManaged public var completedDates_: [Date]?
    @NSManaged public var creationDate_: Date?
    @NSManaged public var dailyCounters_: [Date: Int]?
    @NSManaged public var duration_: Int32
    @NSManaged public var durationHistory_: String?
    @NSManaged public var id_: UUID?
    @NSManaged public var isWeekly_: Bool
    @NSManaged public var motivation_: String?
    @NSManaged public var order_: Int64
    @NSManaged public var title_: String?
    @NSManaged public var type_: String?
}

// MARK: - Generated accessors for completedDates_
extension Habit {
    @objc(addCompletedDates_Object:)
    @NSManaged public func addToCompletedDates_(_ value: Date)

    @objc(removeCompletedDates_Object:)
    @NSManaged public func removeFromCompletedDates_(_ value: Date)

    @objc(addCompletedDates_:)
    @NSManaged public func addToCompletedDates_(_ values: NSSet)

    @objc(removeCompletedDates_:)
    @NSManaged public func removeFromCompletedDates_(_ values: NSSet)
}

// MARK: - Generated accessors for dailyCounters_
extension Habit {
    @objc(addDailyCounters_Object:)
    @NSManaged public func addToDailyCounters_(_ value: NSDate)

    @objc(removeDailyCounters_Object:)
    @NSManaged public func removeFromDailyCounters_(_ value: NSDate)

    @objc(addDailyCounters_:)
    @NSManaged public func addToDailyCounters_(_ values: NSSet)

    @objc(removeDailyCounters_:)
    @NSManaged public func removeFromDailyCounters_(_ values: NSSet)
}

// MARK: - Convenience Properties
extension Habit {
    var color: String {
        get { color_ ?? "blue" }
        set { color_ = newValue }
    }
    
    var completedDates: [Date] {
        get { completedDates_ ?? [] }
        set { completedDates_ = newValue }
    }
    
    var creationDate: Date {
        get { creationDate_ ?? Date() }
        set { creationDate_ = newValue }
    }
    
    var dailyCounters: [Date: Int] {
        get { dailyCounters_ ?? [:] }
        set { dailyCounters_ = newValue }
    }
    
    var duration: Int? {
        get { duration_ == 0 ? nil : Int(duration_) }
        set { duration_ = Int32(newValue ?? 0) }
    }
    
    var durationHistory: [HabitDuration] {
        get {
            guard let data = durationHistory_?.data(using: .utf8),
                  let history = try? JSONDecoder().decode([HabitDuration].self, from: data) else {
                return []
            }
            return history
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                durationHistory_ = String(data: data, encoding: .utf8)
            }
        }
    }
    
    var id: UUID {
        get { id_ ?? UUID() }
        set { id_ = newValue }
    }
    
    var isWeekly: Bool {
        get { isWeekly_ }
        set { isWeekly_ = newValue }
    }
    
    var motivation: String {
        get { motivation_ ?? "" }
        set { motivation_ = newValue }
    }
    
    var order: Int {
        get { Int(order_) }
        set { order_ = Int64(newValue) }
    }
    
    var title: String {
        get { title_ ?? "" }
        set { title_ = newValue }
    }
    
    var type: HabitType {
        get { HabitType(rawValue: type_ ?? "") ?? .boolean }
        set { type_ = newValue.rawValue }
    }
}

// MARK: - Time Tracking
extension Habit {
    func effectiveDuration(for date: Date) -> Int {
        // Get all durations that were active on this date
        let activeDurations = durationHistory.filter { duration in
            let effectiveDate = duration.effectiveDate
            let expirationDate = duration.expirationDate ?? .distantFuture
            return date >= effectiveDate && date < expirationDate
        }
        
        // If no durations were active, return 0
        guard let lastActiveDuration = activeDurations.last else {
            return 0
        }
        
        return lastActiveDuration.duration
    }
    
    func getTotalTimeSpent() -> Int {
        // For each completed date, calculate the time spent
        return completedDates.reduce(0) { total, date in
            let duration = effectiveDuration(for: date)
            let count = type == .counter ? counterValue(for: date) : 1
            return total + (duration * count)
        }
    }
    
    func getTotalTimeSpentInLastMonth() -> Int {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        return completedDates
            .filter { $0 >= thirtyDaysAgo }
            .reduce(0) { total, date in
                let duration = effectiveDuration(for: date)
                let count = type == .counter ? counterValue(for: date) : 1
                return total + (duration * count)
            }
    }
    
    func getTotalTimeSpentInLastYear() -> Int {
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        
        return completedDates
            .filter { $0 >= oneYearAgo }
            .reduce(0) { total, date in
                let duration = effectiveDuration(for: date)
                let count = type == .counter ? counterValue(for: date) : 1
                return total + (duration * count)
            }
    }
} 