//
//  HabitListView.swift
//  Habit
//
//  Created by Nazarii Zomko on 30.07.2023.
//

import CoreData
import SwiftUI

struct HabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dataController: DataController
    
    @FetchRequest var habits: FetchedResults<Habit>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order_, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    init(sortingOption: SortingOption, isSortingOrderAscending: Bool) {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        
        switch sortingOption {
        case .byDate:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.creationDate_, ascending: isSortingOrderAscending)]
        case .byName:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.title_, ascending: isSortingOrderAscending)]
        case .byOrder:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.order_, ascending: true)]
        }
        
        _habits = FetchRequest<Habit>(fetchRequest: request)
    }
    
    var body: some View {
        List {
            UncategorizedHabitsSection(habits: habits, dataController: dataController)
            CategorizedHabitsSection(habits: habits, categories: categories, dataController: dataController)
        }
        .listStyle(.plain)
    }
}

private struct UncategorizedHabitsSection: View {
    let habits: FetchedResults<Habit>
    let dataController: DataController
    
    var body: some View {
        let uncategorizedHabits = habits.filter { $0.category == nil }
        if !uncategorizedHabits.isEmpty {
            Section {
                ForEach(uncategorizedHabits) { habit in
                    HabitRowView(habit: habit)
                        .id(habit.id)
                }
                .onDelete { indexSet in
                    deleteItems(offsets: indexSet, from: uncategorizedHabits)
                }
                .onMove { source, destination in
                    moveItems(from: source, to: destination, in: uncategorizedHabits)
                }
            } header: {
                Text("Uncategorized")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet, from habits: [Habit]) {
        offsets.map { habits[$0] }.forEach(dataController.delete(_:))
        dataController.save()
    }
    
    private func moveItems(from source: IndexSet, to destination: Int, in habits: [Habit]) {
        var revisedItems: [Habit] = habits.map { $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        // Update the order for each habit
        for (index, habit) in revisedItems.enumerated() {
            habit.order_ = Int64(index)
        }
        
        dataController.save()
    }
}

private struct CategorizedHabitsSection: View {
    let habits: FetchedResults<Habit>
    let categories: FetchedResults<Category>
    let dataController: DataController
    @State private var expandedCategories: Set<ObjectIdentifier>
    
    init(habits: FetchedResults<Habit>, categories: FetchedResults<Category>, dataController: DataController) {
        self.habits = habits
        self.categories = categories
        self.dataController = dataController
        // Initialize with all categories expanded
        _expandedCategories = State(initialValue: Set(categories.map { ObjectIdentifier($0) }))
    }
    
    var body: some View {
        ForEach(categories, id: \.id) { category in
            let categoryHabits = habits.filter { $0.category == category }
            if !categoryHabits.isEmpty {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedCategories.contains(ObjectIdentifier(category)) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedCategories.insert(ObjectIdentifier(category))
                            } else {
                                expandedCategories.remove(ObjectIdentifier(category))
                            }
                        }
                    ),
                    content: {
                        ForEach(categoryHabits) { habit in
                            HabitRowView(habit: habit)
                                .id(habit.id)
                        }
                        .onDelete { indexSet in
                            deleteItems(offsets: indexSet, from: categoryHabits)
                        }
                        .onMove { source, destination in
                            moveItems(from: source, to: destination, in: categoryHabits)
                        }
                    },
                    label: {
                        HStack {
                            Circle()
                                .fill(Color(HabitColor(rawValue: category.color_ ?? "blue") ?? .blue))
                                .frame(width: 12, height: 12)
                            Text(category.name_ ?? "")
                        }
                    }
                )
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet, from habits: [Habit]) {
        offsets.map { habits[$0] }.forEach(dataController.delete(_:))
        dataController.save()
    }
    
    private func moveItems(from source: IndexSet, to destination: Int, in habits: [Habit]) {
        var revisedItems: [Habit] = habits.map { $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        // Update the order for each habit
        for (index, habit) in revisedItems.enumerated() {
            habit.order_ = Int64(index)
        }
        
        dataController.save()
    }
}

struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView(sortingOption: .byOrder, isSortingOrderAscending: true)
            .environmentObject(DataController.preview)
    }
}
