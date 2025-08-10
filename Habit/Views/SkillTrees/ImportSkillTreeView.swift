import SwiftUI
import UniformTypeIdentifiers

struct ImportSkillTreeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var textInput = ""
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var importResult: ImportResult?
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            // Wrap main content in a vertical ScrollView so the view is scrollable
            ScrollView {
                VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Import Skill Trees")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Import forests and skill trees from a text file")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
                
                // Format instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("File Format:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• No dashes = Forest name")
                        Text("• 1 dash = Tree name")
                        Text("• 2+ dashes = Node levels within tree")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Example
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("""
                        My Forest
                        - Programming Skills
                        -- Learn Swift
                        -- Build iOS App
                        -- Daily Practice
                        - Fitness Goals
                        -- Cardio Training
                        -- Strength Training
                        """)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Import options
                VStack(spacing: 16) {
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .font(.title3)
                            Text("Import from File")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Text input area
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paste text directly:")
                            .font(.headline)
                        
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
                }
                
                Spacer()
                
                // Import button
                Button(action: importFromText) {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                            .font(.title3)
                        Text("Import")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(textInput.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(textInput.isEmpty)
                }
                .padding()
            }
            .scrollIndicators(.visible)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Import Skill Trees")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    loadFile(file)
                }
            case .failure(let error):
                alertTitle = "Import Error"
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
                ImportPreviewView(result: result) {
                    dismiss()
                }
            }
        }
    }
    
    private func loadFile(_ file: URL) {
        do {
            let content = try String(contentsOf: file)
            textInput = content
        } catch {
            alertTitle = "File Error"
            alertMessage = "Failed to read file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func importFromText() {
        guard !textInput.isEmpty else { return }
        
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
        print("🔍 Starting text parsing...")
        print("📝 Raw text input:")
        print(text)
        print("---")
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        print("📋 Parsed lines (\(lines.count) total):")
        for (index, line) in lines.enumerated() {
            print("  Line \(index + 1): '\(line)'")
        }
        print("---")
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        // Minimum valid forest content: at least one forest line (no dash) and one tree line (one dash)
        let dashCounts = lines.map { $0.prefix(while: { $0 == "-" }).count }
        let hasForestLine = dashCounts.contains(0)
        let hasAtLeastOneTree = dashCounts.contains(1)
        guard hasForestLine && hasAtLeastOneTree else {
            throw ImportError.invalidFormat("A forest requires a forest name (no dashes) and at least one tree (one dash).")
        }
        
        var forests: [Forest] = []
        var currentForest: Forest?
        var currentTree: SkillTree?
        var nodeStack: [(SkillNode, Int)] = []
        
        let context = dataController.container.viewContext
        
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
            print("  Raw line bytes: \(Array(line.utf8))")
            print("  First 10 characters: '\(String(line.prefix(10)))'")
            
            guard !content.isEmpty else { 
                print("  ⏭️ Skipping empty content")
                continue 
            }
            
            switch dashCount {
            case 0:
                // Forest name
                print("  🌲 Creating new forest: '\(content)'")
                let forest = Forest(context: context)
                forest.name_ = content
                forest.description_ = ""
                forests.append(forest)
                currentForest = forest
                currentTree = nil
                nodeStack.removeAll()
                print("  ✅ Forest created and set as current")
                print("  📊 Current state: \(forests.count) forests, currentTree: \(currentTree?.name ?? "nil")")
                
            case 1:
                // Tree name
                print("  🌳 Creating new tree: '\(content)'")
                guard let forest = currentForest else {
                    print("  ❌ No forest defined for tree: '\(content)'")
                    throw ImportError.noForestDefined(lineNumber: index + 1)
                }
                
                print("  📍 Adding tree to forest: '\(forest.name_ ?? "unknown")'")
                let tree = SkillTree(context: context, name: content)
                tree.forest = forest
                currentTree = tree
                nodeStack.removeAll()
                
                // Find the automatically created root node and add it to the stack
                let rootNode = tree.nodes.first { $0.name == content }
                if let root = rootNode {
                    nodeStack.append((root, 0)) // Root node is level 0
                    print("  ✅ Found and added root node '\(root.name)' to stack at level 0")
                } else {
                    print("  ⚠️ Could not find automatically created root node")
                }
                
                print("  ✅ Tree created and set as current")
                print("  📊 Current state: currentTree: '\(currentTree?.name ?? "nil")', nodeStack: \(nodeStack.count) items")
                
            case 2:
                // Level 1 node (2 dashes = level 1 in tree) - should be child of root
                print("  📌 Creating level 1 node: '\(content)'")
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  📍 Adding node to tree: '\(tree.name)'")
                let (parsedName1, parsedType1) = parseTaggedContent(content, defaultType: .goal)
                let node = SkillNode(context: context, name: parsedName1, type: parsedType1)
                node.tree = tree
                node.order = nodeStack.filter { $0.1 == 2 }.count
                
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
                
                nodeStack.append((node, 2))
                print("  ✅ Level 1 node created and added to stack")
                print("  📊 Node stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                
            case 3:
                // Level 2 node (3 dashes = level 2 in tree)
                print("  📌 Creating level 2 node: '\(content)'")
                guard let tree = currentTree else {
                    print("  ❌ No tree defined for node: '\(content)'")
                    throw ImportError.noTreeDefined(lineNumber: index + 1)
                }
                
                print("  📍 Adding node to tree: '\(tree.name)'")
                let (parsedName2, parsedType2) = parseTaggedContent(content, defaultType: .activity)
                let node = SkillNode(context: context, name: parsedName2, type: parsedType2)
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
                print("  ✅ Level 2 node created and added to stack")
                print("  📊 Node stack: \(nodeStack.map { "\($0.0.name)(level \($0.1))" }.joined(separator: ", "))")
                
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
            }
        }
        
        print("🔄 Processing complete!")
        print("📊 Final summary:")
        print("  - Forests created: \(forests.count)")
        for (index, forest) in forests.enumerated() {
            print("    \(index + 1). \(forest.name_ ?? "unknown")")
        }
        print("  - Node stack size: \(nodeStack.count)")
        print("  - Current tree: \(currentTree?.name ?? "nil")")
        
        // Save to Core Data
        print("💾 Saving to Core Data...")
        do {
            try context.save()
            print("✅ Successfully imported \(forests.count) forests")
        } catch {
            print("❌ Failed to save: \(error.localizedDescription)")
            throw ImportError.saveFailed(error.localizedDescription)
        }
        
        return ImportResult(
            forestsCount: forests.count,
            treesCount: forests.reduce(0) { sum, forest in sum + (forest.trees_?.allObjects as? [SkillTree] ?? []).count },
            nodesCount: forests.reduce(0) { sum, forest in sum + (forest.trees_?.allObjects as? [SkillTree] ?? []).reduce(0) { treeSum, tree in treeSum + tree.nodes.count } },
            forests: forests
        )
    }
}

