import Foundation

struct HolidayRange: Codable, Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let name: String
    
    init(startDate: Date, endDate: Date, name: String = "") {
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = Calendar.current.startOfDay(for: endDate)
        self.name = name
    }
    
    /// Checks if a given date falls within this holiday range
    func contains(_ date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return normalizedDate >= startDate && normalizedDate <= endDate
    }
    
    /// Returns all dates within this holiday range
    func getAllDates() -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
} 