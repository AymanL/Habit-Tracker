import Foundation

struct HabitDuration: Codable {
    let minutes: Int
    let effectiveDate: Date
    var expirationDate: Date?
    
    init(minutes: Int, effectiveDate: Date, expirationDate: Date? = nil) {
        self.minutes = minutes
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= effectiveDate && (expirationDate == nil || now <= expirationDate!)
    }
    
    func isActiveOn(_ date: Date) -> Bool {
        return date >= effectiveDate && (expirationDate == nil || date <= expirationDate!)
    }
} 