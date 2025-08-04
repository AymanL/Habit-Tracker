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
    @State private var isPresentingSettingsView = false
    @Environment(\.scenePhase) var scenePhase

    @State private var exportURL: URL?
    @AppStorage("sortingOption") private var sortingOption: SortingOption = .byOrder
    @AppStorage("isSortingOrderAscending") private var isSortingOrderAscending = false
    @State private var currentDate = Date()
    @State private var timer: Timer?
    
    var body: some View {
        TabView {
            // Habits Tab
            HabitsView(
                showingAddHabit: $showingAddHabit,
                showingCategories: $showingCategories,
                isPresentingSettingsView: $isPresentingSettingsView,
                currentDate: $currentDate
            )
            .tabItem {
                Label("Habits", systemImage: "list.bullet")
            }
            
            // Skill Trees Tab
            SkillTreesView()
                .tabItem {
                    Label("Skill Trees", systemImage: "tree")
                }
        }
        .onAppear {
            startDateRefreshTimer()
        }
        .onDisappear {
            stopDateRefreshTimer()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Refresh the current date when app becomes active
                currentDate = Date()
            }
        }
    }
    
    private func startDateRefreshTimer() {
        // Stop any existing timer
        stopDateRefreshTimer()
        
        // Create a timer that fires every minute to check for day changes
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let newDate = Date()
            let calendar = Calendar.current
            
            // Check if the day has changed
            if !calendar.isDate(currentDate, inSameDayAs: newDate) {
                currentDate = newDate
                // Force UI refresh by updating the environment
                dataController.objectWillChange.send()
            }
        }
    }
    
    private func stopDateRefreshTimer() {
        timer?.invalidate()
        timer = nil
    }    
}

// MARK: - Habits View (Current Functionality)
struct HabitsView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var showingAddHabit: Bool
    @Binding var showingCategories: Bool
    @Binding var isPresentingSettingsView: Bool
    @AppStorage("sortingOption") private var sortingOption: SortingOption = .byOrder
    @AppStorage("isSortingOrderAscending") private var isSortingOrderAscending = false
    @Binding var currentDate: Date
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Divider()
                HeaderView()
                HabitListView(sortingOption: sortingOption, isSortingOrderAscending: isSortingOrderAscending)
            }
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
                        
                        Button(action: { isPresentingSettingsView = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                EditHabitView()
            }
            .sheet(isPresented: $showingCategories) {
                CategoryListView()
            }
            .sheet(isPresented: $isPresentingSettingsView) {
                NavigationView {
                    SettingsView()
                }
            }
        }
    }
}

// MARK: - Skill Trees View
struct SkillTreesView: View {
    var body: some View {
        SkillTreeListView()
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
