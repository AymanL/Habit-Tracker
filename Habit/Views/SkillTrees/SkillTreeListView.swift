import SwiftUI

struct SkillTreeListView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddForest = false
    @State private var searchText = ""
    
    @FetchRequest(
        entity: Forest.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Forest.creationDate_, ascending: false)]
    ) var forests: FetchedResults<Forest>
    
    var filteredForests: [Forest] {
        if searchText.isEmpty {
            return Array(forests)
        } else {
            return forests.filter { forest in
                ((forest.name_ ?? "").localizedCaseInsensitiveContains(searchText) ||
                 (forest.description_ ?? "").localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredForests) { forest in
                    NavigationLink(destination: ForestDetailView(forest: forest)) {
                        ForestRowView(forest: forest)
                    }
                }
                .onDelete(perform: deleteForests)
            }
            .searchable(text: $searchText, prompt: "Search forests...")
            .navigationTitle("Forests")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
            .navigationBarItems(trailing: Button("Add") {
                showingAddForest = true
            })
            .sheet(isPresented: $showingAddForest) {
                NavigationView {
                    EditForestView()
                }
            }
            .overlay {
                if filteredForests.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tree.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Forests")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text(searchText.isEmpty ? 
                            "Create your first forest to get started" : 
                            "No forests match your search"
                        )
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
        }
    }
    
    private func deleteForests(offsets: IndexSet) {
        for index in offsets {
            let forest = filteredForests[index]
            dataController.deleteForest(forest)
        }
    }
    
}

// MARK: - Helper Functions

private func calculateForestCompletion(for forest: Forest) -> Double {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    guard !trees.isEmpty else { return 0.0 }
    let totalCompletion = trees.reduce(0.0) { sum, tree in
        sum + tree.completionPercentage
    }
    return totalCompletion / Double(trees.count)
}

private func calculateCompletedTreesCount(for forest: Forest) -> Int {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    return trees.filter { $0.completionPercentage == 1.0 }.count
}

private func calculateTotalTreesCount(for forest: Forest) -> Int {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    return trees.count
}

private func calculateTotalNodesCount(for forest: Forest) -> Int {
    let trees = forest.trees_?.allObjects as? [SkillTree] ?? []
    return trees.reduce(0) { sum, tree in
        sum + tree.totalNodesCount
    }
}

struct ForestRowView: View {
    @ObservedObject var forest: Forest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(forest.name_ ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = forest.description_, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(calculateCompletedTreesCount(for: forest))/\(calculateTotalTreesCount(for: forest))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: calculateForestCompletion(for: forest))
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 60)
                }
            }
            
            HStack {
                Label("\(calculateTotalNodesCount(for: forest)) nodes", systemImage: "circle.grid.2x2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text((forest.creationDate_ ?? Date()).formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SkillTreeListView()
        .environmentObject(DataController.preview)
} 