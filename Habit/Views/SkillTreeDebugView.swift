import SwiftUI

struct SkillTreeDebugView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingCreateTree = false
    @State private var newTreeName = ""
    @State private var newTreeDescription = ""
    
    var body: some View {
        List {
            Section("Debug Tools") {
                Button("Print All Entities") {
                    dataController.debugAllEntities()
                }
                
                Button("Print Skill Trees") {
                    dataController.debugSkillTrees()
                }
                
                Button("Print Skill Nodes") {
                    dataController.debugSkillNodes()
                }
                
                Button("Create Test Skill Tree") {
                    dataController.createTestSkillTree()
                }
                
                Button("Create Custom Tree") {
                    showingCreateTree = true
                }
            }
            
            Section("Sample Data") {
                let trees = dataController.getAllSkillTrees()
                ForEach(trees, id: \.id) { tree in
                    VStack(alignment: .leading) {
                        Text(tree.name)
                            .font(.headline)
                        Text(tree.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("\(tree.nodes.count) nodes")
                            Spacer()
                            Text("\(Int(tree.completionPercentage * 100))% complete")
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Skill Tree Debug")
        .sheet(isPresented: $showingCreateTree) {
            NavigationView {
                Form {
                    Section("Tree Details") {
                        TextField("Tree Name", text: $newTreeName)
                        TextField("Description", text: $newTreeDescription)
                    }
                }
                .navigationTitle("Create Skill Tree")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingCreateTree = false
                    },
                    trailing: Button("Create") {
                        if !newTreeName.isEmpty {
                            dataController.createSkillTree(name: newTreeName, description: newTreeDescription)
                            newTreeName = ""
                            newTreeDescription = ""
                            showingCreateTree = false
                        }
                    }
                    .disabled(newTreeName.isEmpty)
                )
            }
        }
    }
} 