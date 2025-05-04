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
            ForEach(habits) { habit in
                HabitRowView(habit: habit)
                    .id(habit.id)
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
            .listRowSeparator(.hidden)
            .buttonStyle(.plain)
            .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))
        }
        .listStyle(.plain)
    }
    
    private func deleteItems(offsets: IndexSet) {
        offsets.map { habits[$0] }.forEach(dataController.delete(_:))
        dataController.save()
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var updatedHabits = habits.map { $0 }
        updatedHabits.move(fromOffsets: source, toOffset: destination)
        
        // Update the order of all habits
        for (index, habit) in updatedHabits.enumerated() {
            habit.order = index
        }
        
        dataController.save()
    }
}

struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView(sortingOption: .byDate, isSortingOrderAscending: false)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .environmentObject(DataController.preview)
    }
}
