import SwiftUI

struct SkillTreeListView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddSkillTree = false
    @State private var searchText = ""
    
    @FetchRequest(
        entity: SkillTree.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SkillTree.creationDate_, ascending: false)]
    ) var skillTrees: FetchedResults<SkillTree>
    
    var filteredSkillTrees: [SkillTree] {
        if searchText.isEmpty {
            return Array(skillTrees)
        } else {
            return skillTrees.filter { tree in
                (tree.name.localizedCaseInsensitiveContains(searchText) ||
                 tree.treeDescription.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSkillTrees) { tree in
                    NavigationLink(destination: SkillTreeDetailView(skillTree: tree)) {
                        SkillTreeRowView(skillTree: tree)
                    }
                }
                .onDelete(perform: deleteSkillTrees)
            }
            .searchable(text: $searchText, prompt: "Search skill trees...")
            .navigationTitle("Skill Trees")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
            .navigationBarItems(trailing: Button("Add") {
                showingAddSkillTree = true
            })
            .sheet(isPresented: $showingAddSkillTree) {
                NavigationView {
                    EditSkillTreeView()
                }
            }
            .overlay {
                if filteredSkillTrees.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tree")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Skill Trees")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text(searchText.isEmpty ? 
                            "Create your first skill tree to get started" : 
                            "No skill trees match your search"
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
    
    private func deleteSkillTrees(offsets: IndexSet) {
        for index in offsets {
            let tree = filteredSkillTrees[index]
            dataController.deleteSkillTree(tree)
        }
    }
}

struct SkillTreeRowView: View {
    @ObservedObject var skillTree: SkillTree
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(skillTree.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !skillTree.treeDescription.isEmpty {
                        Text(skillTree.treeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(skillTree.completedNodesCount)/\(skillTree.totalNodesCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: skillTree.completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 60)
                }
            }
            
            HStack {
                Label("\(skillTree.nodes.count) nodes", systemImage: "circle.grid.2x2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(skillTree.creationDate.formatted(date: .abbreviated, time: .omitted))
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