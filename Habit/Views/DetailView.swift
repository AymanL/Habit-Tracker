//
//  DetailView.swift
//  Habit
//
//  Created by Nazarii Zomko on 21.07.2023.
//

import SwiftUI


struct DetailView: View {
    @ObservedObject var habit: Habit
    @AppStorage("overviewPageIndex") private var overviewPageIndex = 0
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isPresentingEditHabitView = false
    
    private var habitInstance: Habit {
        habit
    }
    
    private var completedDates: Binding<[Date]> {
        Binding(
            get: { habit.completedDates },
            set: { newDates in
                habit.completedDates = newDates
                try? viewContext.save()
            }
        )
    }
    
    @EnvironmentObject var dataController: DataController
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                regularityAndReminder
                overview
                
                ChartView(
                    dates: habit.completedDates,
                    color: habit.color,
                    counterValues: habit.dailyCounters
                )
                    .frame(height: 200)
                    .padding()
                
                CalendarView(
                    dateInterval: DateInterval(start: .distantPast, end: Date()),
                    completedDates: $habit.completedDates,
                    color: habit.color,
                    habit: habit
                )
            }
            .navigationTitle("\(habit.title)")
            .toolbarBackground(Color(habit.color), for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    NavigationLink("Edit") {
                        EditHabitView(habit: habit)
                    }
                    .foregroundColor(.black)
                    .accessibilityIdentifier("editHabit")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .onAppear {
                setupAppearance()
            }
        }
    }
    
    var regularityAndReminder: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("REGULARITY")
                    .font(.caption.bold())
                Text("every day")
            }
            .padding(.leading)
            .padding(.trailing, 70)
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading) {
                Text("REMIND ME")
                    .font(.caption.bold())
                Text("--:--")
            }
            .accessibilityElement(children: .combine)

            Spacer()
        }
        .foregroundColor(.black)
        .padding(.top, 40)
        .padding(.bottom, 15)
        .background(alignment: .bottom, content: {
            Color(habit.color)
                .frame(height: 500)
        })
    }
    
    var overview: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $overviewPageIndex) {
                // Note: There is no point in calculating strength gained in last year because with current formula strengthGainedInYear will always be equal to strengthPercentage.
                let strength = habitInstance.strengthPercentage
                let monthStrength = habitInstance.strengthGainedWithinLastDays(daysAgo: 30)
                let yearStrength = habitInstance.strengthGainedWithinLastDays(daysAgo: 365)
                
                OverviewView(
                    title: "Habit Strength",
                    mainText: "\(strength)%",
                    secondaryText1: "Month: +\(monthStrength)%",
                    secondaryText2: "Year: +\(yearStrength)%"
                )
                .tag(0)
                .accessibilityElement(children: .combine)
                
                let completedCount = habitInstance.isWeekly ? 
                    habitInstance.completedDates.count / 7 : 
                    habitInstance.completedDates.count
                let monthCompletions = habitInstance.isWeekly ? 
                    habitInstance.completionsWithinLastDays(daysAgo: 30) / 7 : 
                    habitInstance.completionsWithinLastDays(daysAgo: 30)
                let yearCompletions = habitInstance.isWeekly ? 
                    habitInstance.completionsWithinLastDays(daysAgo: 365) / 7 : 
                    habitInstance.completionsWithinLastDays(daysAgo: 365)
                
                OverviewView(
                    title: "Completions",
                    mainText: "\(completedCount)",
                    secondaryText1: "Month: +\(monthCompletions)",
                    secondaryText2: "Year: +\(yearCompletions)"
                )
                .tag(1)
                .accessibilityElement(children: .combine)

                let streak = habitInstance.streak
                let longestStreak = habitInstance.longestStreak
                
                OverviewView(
                    title: "Streak",
                    mainText: "\(streak) \(habitInstance.isWeekly ? "weeks" : "days")",
                    secondaryText1: "Longest Streak: \(longestStreak) \(habitInstance.isWeekly ? "weeks" : "days")",
                    secondaryText2: ""
                )
                .tag(2)
                .accessibilityElement(children: .combine)
                
                let totalTime = habitInstance.getTotalTimeSpent()
                let monthTime = habitInstance.getTotalTimeSpentInLastMonth()
                let yearTime = habitInstance.getTotalTimeSpentInLastYear()
                
                OverviewView(
                    title: "Time Spent",
                    mainText: formatTime(totalTime),
                    secondaryText1: "Month: \(formatTime(monthTime))",
                    secondaryText2: "Year: \(formatTime(yearTime))"
                )
                .tag(3)
                .accessibilityElement(children: .combine)
            }
            .tabViewStyle(.page)
            .frame(height: 190)
            
            Text("OVERVIEW")
                .font(.caption.bold())
                .padding()
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    func setupAppearance() {
        // Fixes SwiftUI bug where paging dots are white in Light Mode.
        let color = UIColor.label
        UIPageControl.appearance().currentPageIndicatorTintColor = color
        UIPageControl.appearance().pageIndicatorTintColor = color.withAlphaComponent(0.4)
    }
    
    struct OverviewView: View {
        var title: String
        var mainText: String
        var secondaryText1: String
        var secondaryText2: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.title3.bold())
                HStack() {
                    VStack(alignment: .leading) {
                        VStack() {
                            Text(mainText)
                                .font(.system(size: 50).bold())
                        }
                        HStack {
                            Text(secondaryText1)
                                .padding(.trailing, 60)
                            Text(secondaryText2)
                        }
                    }
                    .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailView(habit: Habit.example)
                .previewDisplayName("Boolean Habit")
            
            DetailView(habit: Habit.counterExample)
                .previewDisplayName("Counter Habit")
        }
        .previewLayout(.sizeThatFits)
    }
}


