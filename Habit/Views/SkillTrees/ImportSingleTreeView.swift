import SwiftUI
import UniformTypeIdentifiers

struct ImportSingleTreeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    let forest: Forest
    
    @State private var textInput = ""
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var importResult: ImportResult?
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Import Tree")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Import a single tree into '\(forest.name_ ?? "Forest")'")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Text Input Area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tree Structure")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextEditor(text: $textInput)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Format Instructions:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• First line: Tree name (no dashes)")
                        Text("• Second level: 1 dash (-)")
                        Text("• Third level: 2 dashes (--)")
                        Text("• Fourth level: 3 dashes (---)")
                        Text("• And so on...")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Example
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example:")
                        .font(.headline)
                    
                    Text("""
                    Swift Development
                    - Learn Swift Basics
                    - Understand Optionals
                    - Master Closures
                    - Build Simple Apps
                    - Advanced Swift Features
                    -- Protocol-Oriented Programming
                    -- Generics and Type Constraints
                    -- Memory Management
                    """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: importFromText) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Import Tree")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Import from File")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Import Tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.text, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        let content = try String(contentsOf: url)
                        textInput = content
                        importFromText()
                    } catch {
                        alertTitle = "Error"
                        alertMessage = "Failed to read file: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            case .failure(let error):
                alertTitle = "Error"
                alertMessage = "Failed to import file: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPreview) {
            if let result = importResult {
                SingleTreeImportPreviewView(result: result) {
                    dismiss()
                }
            }
        }
    }
    
    private func importFromText() {
        do {
            let result = try parseAndImport(textInput)
            importResult = result
            showingPreview = true
        } catch {
            alertTitle = "Import Error"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func parseAndImport(_ text: String) throws -> ImportResult {
        print("🔍 Starting single tree parsing...")
        print("📝 Raw text input:")
        print(text)
        print("---")
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        // Minimum valid single-tree content: at least a tree name
        // If only one line is provided, we will create the tree and a single child under root to help users get started
        
        print("📋 Parsed lines (\(lines.count) total):")
        for (index, line) in lines.enumerated() {
            print("  Line \(index + 1): '\(line)'")
        }
        print("---")
        
        guard lines.count >= 1 else {
            throw ImportError.invalidFormat("At least one line (tree name) is required")
        }
        
        let context = dataController.container.viewContext
        var trees: [SkillTree] = []
        var currentTree: SkillTree?
        var nodeStack: [(SkillNode, Int)] = []
        
        print("🔄 Starting line-by-line processing...")
        
        func parseTaggedContent(_ raw: String, defaultType: SkillNodeType) -> (String, SkillNodeType) {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("["), let close = trimmed.firstIndex(of: "]") else {
                return (trimmed, defaultType)
            }
            let tagRange = trimmed.index(after: trimmed.startIndex)..<close
            let tag = String(trimmed[tagRange]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let remainder = trimmed.index(after: close)..<trimmed.endIndex
            let name = String(trimmed[remainder]).trimmingCharacters(in: .whitespaces)
            let mapping: [String: SkillNodeType] = [
                "goal": .goal,
                "g": .goal,
                "action": .activity,
                "activity": .activity,
                "a": .activity,
                "boss": .boss,
                "boss fight": .boss,
                "bossfight": .boss
            ]
            let type = mapping[tag] ?? defaultType
            return (name.isEmpty ? trimmed : name, type)
        }

        for (index, line) in lines.enumerated() {
            let dashCount = line.prefix(while: { $0 == "-" }).count
            let content = String(line.dropFirst(dashCount)).trimmingCharacters(in: .whitespaces)
            
            print("📄 Processing line \(index + 1): '\(line)'")
            print("  Dash count: \(dashCount)")
            print("  Content: '\(content)'")
            
            guard !content.isEmpty else { 
                print("  ⏭️ Skipping empty content")
                continue 
            }
            
            switch dashCount {
            case 0:
                // Tree name - create the tree (it automatically creates a root node)
                print("  🌳 Creating new tree: '\(content)'")
                let tree = SkillTree(context: context, name: content)
                tree.forest = forest
                currentTree = tree
                
                // Find the automatically created root node
                let rootNode = tree.nodes.first { $0.name == content }
                if let root = rootNode {
                    nodeStack.removeAll()
                    nodeStack.append((root, 0)) // Root node is level 0
                    print("  ✅ Tree created with existing root node: '\(content)'")
                    // If the entire input is a single line (just the tree name), create a default child node
                    if lines.count == 1 {
                        let defaultChild = SkillNode(context: context, name: "First Goal", type: .goal)
                        defaultChild.tree = tree
                        defaultChild.order = 0
                        root.addChild(defaultChild)
                        nodeStack.append((defaultChild, 1))
                        print("  ➕ Auto-added default child 'First Goal' under root for single-line input")
                    }
                } else {
                    print("  ⚠️ No root node found for tree: '\(content)'")
                }
                trees.append(tree)
                print("  📊 Current state: \(trees.count) trees, currentTree: \(currentTree?.name ?? "nil")")
                
            case 1:
                // Level 1 node (1 dash = level 1 in tree)
                print("  📌 Creating level 1 node: '\(content)'")
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  📍 Adding node to tree: '\(tree.name)'")
                let (parsedName1, parsedType1) = parseTaggedContent(content, defaultType: .goal)
                let node = SkillNode(context: context, name: parsedName1, type: parsedType1)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 1 }.count
                
                // Find the root node (level 0) as parent
                print("  🔍 Looking for root node (level 0)...")
                if let rootIndex = nodeStack.lastIndex(where: { $0.1 == 0 }) {
                    let root = nodeStack[rootIndex].0
                    print("  👆 Found root node: '\(root.name)' at index \(rootIndex)")
                    root.addChild(node)
                    print("  ✅ Linked node '\(content)' to root '\(root.name)'")
                } else {
                    print("  ⚠️ No root node found for node '\(content)' at level 1")
                    print("  📊 Available nodes in stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                }
                
                nodeStack.append((node, 1))
                print("  ✅ Level 1 node created and added to stack")
                print("  📊 Node stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                print("  👤 Node parent confirmation: '\(node.name)' parent = '\(node.parentNode?.name ?? "none")'")
                
            case 2:
                // Level 2 node (2 dashes = level 2 in tree)
                print("  📌 Creating level 2 node: '\(content)'")
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  📍 Adding node to tree: '\(tree.name)'")
                let (parsedName2, parsedType2) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: context, name: parsedName2, type: parsedType2)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 2 }.count
                
                // Find the most recent level 1 node as parent
                print("  🔍 Looking for parent at level 1...")
                if let parentIndex = nodeStack.lastIndex(where: { $0.1 == 1 }) {
                    let parent = nodeStack[parentIndex].0
                    print("  👆 Found parent: '\(parent.name)' at index \(parentIndex)")
                    parent.addChild(node)
                    print("  ✅ Linked node '\(content)' to parent '\(parent.name)'")
                } else {
                    print("  ⚠️ No parent found for node '\(content)' at level 2")
                    print("  📊 Available nodes in stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                }
                
                nodeStack.append((node, 2))
                print("  ✅ Level 2 node created and added to stack")
                print("  📊 Node stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                print("  👤 Node parent confirmation: '\(node.name)' parent = '\(node.parentNode?.name ?? "none")'")
                
            case 3:
                // Level 3 node (3 dashes = level 3 in tree)
                print("  📌 Creating level 3 node: '\(content)'")
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  📍 Adding node to tree: '\(tree.name)'")
                let (parsedName3, parsedType3) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: context, name: parsedName3, type: parsedType3)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 3 }.count
                
                // Find the most recent level 2 node as parent
                print("  🔍 Looking for parent at level 2...")
                if let parentIndex = nodeStack.lastIndex(where: { $0.1 == 2 }) {
                    let parent = nodeStack[parentIndex].0
                    print("  👆 Found parent: '\(parent.name)' at index \(parentIndex)")
                    parent.addChild(node)
                    print("  ✅ Linked node '\(content)' to parent '\(parent.name)'")
                } else {
                    print("  ⚠️ No parent found for node '\(content)' at level 3")
                    print("  📊 Available nodes in stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                }
                
                nodeStack.append((node, 3))
                print("  ✅ Level 3 node created and added to stack")
                print("  📊 Node stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                print("  👤 Node parent confirmation: '\(node.name)' parent = '\(node.parentNode?.name ?? "none")'")
                
            default:
                // Deeper levels (4+ dashes)
                print("  📌 Creating level \(dashCount) node: '\(content)'")
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  📍 Adding node to tree: '\(tree.name)'")
                let (parsedNameN, parsedTypeN) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: context, name: parsedNameN, type: parsedTypeN)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == dashCount }.count
                
                // Find the most recent node at the previous level as parent
                let parentLevel = dashCount - 1
                print("  🔍 Looking for parent at level \(parentLevel)...")
                if let parentIndex = nodeStack.lastIndex(where: { $0.1 == parentLevel }) {
                    let parent = nodeStack[parentIndex].0
                    print("  👆 Found parent: '\(parent.name)' at index \(parentIndex)")
                    parent.addChild(node)
                    print("  ✅ Linked node '\(content)' to parent '\(parent.name)' at level \(parentLevel)")
                } else {
                    print("  ⚠️ No parent found for node '\(content)' at level \(dashCount)")
                    print("  📊 Available nodes in stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                }
                
                nodeStack.append((node, dashCount))
                print("  ✅ Level \(dashCount) node created and added to stack")
                print("  📊 Node stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                print("  👤 Node parent confirmation: '\(node.name)' parent = '\(node.parentNode?.name ?? "none")'")
            }
        }
        
        print("🔄 Processing complete!")
        print("📊 Final summary:")
        print("  - Trees created: \(trees.count)")
        for (index, tree) in trees.enumerated() {
            print("    \(index + 1). \(tree.name)")
        }
        print("  - Node stack size: \(nodeStack.count)")
        print("  - Current tree: \(currentTree?.name ?? "nil")")
        
        // Save to Core Data
        print("💾 Saving to Core Data...")
        do {
            try context.save()
            print("✅ Successfully imported \(trees.count) trees")
        } catch {
            print("❌ Failed to save: \(error.localizedDescription)")
            throw ImportError.saveFailed(error.localizedDescription)
        }
        
        return ImportResult(
            forestsCount: 0,
            treesCount: trees.count,
            nodesCount: trees.reduce(0) { sum, tree in sum + tree.nodes.count },
            forests: []
        )
    }
}

struct SingleTreeImportPreviewView: View {
    let result: ImportResult
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                // Success Message
                VStack(spacing: 8) {
                    Text("Import Successful!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your tree has been imported successfully.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Import Summary
                VStack(spacing: 12) {
                    Text("Import Summary")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "tree")
                            Text("Trees imported:")
                            Spacer()
                            Text("\(result.treesCount)")
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Image(systemName: "circle")
                            Text("Nodes created:")
                            Spacer()
                            Text("\(result.nodesCount)")
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Dismiss Button
                Button(action: onDismiss) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Import Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// #Preview {
//     ImportSingleTreeView(forest: Forest.example)
//         .environmentObject(DataController.preview)
// } 