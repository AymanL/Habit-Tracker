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
//        List {
//            ForEach(habits) { habit in
//                HabitRowView(habit: habit)
//            }
//            
//            .listRowSeparator(.hidden)
//            .buttonStyle(.plain)
//            .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))
//        }
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Emoji:")
            Text(entry.emoji)
            
            Text(entry.habits.first?.title ?? "could not find any title")
        }
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
#Preview(as: .systemSmall) {
    HabitWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀", habits: [])
    SimpleEntry(date: .now, emoji: "🤩", habits: [])
}
