//
//  HabitWidget.swift
//  HabitWidget
//
//  Created by Utku, YE (Yusuf Eren) on 23/09/2024.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    /// Access to CoreDataManger
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀", habits: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀", habits: [])
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        //        for hourOffset in 0 ..< 5 {
        //            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
        //            let entry = SimpleEntry(date: entryDate, emoji: "😀", habits: [])
        //            entries.append(entry)
        //        }
        entries.append(SimpleEntry(date:currentDate, emoji: "🏖️", habits: fetchHabits()))
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
    func fetchHabits() -> [Habit] {
        return DataController.shared.getAllHabits()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
    let habits: [Habit]
}

struct HabitWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            HeaderView()
            ForEach(entry.habits) { habit in
                HabitRowView(habit: habit)
            }
        }
        //        List {
        //            ForEach(habits) { habit in
        //                HabitRowView(habit: habit)
        //            }
        //
        //            .listRowSeparator(.hidden)
        //            .buttonStyle(.plain)
        //            .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))
        //        }
        //        VStack {
        //            Text("Time:")
        //            Text(entry.date, style: .time)
        //
        //            Text("Emoji:")
        //            Text(entry.emoji)
        //
        //            Text(entry.habits.first?.title ?? "could not find any title")
        //        }
    }
}


struct HeaderView: View {
    var body: some View {
        HStack {
            //            Text("Habit")
            //                .font(.largeTitle.bold())
            //                .padding(.leading, 8) // 12 or 8?
            Spacer()
            HStack(spacing: 2.5) {
                ForEach(0..<5) { number in
                    let daysAgo = abs(number - 4) // reverse order
                    let dayInfo = getDayInfo(daysAgo: daysAgo)
                    
                    VStack(spacing: 0) {
                        Text("\(dayInfo.dayNumber)")
                        Text("\(dayInfo.dayName)")
                    }
                    .frame(width: Constants.dayOfTheWeekFrameSize, height: Constants.dayOfTheWeekFrameSize)
                    .font(.system(size: 12, weight: .bold))
                    .opacity(daysAgo == 0 ? 1 : 0.5)
                }
            }
            //            .padding(.trailing, 10)
        }
        .padding(.trailing, 2)
        //        .padding([.top, .leading, .trailing])
        //        .padding(.bottom, 4)
        .accessibilityHidden(true)
    }
    
    func getDayInfo(daysAgo: Int) -> (dayNumber: String, dayName: String) {
        let today = Date.now
        let todayMinusDaysAgo = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
        
        let dateFormatter = DateFormatter()
        //        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEEEEE"
        let dayName = dateFormatter.string(from: todayMinusDaysAgo)
        
        dateFormatter.dateFormat = "d"
        let dayNumber = dateFormatter.string(from: todayMinusDaysAgo)
        
        return (dayNumber: dayNumber, dayName: dayName)
    }
}

struct HabitRowView: View {
    @ObservedObject var habit: Habit
    @State private var isPresentingEditHabitView = false
    @EnvironmentObject var dataController: DataController
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack() {
                habitTitle
                //                        .padding(.horizontal, 22)
                    .allowsHitTesting(false)
                Spacer()
                checkmarksView
                                        .padding(.trailing, 12)
            }
                            .padding(.leading, 22)
            //                .padding(.top, 12)
            //
                            .frame(maxHeight: .infinity)
            
        }
        //        .frame(height: 95)
                .clipShape(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        //        .sheet(isPresented: $isPresentingEditHabitView) {
        //            DetailView(habit: habit)
        //        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(habit.title), \(habit.strengthPercentage)% strength, \(habit.isCompleted(daysAgo: 0) ? "completed" : "not completed") for today.")
        .accessibilityAction(named: "Toggle completion for today") {
            toggleCompletion(daysAgo: 0)
            UIAccessibility.post(notification: .announcement, argument: "\(habit.isCompleted(daysAgo: 0) ? "completed" : "not completed")")
        }
    }
    
    var checkmarksView: some View {
        HStack(spacing: 24) {
            ForEach(0..<5) {number in
                let daysAgo = abs(number - 4) // reverse order
                Button {
                    toggleCompletion(daysAgo: daysAgo)
                } label: {
                    let isCompleted = habit.isCompleted(daysAgo: daysAgo)
                    Image(isCompleted ? "checkmark" : "circle")
                        .resizable()
                        .foregroundColor(.primary) // For this to work, set rendering mode to Template inside Attributes Inspector for the image.
                                            .padding(isCompleted ? 0 : 1)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.dayOfTheWeekFrameSize/2, height: Constants.dayOfTheWeekFrameSize/2)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .frame(width: Constants.dayOfTheWeekFrameSize/3, height: Constants.dayOfTheWeekFrameSize/3)
            }
        }
    }
    
    var habitTitle: some View {
        Text(habit.title)
            .font(.custom("", size: 19, relativeTo: .title3))
            .lineLimit(2)
            .if(colorScheme == .dark) { $0.shadow(radius: 3) }
    }
    
    func toggleCompletion(daysAgo: Int) {
        habit.toggleCompletion(daysAgo: daysAgo)
        //        HapticController.shared.impact(style: .soft)
        dataController.save()
    }
}

struct HabitWidget: Widget {
    let kind: String = "HabitWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HabitWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HabitWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    HabitWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀", habits: [Habit(context: DataController.preview.container.viewContext, title: "Habit 1", motivation: "", color: HabitColor.randomColor), Habit(context: DataController.preview.container.viewContext, title: "Habit 2", motivation: "", color: HabitColor.randomColor), Habit(context: DataController.preview.container.viewContext, title: "Habit 3", motivation: "", color: HabitColor.randomColor)])
    //    SimpleEntry(date: .now, emoji: "🤩", habits: [])
}
