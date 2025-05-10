//
//  ContentView.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddHabit = false
    @State private var showingCategories = false
    @State private var sortingOption: SortingOption = .byOrder
    @State private var isSortingOrderAscending = true
    
    var body: some View {
        NavigationView {
            HabitListView(sortingOption: sortingOption, isSortingOrderAscending: isSortingOrderAscending)
                .navigationTitle("Habits")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button(action: { sortingOption = .byDate }) {
                                Label("Sort by Date", systemImage: "calendar")
                            }
                            Button(action: { sortingOption = .byName }) {
                                Label("Sort by Name", systemImage: "textformat")
                            }
                            Button(action: { sortingOption = .byOrder }) {
                                Label("Sort by Order", systemImage: "arrow.up.arrow.down")
                            }
                            
                            Divider()
                            
                            Button(action: { isSortingOrderAscending.toggle() }) {
                                Label(isSortingOrderAscending ? "Sort Descending" : "Sort Ascending",
                                      systemImage: isSortingOrderAscending ? "arrow.down" : "arrow.up")
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: { showingCategories = true }) {
                                Label("Categories", systemImage: "folder")
                            }
                            
                            Button(action: { showingAddHabit = true }) {
                                Label("Add Habit", systemImage: "plus")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingAddHabit) {
                    NavigationView {
                        EditHabitView()
                    }
                }
                .sheet(isPresented: $showingCategories) {
                    NavigationView {
                        CategoryListView()
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iPhone 14 Pro Max")
            .environment(\.locale, .init(identifier: "uk"))
        
        ContentView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
