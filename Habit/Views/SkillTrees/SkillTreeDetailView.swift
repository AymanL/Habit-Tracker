import SwiftUI

struct SkillTreeDetailView: View {
    @ObservedObject var skillTree: SkillTree
    @EnvironmentObject var dataController: DataController
    @State private var showingAddNode = false
    @State private var selectedNode: SkillNode?
    @State private var searchText = ""
    
    var rootNode: SkillNode? {
        skillTree.nodes.filter { $0.isRootNode }.sorted { $0.order < $1.order }.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(skillTree.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if !skillTree.treeDescription.isEmpty {
                        Text(skillTree.treeDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Completion: \(Int(skillTree.completionPercentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Add Node") {
                            showingAddNode = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Tree visualization
                // SkillTreeVisualizationView(skillTree: skillTree) { node in
                //     selectedNode = node
                // }
            }
            .padding()
        }
        .navigationTitle("Skill Tree")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search nodes...")
        .sheet(isPresented: $showingAddNode) {
            NavigationView {
                EditSkillNodeView(skillTree: skillTree)
            }
        }
        .sheet(item: $selectedNode) { node in
            NavigationView {
                EditSkillNodeView(skillTree: skillTree, skillNode: node)
            }
        }
    }
}

#Preview {
    NavigationView {
        SkillTreeDetailView(skillTree: SkillTree.example)
            .environmentObject(DataController())
    }
} 