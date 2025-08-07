import SwiftUI

struct SkillTreeDebugView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingCreateTree = false
    @State private var newTreeName = ""
    @State private var newTreeDescription = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Skill Tree Debug")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Debug buttons
                    VStack(spacing: 12) {
                        Button("Debug All Entities") {
                            dataController.debugAllEntities()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Debug Skill Trees") {
                            dataController.debugSkillTrees()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Debug Skill Nodes") {
                            dataController.debugSkillNodes()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Debug Core Data State") {
                            dataController.debugCoreDataState()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Test skill tree creation
                    VStack(spacing: 12) {
                        Text("Test Functions")
                            .font(.headline)
                        
                        Button("Create Test Skill Tree") {
                            dataController.createTestSkillTree()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Create Sample Data") {
                            do {
                                try dataController.createSampleData()
                            } catch {
                                print("❌ Error creating sample data: \(error)")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Current state display
                    VStack(spacing: 12) {
                        Text("Current State")
                            .font(.headline)
                        
                        let trees = dataController.getAllSkillTrees()
                        let nodes = dataController.getAllSkillNodes()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Skill Trees: \(trees.count)")
                            Text("Skill Nodes: \(nodes.count)")
                            
                            if !trees.isEmpty {
                                Text("Sample Tree: \(trees.first?.name ?? "Unknown")")
                            }
                            
                            if !nodes.isEmpty {
                                Text("Sample Node: \(nodes.first?.name ?? "Unknown")")
                            }
                        }
                        .font(.caption)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .padding()
    }
} 