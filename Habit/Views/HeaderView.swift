//
//  HeaderView.swift
//  Habit
//
//  Created by Nazarii Zomko on 19.05.2023.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            Text("Habit")
                .font(.largeTitle.bold())
                .padding(.leading, 8)
            Spacer()
            HStack(spacing: 0) {
                ForEach(0..<7) { index in
                    let date = getDateForWeekday(index)
                    let dayInfo = getDayInfo(for: date)
                    
                    VStack(spacing: 0) {
                        Text("\(dayInfo.dayNumber)")
                        Text("\(dayInfo.dayName)")
                    }
                    .frame(width: Constants.dayOfTheWeekFrameSize, height: Constants.dayOfTheWeekFrameSize)
                    .font(.system(size: 11, weight: .bold))
                    .opacity(Calendar.current.isDateInToday(date) ? 1 : 0.5)
                }
            }
            .padding(.trailing, 10)
        }
        .padding([.top, .leading, .trailing])
        .padding(.bottom, 4)
        .accessibilityHidden(true)
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
    
    func getDayInfo(for date: Date) -> (dayNumber: String, dayName: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEEEE"
        let dayName = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "d"
        let dayNumber = dateFormatter.string(from: date)
        
        return (dayNumber: dayNumber, dayName: dayName)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
            .previewLayout(.sizeThatFits)
    }
}