struct ImportResult {
    let forestsCount: Int
    let treesCount: Int
    let nodesCount: Int
    let forests: [Forest]
}

enum ImportError: LocalizedError {
    case emptyFile
    case invalidFormat(String)
    case noForestDefined(lineNumber: Int)
    case noTreeDefined(lineNumber: Int)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty or contains no valid content."
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .noForestDefined(let lineNumber):
            return "Line \(lineNumber): Tree defined without a forest. Add a forest name (no dashes) first."
        case .noTreeDefined(let lineNumber):
            return "Line \(lineNumber): Node defined without a tree. Add a tree name (one dash) first."
        case .saveFailed(let message):
            return "Failed to save imported data: \(message)"
        }
    }
}

struct ImportPreviewView: View {
    let result: ImportResult
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Import Successful!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Statistics
                VStack(spacing: 16) {
                    StatCard(
                        icon: "tree",
                        title: "Forests",
                        value: "\(result.forestsCount)",
                        color: .blue
                    )
                    
                    StatCard(
                        icon: "leaf",
                        title: "Trees",
                        value: "\(result.treesCount)",
                        color: .green
                    )
                    
                    StatCard(
                        icon: "circle.grid.2x2",
                        title: "Nodes",
                        value: "\(result.nodesCount)",
                        color: .orange
                    )
                }
                
                // Forest list
                if !result.forests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Imported Forests:")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(result.forests, id: \.id) { forest in
                                    ForestPreviewRow(forest: forest)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Import Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ForestPreviewRow: View {
    let forest: Forest
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(forest.name_ ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\((forest.trees_?.allObjects as? [SkillTree] ?? []).count) trees, \((forest.trees_?.allObjects as? [SkillTree] ?? []).reduce(0) { sum, tree in sum + tree.totalNodesCount }) nodes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ImportSkillTreeView()
        .environmentObject(DataController.preview)
}